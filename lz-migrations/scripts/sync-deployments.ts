#!/usr/bin/env ts-node

import * as fs from 'fs';
import * as path from 'path';

type CsvRow = { chain: string; eid: string; adapter: string };

function readAdaptersCsv(): CsvRow[] {
  const csvPath = path.resolve(__dirname, '..', '..', 'deployments', 'adapters.csv');
  if (!fs.existsSync(csvPath)) return [];
  const lines = fs.readFileSync(csvPath, 'utf8').trim().split(/\r?\n/);
  const rows: CsvRow[] = [];
  for (let i = 1; i < lines.length; i++) {
    const [chain, eid, adapter] = lines[i].split(',');
    if (chain && adapter) rows.push({ chain, eid, adapter });
  }
  return rows;
}

function latestAdapterFor(chainKey: string, rows: CsvRow[]): string | null {
  for (let i = rows.length - 1; i >= 0; i--) {
    if (rows[i].chain === chainKey && rows[i].adapter) return rows[i].adapter;
  }
  return null;
}

function ensureDir(p: string) {
  if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true });
}

function writeDeployment(networkDir: string, address: string) {
  const abi = [
    'function READ_CHANNEL() external view returns (uint32)',
    'function peers(uint32 eid) external view returns (bytes32)',
    'function setReadChannel(uint32 channelId, bool active) external',
    'function owner() external view returns (address)',
    'function endpoint() external view returns (address)',
    'function enforcedOptions(uint32 eid, uint16 msgType) external view returns (bytes memory)',
    'function setEnforcedOptions((uint32 eid, uint16 msgType, bytes options)[] _enforcedOptions) external'
  ];

  const outDir = path.resolve(__dirname, '..', 'deployments', networkDir);
  ensureDir(outDir);
  const outFile = path.join(outDir, 'TixReadAdapter.json');

  const json = {
    address,
    abi,
    transactionHash: '0x0000000000000000000000000000000000000000000000000000000000000000',
    receipt: {
      to: null,
      from: '0x0000000000000000000000000000000000000000',
      contractAddress: address,
      transactionIndex: 0,
      gasUsed: '0x0',
      logsBloom: '0x' + '0'.repeat(512),
      blockHash: '0x' + '0'.repeat(64),
      transactionHash: '0x' + '0'.repeat(64),
      logs: [],
      blockNumber: 0,
      cumulativeGasUsed: '0x0',
      status: 1,
      byzantium: true
    },
    args: [],
    numDeployments: 1,
    solcInputHash: '0x' + '0'.repeat(64),
    metadata: '',
    bytecode: '0x',
    deployedBytecode: '0x',
    linkReferences: {},
    deployedLinkReferences: {},
    devdoc: { kind: 'dev', methods: {}, version: 1 },
    userdoc: { kind: 'user', methods: {}, version: 1 },
    storageLayout: { storage: [], types: null }
  };

  fs.writeFileSync(outFile, JSON.stringify(json, null, 2));
  console.log(`✅ Wrote deployment for ${networkDir}: ${address}`);
}

function writeChainIdFile(networkDir: string, chainId: number | null) {
  if (!chainId) return;
  const outDir = path.resolve(__dirname, '..', 'deployments', networkDir);
  ensureDir(outDir);
  const outFile = path.join(outDir, '.chainId');
  if (!fs.existsSync(outFile)) {
    fs.writeFileSync(outFile, `${chainId}\n`, { encoding: 'utf8' });
    console.log(`💾 Wrote .chainId for ${networkDir}: ${chainId}`);
  }
}

function chainKeyToNetworkDir(chainKey: string): string {
  // Map chain keys to network directory names used by hardhat-deploy
  const mapping: { [key: string]: string } = {
    'arbitrum-sepolia': 'arbitrumSepolia',
    'base-sepolia': 'baseSepolia',
    'arbitrum': 'arbitrum',
    'base': 'baseMainnet',
    'ethereum': 'mainnet',
    'polygon': 'polygon',
    'optimism': 'optimism',
    'bsc': 'bsc',
    'avalanche-mainnet': 'avalanche',
    'sepolia-testnet': 'sepolia',
    'optimism-sepolia': 'optimismSepolia',
    'polygon-mumbai': 'polygonMumbai',
    'amoy-testnet': 'polygonAmoy',
    'bsc-testnet': 'bscTestnet',
    'fuji': 'fuji',
    'scroll-sepolia': 'scrollSepolia',
    'unichain-testnet': 'unichainTestnet'
  };
  
  return mapping[chainKey] || chainKey.replace(/-/g, '');
}

function chainKeyToChainId(chainKey: string): number | null {
  const mapping: { [key: string]: number } = {
    // Testnets
    'arbitrum-sepolia': 421614,
    'base-sepolia': 84532,
    'sepolia-testnet': 11155111,
    'optimism-sepolia': 11155420,
    'polygon-mumbai': 80001,
    'amoy-testnet': 80002,
    'bsc-testnet': 97,
    'fuji': 43113,
    'scroll-sepolia': 534351,
    // Mainnets
    'arbitrum': 42161,
    'base': 8453,
    'ethereum': 1,
    'polygon': 137,
    'optimism': 10,
    'bsc': 56,
    'avalanche-mainnet': 43114,
  };
  return mapping[chainKey] ?? null;
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

async function main() {
  const targetEnv = process.argv.includes('--testnet') ? 'testnet' : 
                   process.argv.includes('--mainnet') ? 'mainnet' : undefined;

  const rows = readAdaptersCsv();
  if (rows.length === 0) {
    console.log('⚠️  No adapters.csv found or empty; skipping sync');
    return;
  }

  console.log(`🔄 Syncing deployments${targetEnv ? ` (${targetEnv} only)` : ' (all environments)'}...`);

  let syncedCount = 0;
  for (const row of rows) {
    if (!row.chain || !row.adapter) continue;
    
    const environment = getEnvironmentForChainKey(row.chain);
    
    // Filter by environment if specified
    if (targetEnv && environment !== targetEnv) {
      continue;
    }
    
    const networkDir = chainKeyToNetworkDir(row.chain);
    writeDeployment(networkDir, row.adapter);
    writeChainIdFile(networkDir, chainKeyToChainId(row.chain));
    syncedCount++;
  }

  console.log(`✅ Synced ${syncedCount} deployment(s)`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});


