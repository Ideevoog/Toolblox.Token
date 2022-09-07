#!/usr/bin/env node

import { ethers } from "ethers";
import * as fs from 'fs';
import * as path from 'path';

type CsvRow = { chain: string; eid: string; adapter: string };

function readAdaptersCsv(): CsvRow[] {
  try {
    const csvPath = path.resolve(__dirname, '..', '..', 'deployments', 'adapters.csv');
    if (!fs.existsSync(csvPath)) return [];
    const lines = fs.readFileSync(csvPath, 'utf8').trim().split(/\r?\n/);
    const rows: CsvRow[] = [];
    for (let i = 1; i < lines.length; i++) {
      const [chain, eid, adapter] = lines[i].split(',');
      if (chain && adapter) rows.push({ chain, eid, adapter });
    }
    return rows;
  } catch {
    return [];
  }
}

function getEidForChainKey(chainKey: string): number {
  const rows = readAdaptersCsv();
  for (let i = rows.length - 1; i >= 0; i--) {
    if (rows[i].chain === chainKey) {
      const eidNum = Number(rows[i].eid);
      return Number.isNaN(eidNum) ? 0 : eidNum;
    }
  }
  return 0;
}

function getEnvironmentForChainKey(chainKey: string): 'mainnet' | 'testnet' {
  const ck = chainKey.toLowerCase();
  if (
    ck.includes('sepolia') ||
    ck.includes('testnet') ||
    ck.includes('mumbai') ||
    ck.includes('amoy') ||
    ck.includes('fuji')
  ) {
    return 'testnet';
  }
  return 'mainnet';
}

type Metadata = any;
function readMetadata(): Metadata {
  try {
    const p = path.resolve(__dirname, '..', 'metadata.json');
    if (!fs.existsSync(p)) throw new Error('metadata.json not found. Run npm run fetch-addresses');
    return JSON.parse(fs.readFileSync(p, 'utf8'));
  } catch {
    throw new Error('Failed to read metadata.json');
  }
}

function resolveReadParams(chainKey: string) {
  const meta = readMetadata();
  const values = Object.values(meta) as any[];
  const chain = values.find((v) => v?.chainKey === chainKey || v?.chainDetails?.chainKey === chainKey);
  if (!chain) throw new Error(`Chain ${chainKey} not found in metadata.json`);
  const dep = Array.isArray(chain?.deployments) ? chain.deployments.find((d: any) => d.version === 2 && d.chainKey === chainKey) : null;
  const readLibrary = dep?.readLib1002?.address;
  const executor = dep?.executor?.address;
  const endpoint = dep?.endpoint?.address || dep?.endpointV2?.address;
  
  if (!readLibrary || !executor || !endpoint) {
    throw new Error(`Missing read params in metadata for ${chainKey}`);
  }
  return { readLibrary, executor, endpoint };
}

const ENDPOINT_ABI = [
  "function getSendLibrary(address sender, uint32 dstEid) external view returns (address lib)",
  "function getReceiveLibrary(address receiver, uint32 srcEid) external view returns (address lib)"
];

function getRpcUrl(chainKey: string): string {
  const rpcUrls: { [key: string]: string } = {
    'arbitrum-sepolia': process.env.ARBITRUM_SEPOLIA_RPC_URL || 'https://sepolia-rollup.arbitrum.io/rpc',
    'base-sepolia': process.env.BASE_SEPOLIA_RPC_URL || 'https://sepolia.base.org',
    'arbitrum': process.env.ARBITRUM_RPC_URL || 'https://arb1.arbitrum.io/rpc',
    'base': process.env.BASE_RPC_URL || 'https://mainnet.base.org',
    'ethereum': process.env.MAINNET_RPC_URL || 'https://cloudflare-eth.com',
    'polygon': process.env.POLYGON_RPC_URL || 'https://polygon-rpc.com',
    'optimism': process.env.OPTIMISM_RPC_URL || 'https://mainnet.optimism.io'
  };
  
  return rpcUrls[chainKey] || '';
}

function getProvider(chainKey: string): ethers.providers.JsonRpcProvider | null {
  const rpcUrl = getRpcUrl(chainKey);
  if (!rpcUrl) {
    console.warn(`⚠️  No RPC URL configured for ${chainKey}`);
    return null;
  }
  return new ethers.providers.JsonRpcProvider(rpcUrl);
}

interface AdapterStatus {
  chain: string;
  adapter: string;
  environment: 'testnet' | 'mainnet';
  isWired: boolean;
  currentSendLib?: string;
  expectedReadLib?: string;
  error?: string;
}

async function checkAdapterWiredStatus(chainKey: string, adapterAddress: string): Promise<AdapterStatus> {
  const environment = getEnvironmentForChainKey(chainKey);
  const status: AdapterStatus = {
    chain: chainKey,
    adapter: adapterAddress,
    environment,
    isWired: false
  };

  try {
    const provider = getProvider(chainKey);
    if (!provider) {
      status.error = `No RPC provider configured for ${chainKey}`;
      return status;
    }

    const { readLibrary, endpoint } = resolveReadParams(chainKey);
    status.expectedReadLib = readLibrary;

    const endpointContract = new ethers.Contract(endpoint, ENDPOINT_ABI, provider);
    const dstEid = getEidForChainKey(chainKey);
    if (!dstEid) {
      status.error = `Missing or invalid EID for ${chainKey}`;
      return status;
    }
    
    console.log(`   🔍 Checking endpoint ${endpoint} for adapter ${adapterAddress} with dstEid ${dstEid}`);
    
    // First check if the endpoint contract exists
    const endpointCode = await provider.getCode(endpoint);
    if (endpointCode === '0x') {
      status.error = `Endpoint contract not found at ${endpoint}`;
      return status;
    }
    
    // Check if the adapter contract exists
    const adapterCode = await provider.getCode(adapterAddress);
    if (adapterCode === '0x') {
      status.error = `Adapter contract not found at ${adapterAddress}`;
      return status;
    }
    
    let currentSendLib: string | null = null;
    try {
      currentSendLib = await endpointContract.getSendLibrary(adapterAddress, dstEid);
    } catch (getSendLibError: any) {
      // DefaultSendLibUnavailable (0x6c1ccdb5) => treat as not wired, not an error
      if (getSendLibError?.data === '0x6c1ccdb5') {
        console.log(`   📝 No library set for dstEid ${dstEid} (DefaultSendLibUnavailable) → NOT wired`);
        currentSendLib = null;
      } else {
        throw getSendLibError;
      }
    }
    
    if (currentSendLib) {
      status.currentSendLib = currentSendLib;
      status.isWired = currentSendLib.toLowerCase() === readLibrary.toLowerCase();
    } else {
      status.isWired = false;
    }
    
  } catch (error) {
    status.error = error instanceof Error ? error.message : 'Unknown error';
  }

  return status;
}

async function main() {
  console.log('🚀 Starting check-wired-status script...');
  
  // Check environment variable first, then hardhat network
  let targetEnv: 'testnet' | 'mainnet' | undefined = process.env.LZ_CHECK_ENV?.trim() as 'testnet' | 'mainnet' | undefined;
  console.log(`🔍 Target environment: ${targetEnv || 'all'}`);
  
  // If no environment specified, check all adapters
  if (!targetEnv) {
    console.log('💡 No environment specified, checking all adapters');
  }

  console.log(`🔍 Checking wired status of adapters${targetEnv ? ` (${targetEnv} only)` : ' (all environments)'}...\n`);

  const rows = readAdaptersCsv();
  if (rows.length === 0) {
    console.log('⚠️  No adapters found in adapters.csv');
    return;
  }

  const statuses: AdapterStatus[] = [];
  const filteredRows = targetEnv ? rows.filter(row => getEnvironmentForChainKey(row.chain) === targetEnv) : rows;

  console.log(`📋 Found ${filteredRows.length} adapter(s) to check:\n`);

  for (const row of filteredRows) {
    console.log(`🔍 Checking ${row.chain}...`);
    const status = await checkAdapterWiredStatus(row.chain, row.adapter);
    statuses.push(status);
    
    if (status.error) {
      console.log(`   ❌ Error: ${status.error}`);
    } else if (status.isWired) {
      console.log(`   ✅ Already wired correctly`);
    } else {
      console.log(`   ⚠️  NOT wired - needs configuration`);
      console.log(`      Current: ${status.currentSendLib}`);
      console.log(`      Expected: ${status.expectedReadLib}`);
    }
    console.log();
  }

  // Summary
  const wiredCount = statuses.filter(s => s.isWired && !s.error).length;
  const needsWiring = statuses.filter(s => !s.isWired && !s.error).length;
  const errorCount = statuses.filter(s => s.error).length;

  console.log(`📊 Summary:`);
  console.log(`   ✅ Already wired: ${wiredCount}`);
  console.log(`   ⚠️  Need wiring: ${needsWiring}`);
  console.log(`   ❌ Errors: ${errorCount}`);

  if (needsWiring > 0) {
    console.log(`\n🔧 To wire the adapters that need it, run:`);
    if (targetEnv) {
      console.log(`   npm run wire-read:${targetEnv}`);
    } else {
      const testnetNeedsWiring = statuses.filter(s => !s.isWired && !s.error && s.environment === 'testnet').length;
      const mainnetNeedsWiring = statuses.filter(s => !s.isWired && !s.error && s.environment === 'mainnet').length;
      
      if (testnetNeedsWiring > 0) {
        console.log(`   npm run wire-read:testnet  # for ${testnetNeedsWiring} testnet adapter(s)`);
      }
      if (mainnetNeedsWiring > 0) {
        console.log(`   npm run wire-read:mainnet  # for ${mainnetNeedsWiring} mainnet adapter(s)`);
      }
    }
  }

  // Exit with error code if any adapters need wiring (useful for CI/CD)
  if (needsWiring > 0) {
    process.exit(1);
  }
}

main().catch((error) => {
  console.error('❌ Failed to check wired status:', error);
  process.exit(1);
});
