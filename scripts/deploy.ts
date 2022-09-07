#!/usr/bin/env node

import { ethers } from "hardhat";
import * as fs from "fs";
import fetch from "node-fetch";

// Parse mode from environment variable (set by wrapper scripts)
const MODE = process.env.DEPLOY_MODE || 'all';

// CSV output paths
const OUTPUT_DIR = "deployments";
const TIX_CSV = `${OUTPUT_DIR}/tix.csv`;
const ADAPTERS_CSV = `${OUTPUT_DIR}/adapters.csv`;

function ensureOutputDir() {
  if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  }
}

function appendCsv(filePath: string, header: string, row: string) {
  ensureOutputDir();
  const needsHeader = !fs.existsSync(filePath) || fs.readFileSync(filePath, 'utf8').trim().length === 0;
  const data = (needsHeader ? header + "\n" : "") + row + "\n";
  fs.appendFileSync(filePath, data);
}

function getAlchemyUrl(chainKey: string): string | null {
  const key = process.env.ALCHEMY_API_KEY;
  if (!key) return null;
  switch (chainKey) {
    case 'sepolia-testnet': return `https://eth-sepolia.g.alchemy.com/v2/${key}`;
    case 'ethereum': return `https://eth-mainnet.g.alchemy.com/v2/${key}`;
    case 'ethereum-mainnet': return `https://eth-mainnet.g.alchemy.com/v2/${key}`;
    case 'base-sepolia': return `https://base-sepolia.g.alchemy.com/v2/${key}`;
    case 'base-mainnet': return `https://base-mainnet.g.alchemy.com/v2/${key}`;
    case 'polygon-mumbai': return `https://polygon-mumbai.g.alchemy.com/v2/${key}`;
    case 'amoy-testnet': return `https://polygon-amoy.g.alchemy.com/v2/${key}`;
    case 'polygon': return `https://polygon-mainnet.g.alchemy.com/v2/${key}`;
    case 'polygon-mainnet': return `https://polygon-mainnet.g.alchemy.com/v2/${key}`;
    case 'arbitrum-sepolia': return `https://arb-sepolia.g.alchemy.com/v2/${key}`;
    case 'arbitrum': return `https://arb-mainnet.g.alchemy.com/v2/${key}`;
    case 'arbitrum-mainnet': return `https://arb-mainnet.g.alchemy.com/v2/${key}`;
    case 'optimism-sepolia': return `https://opt-sepolia.g.alchemy.com/v2/${key}`;
    case 'optimism': return `https://opt-mainnet.g.alchemy.com/v2/${key}`;
    case 'optimism-mainnet': return `https://opt-mainnet.g.alchemy.com/v2/${key}`;
    case 'fuji': return `https://avax-fuji.g.alchemy.com/v2/${key}`;
    case 'avalanche-mainnet': return `https://avax-mainnet.g.alchemy.com/v2/${key}`;
    case 'scroll-mainnet': return `https://scroll-mainnet.g.alchemy.com/v2/${key}`;
    case 'unichain-mainnet': return `https://unichain-mainnet.g.alchemy.com/v2/${key}`;
    case 'celo-mainnet': return `https://celo-mainnet.g.alchemy.com/v2/${key}`;
    case 'celo-testnet': return `https://celo-alfajores.g.alchemy.com/v2/${key}`;
    case 'zora': return `https://zora-mainnet.g.alchemy.com/v2/${key}`;
    case 'zora-testnet': return `https://zora-sepolia.g.alchemy.com/v2/${key}`;
    case 'worldchain': return `https://worldchain-mainnet.g.alchemy.com/v2/${key}`;
    default: return null;
  }
}

function getEnvRpcUrl(chainKey: string): string | null {
  const envKey = `${chainKey.toUpperCase().replace(/-/g, '_')}_RPC_URL`;
  return process.env[envKey] || null;
}

function getRpcUrl(chainKey: string): string | null {
  return getAlchemyUrl(chainKey) || getEnvRpcUrl(chainKey);
}

// Ensure lz-migrations deployment folder has a .chainId file for hardhat-deploy
async function ensureLZChainIdFile(chainKey: string): Promise<void> {
  // Map our chain keys to lz-migrations network folder names
  function toLZFolderName(key: string): string | null {
    switch (key) {
      case 'base-sepolia': return 'baseSepolia';
      case 'arbitrum-sepolia': return 'arbitrumSepolia';
      case 'base-mainnet': return 'baseMainnet';
      case 'base': return 'baseMainnet';
      case 'arbitrum': return 'arbitrum';
      case 'arbitrum-mainnet': return 'arbitrum';
      default:
        // Convert dash-case to camelCase for names like "foo-bar" -> "fooBar"
        // This covers potential future additions like "polygon-mainnet" -> "polygonMainnet"
        if (key.includes('-')) {
          const parts = key.split('-');
          return parts[0] + parts.slice(1).map(s => s.charAt(0).toUpperCase() + s.slice(1)).join('');
        }
        return key;
    }
  }

  async function resolveChainId(key: string): Promise<number | null> {
    // Try via RPC first
    const rpc = getRpcUrl(key);
    if (rpc) {
      try {
        const { ethers: ethersLib } = await import('ethers');
        const JsonRpcProvider = (ethersLib as any).providers.JsonRpcProvider;
        const provider = new JsonRpcProvider(rpc);
        const net = await provider.getNetwork();
        return Number(net.chainId);
      } catch {}
    }
    // Fallback static map for common networks
    const staticMap: Record<string, number> = {
      'base-sepolia': 84532,
      'arbitrum-sepolia': 421614,
      'base-mainnet': 8453,
      'base': 8453,
      'arbitrum': 42161,
      'arbitrum-mainnet': 42161,
    };
    return staticMap[key] ?? null;
  }

  const folder = toLZFolderName(chainKey);
  if (!folder) return;

  const dir = `lz-migrations/deployments/${folder}`;
  const file = `${dir}/.chainId`;

  try {
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    if (!fs.existsSync(file)) {
      const cid = await resolveChainId(chainKey);
      if (cid) {
        fs.writeFileSync(file, `${cid}\n`, { encoding: 'utf8' });
        console.log(`   💾 Wrote ${file} with chainId ${cid}`);
      } else {
        console.log(`   ⚠️  Could not resolve chainId for ${chainKey}; skipping ${file}`);
      }
    }
  } catch (e) {
    console.log(`   ⚠️  Failed to ensure .chainId for ${chainKey}`);
    console.log(e);
  }
}

// (moved logs into main() to avoid side effects on import)

// Seed TIX CSV with provided known addresses if file is absent, including LZ eid when available
async function seedTixCsvIfMissingAsync(metadata: LZMetadata) {
  ensureOutputDir();
  if (fs.existsSync(TIX_CSV)) return;

  const header = "chain,eid,tix,serviceDeployer,upgradeableDeployer\n";
  const seeds: Array<{ chain: string; tix: string }> = [
    { chain: "scroll-mainnet", tix: "0xABD5F9cFB2C796Bbd1647023ee2BEA74B23bf672" },
    { chain: "scroll-sepolia", tix: "0xABD5F9cFB2C796Bbd1647023ee2BEA74B23bf672" },
    { chain: "scroll-testnet", tix: "0x2C089696c412E0F52AA2f96494B314edeF4A5E1D" },
    { chain: "polygon", tix: "0x6994199717e1396ad91Bf12B41FbEFcD218e25A7" },
    { chain: "polygon-mumbai", tix: "0x6994199717e1396ad91Bf12B41FbEFcD218e25A7" },
    { chain: "amoy-testnet", tix: "0x6994199717e1396ad91Bf12B41FbEFcD218e25A7" },
    { chain: "taraxa-mainnet", tix: "0x6994199717e1396ad91Bf12B41FbEFcD218e25A7" },
    { chain: "taraxa-testnet-2", tix: "0x6994199717e1396ad91Bf12B41FbEFcD218e25A7" },
    { chain: "neon-testnet", tix: "0x6994199717e1396ad91Bf12B41FbEFcD218e25A7" },
    { chain: "bttc-mainnet", tix: "0x6994199717e1396ad91Bf12B41FbEFcD218e25A7" },
    { chain: "bttc-testnet", tix: "0x6994199717e1396ad91Bf12B41FbEFcD218e25A7" },
    { chain: "base-mainnet", tix: "0x6994199717e1396ad91Bf12B41FbEFcD218e25A7" },
    { chain: "base-sepolia", tix: "0x9B3AD2533a7Db882C72E4C403e45c64F4A7E3F5b" },
    { chain: "redbelly-testnet", tix: "0x42e3806cb4092D0cD7ABEBe8D8Ad76AB8324CCf6" },
    { chain: "hedera-testnet", tix: "0x34C11B7D52fB6c4D49784748d55C601Ffbd41a7e" },
  ];

  const rows: string[] = [];
  for (const s of seeds) {
    const dep = findDeploymentForChain(s.chain, metadata);
    const eid = dep?.eid || "";
    rows.push(`${s.chain},${eid},${s.tix},`);
  }

  fs.writeFileSync(TIX_CSV, header + rows.join("\n") + "\n");
}

function findTixInCsv(chainKey: string): string | null {
  if (!fs.existsSync(TIX_CSV)) return null;
  const lines = fs.readFileSync(TIX_CSV, 'utf8').trim().split(/\r?\n/);
  if (lines.length <= 1) return null;
  // find last matching row for chain
  for (let i = lines.length - 1; i >= 1; i--) {
    const parts = lines[i].split(',');
    const chain = parts[0];
    const tix = parts[2];
    if (chain === chainKey && tix && tix.length > 0) {
      return tix;
    }
  }
  return null;
}

function getLatestAdapterFromCsv(chainKey: string): { chain: string; eid: string; adapter: string } | null {
  if (!fs.existsSync(ADAPTERS_CSV)) return null;
  const lines = fs.readFileSync(ADAPTERS_CSV, 'utf8').trim().split(/\r?\n/);
  if (lines.length <= 1) return null;
  for (let i = lines.length - 1; i >= 1; i--) {
    const parts = lines[i].split(',');
    const chain = parts[0];
    const eid = parts[1];
    const adapter = parts[2];
    if (chain === chainKey && adapter && adapter.length > 0) {
      return { chain, eid, adapter };
    }
  }
  return null;
}

// Target chains for deployment - chains with TIX addresses or that can have new TIX deployed
const ALL_CHAINS = [
  // Start with base-sepolia as requested
  "base-sepolia",

  // Mainnets with TIX addresses
  "ethereum",
  "polygon",
  "base-mainnet",
  "scroll-mainnet",
  "bttc-mainnet",

  // Testnets with TIX addresses
  "sepolia-testnet",
  "amoy-testnet",
  "base-testnet",
  "scroll-sepolia",
  "polygon-mumbai",
  "bttc-testnet",
  "scroll-testnet",
  "redbelly-testnet",
  "hedera-testnet",
  "neon-testnet",
  "taraxa-testnet-2",

  // Mainnets that can have new TIX deployed (but will use existing if available)
  "arbitrum",
  "optimism",
  "bsc",
  "avalanche-mainnet",
  "celo-mainnet",
  "zora",
  "worldchain",

  // Testnets that can have new TIX deployed
  "arbitrum-sepolia",
  "optimism-sepolia",
  "bsc-testnet",
  "fuji",
  "unichain-testnet",
  "taraxa-mainnet"
];

// Filter chains based on mode
const MAINNET_CHAIN_KEYS = new Set<string>([
  'ethereum', 'polygon', 'arbitrum', 'optimism', 'bsc',
  'avalanche-mainnet', 'scroll-mainnet', 'unichain-mainnet',
  'celo-mainnet', 'zora', 'worldchain', 'hedera-mainnet',
  // Also include legacy names for compatibility
  'ethereum-mainnet', 'polygon-mainnet', 'arbitrum-mainnet', 'optimism-mainnet', 'bnb-mainnet', 'worldchain-mainnet', 'zora-mainnet'
]);

const TARGET_CHAINS = MODE === 'all' ? ALL_CHAINS :
  MODE === 'mainnet' ? ALL_CHAINS.filter(chain => MAINNET_CHAIN_KEYS.has(chain)) :
  ALL_CHAINS.filter(chain => !MAINNET_CHAIN_KEYS.has(chain));

// (moved logs into main() to avoid side effects on import)

interface LZDeployment {
  eid: string;
  endpoint?: { address: string };
  endpointV2?: { address: string };
  endpointV2View?: { address: string };
  readLib1002?: { address: string };
  chainKey: string;
  stage: string;
  version: number;
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

interface LZChainData {
  deployments: LZDeployment[];
  chainKey: string;
  chainDetails: {
    chainKey: string;
    chainStatus: string;
    nativeChainId: number;
  };
}

interface LZMetadata {
  // The API returns an object keyed by an arbitrary slug (e.g., "arbsep-testnet").
  // We MUST NOT rely on those keys. We will search by inner chainKey/eid fields.
  [slug: string]: LZChainData;
}

async function fetchLZMetadata(): Promise<LZMetadata> {
  // Deprecated: lz-migrations handles wiring and metadata
  throw new Error('fetchLZMetadata removed; use lz-migrations CLI for config');
}

// We only work with inner chainKey and eid; do not rely on top-level API keys

function getChainDataByChainKey(metadata: LZMetadata, chainKey: string): LZChainData | undefined {
  const values = Object.values(metadata);
  return values.find(cd =>
    cd?.chainKey === chainKey ||
    cd?.chainDetails?.chainKey === chainKey ||
    (Array.isArray(cd?.deployments) && cd.deployments.some(d => d.chainKey === chainKey))
  );
}

function findDeploymentForChain(chainKey: string, metadata: LZMetadata): LZDeployment | null {
  // Look up by inner chainKey only (ignore top-level slugs entirely)
  const chainData = getChainDataByChainKey(metadata, chainKey);
  if (!chainData || !Array.isArray(chainData.deployments)) return null;

  // Prefer version 2 deployments, fallback to version 1
  const v2Deployment = chainData.deployments.find(d => d.version === 2 && d.chainKey === chainKey);
  if (v2Deployment) return v2Deployment;
  const v1Deployment = chainData.deployments.find(d => d.version === 1 && d.chainKey === chainKey);
  return v1Deployment || null;
}

function getEndpointAddress(deployment: LZDeployment): string {
  if (deployment.version === 2) {
    return deployment.endpointV2?.address || deployment.endpointV2View?.address || "";
  }
  return deployment.endpoint?.address || "";
}

function getReadLibAddress(deployment: LZDeployment): string {
  // For read operations, ONLY use readLib1002 - no fallbacks to endpoint
  if (deployment.version === 2) {
    // Check if there's a specific readLib1002 address
    if (deployment.readLib1002?.address) {
      return deployment.readLib1002.address;
    }
    // No readLib1002 available - this is an error
    throw new Error(`No readLib1002 address available for chain with EID ${deployment.eid}`);
  }
  // For v1, use the endpoint as read lib (they're the same in v1)
  return deployment.endpoint?.address || "";
}

async function deployToChain(
  chainKey: string,
  deployment: LZDeployment
): Promise<{
  tixToken: string;
  serviceDeployer: string;
  upgradeableDeployer: string;
  omniAdapter: string;
  chain: string;
  eid: string;
} | null> {
  try {
    console.log(`\n🚀 Deploying to ${chainKey} (EID: ${deployment.eid})`);

    const endpointAddress = getEndpointAddress(deployment);

    if (!endpointAddress) {
      console.error(`❌ Missing endpoint addresses for ${chainKey}`);
      return null;
    }

    // Validate endpoint address format
    if (!ethers.utils.isAddress(endpointAddress)) {
      console.error(`❌ Invalid endpoint address format: ${endpointAddress}`);
      return null;
    }

    // On localhost, use a mock endpoint address to avoid validation issues
    const network = await ethers.provider.getNetwork();
    const isLocalhost = network.chainId === 31337 || network.name === 'localhost' || network.name === 'hardhat';

    let actualEndpointAddress = endpointAddress;
    if (isLocalhost) {
      // Use a mock endpoint address for localhost deployment
      actualEndpointAddress = '0x0000000000000000000000000000000000000001';
      console.log(`   ⚠️  Using mock endpoint for localhost: ${actualEndpointAddress}`);
    } else {
      console.log(`   Endpoint: ${endpointAddress}`);
    }
    // ReadLib is configured via lz-migrations CLI, not here

    if (!isLocalhost) {
      try {
        const code = await ethers.provider.getCode(endpointAddress);
        if (code === '0x') {
          console.error(`❌ Endpoint address is not a contract: ${endpointAddress}`);
          return null;
        }
        console.log(`   ✅ Endpoint is a valid contract`);
      } catch (error) {
        console.error(`❌ Failed to validate endpoint contract: ${error}`);
        return null;
      }
    } else {
      console.log(`   ⚠️  Skipping endpoint validation (running on localhost)`);
    }

    // Check if chain already has TIX address
    let tixTokenAddress: string;
    let serviceDeployerAddress: string;
    let upgradeableDeployerAddress: string;
    let existingTix = false;

    // Read existing Tix address from CSV (append-only store) and seed with eid on first run
    try {
      const metaForSeed = await fetchLZMetadata();
      await seedTixCsvIfMissingAsync(metaForSeed);
    } catch {}
    let existingTixAddress = findTixInCsv(chainKey);

    if (existingTixAddress && existingTixAddress !== "") {
      console.log(`📋 Using existing TIX infrastructure at: ${existingTixAddress}`);
      tixTokenAddress = existingTixAddress;
      serviceDeployerAddress = ""; // Will be looked up from TIX
      upgradeableDeployerAddress = ""; // Will be looked up from TIX
      existingTix = true;
    } else {
      // Deploy new TIX infrastructure
      console.log(`🏗️  Deploying new TIX infrastructure...`);

      // Determine initial TIX supply based on mode
      const initialSupply = ethers.BigNumber.from("10000000000000000000000000");
      console.log(`   Initial TIX Supply: ${ethers.utils.formatEther(initialSupply)} TIX`);

      // 1. Deploy TixToken
      console.log(`📄 Deploying TixToken...`);
      const TixToken = await ethers.getContractFactory("TixToken");
      const tixToken = await TixToken.deploy(initialSupply);
      await tixToken.deployed();
      tixTokenAddress = tixToken.address;
      console.log(`✅ TixToken deployed to: ${tixTokenAddress}`);

      // 2. Deploy ServiceDeployer
      console.log(`🔧 Deploying ServiceDeployer...`);
      const ServiceDeployer = await ethers.getContractFactory("ServiceDeployer");
      const serviceDeployer = await ServiceDeployer.deploy(tixTokenAddress);
      await serviceDeployer.deployed();
      serviceDeployerAddress = serviceDeployer.address;
      console.log(`✅ ServiceDeployer deployed to: ${serviceDeployerAddress}`);

      // 3. Deploy UpgradeableServiceDeployer
      console.log(`⬆️  Deploying UpgradeableServiceDeployer...`);
      const UpgradeableServiceDeployer = await ethers.getContractFactory("UpgradeableServiceDeployer");
      const upgradeableDeployer = await UpgradeableServiceDeployer.deploy(tixTokenAddress);
      await upgradeableDeployer.deployed();
      upgradeableDeployerAddress = upgradeableDeployer.address;
      console.log(`✅ UpgradeableServiceDeployer deployed to: ${upgradeableDeployerAddress}`);

      // Set up SERVICE_WORKER roles and register deployers in TixToken
      console.log(`📝 Setting up SERVICE_WORKER roles and registering deployers...`);
      const signer = await ethers.provider.getSigner();
      const signerAddress = await signer.getAddress();

      // Grant SERVICE_WORKER role to both deployers
      await tixToken.grantRole(await tixToken.SERVICE_WORKER(), serviceDeployerAddress);
      await tixToken.grantRole(await tixToken.SERVICE_WORKER(), upgradeableDeployerAddress);

      // Register deployers in TixToken
      await tixToken.registerService("ServiceDeployer", "Service deployment contract", serviceDeployerAddress, signerAddress);
      await tixToken.registerService("UpgradeableServiceDeployer", "Upgradeable service deployment contract", upgradeableDeployerAddress, signerAddress);

      console.log(`✅ TIX infrastructure deployed and configured`);
      console.log(`   - SERVICE_WORKER roles granted to deployers`);
      console.log(`   - Deployers registered in TixToken`);

      // Append TIX CSV immediately (all three known)
      appendCsv(
        TIX_CSV,
        "chain,eid,tix,serviceDeployer,upgradeableDeployer",
        `${chainKey},${deployment.eid},${tixTokenAddress},${serviceDeployerAddress},${upgradeableDeployerAddress}`
      );
    }

    // 4. Deploy TixReadAdapter (always deploy this)
    console.log(`🌐 Deploying TixReadAdapter...`);
    console.log(`   Constructor params:`);
    console.log(`     - endpoint: ${actualEndpointAddress}`);
    console.log(`     - tixToken: ${tixTokenAddress}`);

    let adapterAddress: string | undefined;
    // Reuse existing adapter if present in CSV and code exists
    const latestAdapter = getLatestAdapterFromCsv(chainKey);
    if (latestAdapter) {
      try {
        const code = await ethers.provider.getCode(latestAdapter.adapter);
        if (code && code !== '0x') {
          console.log(`📎 Reusing existing adapter from CSV: ${latestAdapter.adapter}`);
          adapterAddress = latestAdapter.adapter;
        }
      } catch {}
    }

    if (!adapterAddress) {
      try {
        const TixReadAdapter = await ethers.getContractFactory("contracts/TixReadAdapter.sol:TixReadAdapter");
        console.log(`   🔧 Deploying contract...`);
        const adapter = await TixReadAdapter.deploy(
          actualEndpointAddress,
          tixTokenAddress
        );
        console.log(`   ⏳ Waiting for deployment confirmation...`);
        await adapter.deployed();
        adapterAddress = adapter.address;
        console.log(`✅ TixReadAdapter deployed to: ${adapterAddress}`);
      } catch (deployError) {
        console.error(`❌ TixReadAdapter deployment failed:`, deployError);
        console.error(`   This might be due to:`);
        console.error(`   - Invalid endpoint address`);
        console.error(`   - OAppCore initialization failure`);
        console.error(`   - Network connectivity issues`);
        return null;
      }
    }

    // Register OmniAdapter in TixToken
    if (existingTix) {
      // For existing TIX, we need to check if we can register
      try {
        const tixContract = await ethers.getContractAt("TixToken", tixTokenAddress);
        const signer = await ethers.provider.getSigner();
        const signerAddress = await signer.getAddress();

        // Try to register the adapter (this might fail if we don't have permission)
        await tixContract.registerService("OmniAdapter", "Cross-chain adapter", adapterAddress, signerAddress);
        console.log(`📝 OmniAdapter registered in existing TIX`);

        // Try to look up existing deployers
        try {
          const serviceDeployerKey = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("ServiceDeployer"));
          const upgradeableDeployerKey = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("UpgradeableServiceDeployer"));

          serviceDeployerAddress = await tixContract.getService(serviceDeployerKey);
          upgradeableDeployerAddress = await tixContract.getService(upgradeableDeployerKey);

          console.log(`📋 Found existing deployers:`);
          console.log(`   ServiceDeployer: ${serviceDeployerAddress}`);
          console.log(`   UpgradeableDeployer: ${upgradeableDeployerAddress}`);
        } catch (e) {
          console.log(`⚠️  Could not lookup existing deployers`);
        }
      } catch (e) {
        console.log(`⚠️  Could not register OmniAdapter in existing TIX (might need separate registration)`);
      }
    } else {
      // For new TIX, we already registered above
      const tixContract = await ethers.getContractAt("TixToken", tixTokenAddress);
      const signer = await ethers.provider.getSigner();
      const signerAddress = await signer.getAddress();
      await tixContract.registerService("OmniAdapter", "Cross-chain adapter", adapterAddress, signerAddress);
    }

    // Skip READ channel and ReadLib configuration; handled by lz-migrations CLI

    // Append adapter CSV row only if not already the latest identical
    const currentLatest = getLatestAdapterFromCsv(chainKey);
    if (!currentLatest || currentLatest.adapter.toLowerCase() !== (adapterAddress as string).toLowerCase()) {
      appendCsv(ADAPTERS_CSV, "chain,eid,adapter", `${chainKey},${deployment.eid},${adapterAddress}`);
    }

    // Cross-register: set peers in the NEW adapter for existing adapters from CSV (same environment only)
    try {
      const newAdapter = await ethers.getContractAt("contracts/TixReadAdapter.sol:TixReadAdapter", adapterAddress);
      const newEnv = getEnvironmentForChainKey(chainKey);

      if (fs.existsSync(ADAPTERS_CSV)) {
        const lines = fs.readFileSync(ADAPTERS_CSV, 'utf8').trim().split(/\r?\n/).slice(1);
        for (const line of lines) {
          const parts = line.split(',');
          const otherChain = parts[0];
          const otherEidStr = parts[1];
          const otherAdapter = parts[2];
          if (!otherChain || !otherAdapter) continue;
          if (otherChain === chainKey && otherAdapter.toLowerCase() === adapterAddress.toLowerCase()) continue;

          const otherEnv = getEnvironmentForChainKey(otherChain);
          if (newEnv !== otherEnv) {
            console.log(`   ↪️  Skipping cross-environment peering: ${chainKey}(${newEnv}) ↔ ${otherChain}(${otherEnv})`);
            continue;
          }

          const otherEid = Number(otherEidStr);
          if (!otherEid || Number.isNaN(otherEid)) continue;

          try {
            const currentPeer = await newAdapter.peers(otherEid);
            const expectedPeer = ethers.utils.hexZeroPad(otherAdapter, 32);
            if (currentPeer.toLowerCase() !== expectedPeer.toLowerCase()) {
              console.log(`🔗 Setting peer in new (${chainKey}) for ${otherChain} (EID ${otherEid}) -> ${otherAdapter}`);
              await (await newAdapter.setPeer(otherEid, expectedPeer)).wait();
            } else {
              console.log(`   ↪️  Already peered: ${otherChain}`);
            }
          } catch (e) {
            console.log(`⚠️  Could not set peer in new adapter for ${otherChain}`);
            console.log(e);
          }

          // Also try to set in EXISTING adapter (reverse) if we can reach its RPC and have ownership
          const otherRpc = getRpcUrl(otherChain);
          if (otherRpc && process.env.PRIVATE_KEY) {
            try {
              const { ethers: ethersLib } = await import("ethers");
              const JsonRpcProvider = (ethersLib as any).providers.JsonRpcProvider;
              const provider = new JsonRpcProvider(otherRpc);
              const wallet = new (ethersLib as any).Wallet(process.env.PRIVATE_KEY, provider);
              const otherAdapterWithPeer = new (ethersLib as any).Contract(otherAdapter, [
                "function peers(uint32) view returns (bytes32)",
                "function setPeer(uint32 eid, bytes32 peer) external"
              ], wallet);
              const newEid = Number(deployment.eid);
              const currentPeerOther = await otherAdapterWithPeer.peers(newEid);
              const expectedPeerOther = ethers.utils.hexZeroPad(adapterAddress, 32);
              if (currentPeerOther.toLowerCase() !== expectedPeerOther.toLowerCase()) {
                console.log(`🔁 Setting peer in existing (${otherChain}) for ${chainKey} (EID ${newEid}) -> ${adapterAddress}`);
                const peerTx = await otherAdapterWithPeer.setPeer(newEid, expectedPeerOther);
                await peerTx.wait();
              } else {
                console.log(`   ↪️  Existing adapter already peers with new one (${chainKey})`);
              }
            } catch (e) {
              console.log(`⚠️  Could not update reverse peer on ${otherChain} (likely not owner or RPC unsupported)`);
              console.log(e);
            }
          }
        }
      }
    } catch (e) {
      console.log(`⚠️  Cross-peer wiring skipped due to error:`);
      console.log(e);
    }

    // Ownership transfers are handled by a separate script now to avoid disrupting configuration

    console.log(`✅ Deployment completed successfully!`);

    // Ensure lz-migrations has proper hardhat-deploy metadata
    await ensureLZChainIdFile(chainKey);

    return {
      tixToken: tixTokenAddress,
      serviceDeployer: serviceDeployerAddress || "existing/lookup-failed",
      upgradeableDeployer: upgradeableDeployerAddress || "existing/lookup-failed",
      omniAdapter: adapterAddress!,
      chain: chainKey,
      eid: deployment.eid
    };

  } catch (error) {
    console.error(`❌ Failed to deploy to ${chainKey}:`, error);
    return null;
  }
}

async function main() {
  console.log(`🚀 Starting deployment in ${MODE} mode`);
  console.log(`📋 Deploying to ${TARGET_CHAINS.length} chains in ${MODE} mode:`);
  TARGET_CHAINS.forEach(chain => console.log(`   - ${chain}`));
  console.log("🌐 Fetching LayerZero metadata...");
  const metadata = await fetchLZMetadata();

  console.log("📋 Starting deployment to multiple chains...\n");

  const deploymentResults: Array<{
    tixToken: string;
    serviceDeployer: string;
    upgradeableDeployer: string;
    omniAdapter: string;
    chain: string;
    eid: string;
  }> = [];
  const failedChains: string[] = [];
  let hasErrors = false;

  for (const chainKey of TARGET_CHAINS) {
    const deployment = findDeploymentForChain(chainKey, metadata);

    if (!deployment) {
      console.log(`⚠️  No deployment data found for ${chainKey}`);
      failedChains.push(chainKey);
      hasErrors = true;
      continue;
    }

    const result = await deployToChain(chainKey, deployment);
    if (result) {
      deploymentResults.push(result);
    } else {
      failedChains.push(chainKey);
      hasErrors = true;
      // Stop deployment on first error as requested
      console.log(`❌ Stopping deployment due to error on ${chainKey}`);
      break;
    }

    // Small delay between deployments
    await new Promise(resolve => setTimeout(resolve, 1000));
  }

  // Save results to file
  console.log("\n📊 Deployment Summary:");
  console.log("======================");

  if (deploymentResults.length > 0) {
    console.log("\n✅ Successful Deployments:");
    deploymentResults.forEach(result => {
      console.log(`\n🌐 ${result.chain} (EID: ${result.eid}):`);
      console.log(`   📄 TixToken:           ${result.tixToken}`);
      if (result.serviceDeployer && result.serviceDeployer !== "existing/lookup-failed") {
        console.log(`   🔧 ServiceDeployer:    ${result.serviceDeployer}`);
      } else if (result.serviceDeployer === "existing/lookup-failed") {
        console.log(`   🔧 ServiceDeployer:    (existing, lookup failed)`);
      }
      if (result.upgradeableDeployer && result.upgradeableDeployer !== "existing/lookup-failed") {
        console.log(`   ⬆️  UpgradeableDeployer: ${result.upgradeableDeployer}`);
      } else if (result.upgradeableDeployer === "existing/lookup-failed") {
        console.log(`   ⬆️  UpgradeableDeployer: (existing, lookup failed)`);
      }
      console.log(`   🌐 OmniAdapter:        ${result.omniAdapter}`);
    });

    // Save to JSON file
    const outputFile = `deployment-results-${MODE}-${new Date().toISOString().split('T')[0]}.json`;
    fs.writeFileSync(outputFile, JSON.stringify({
      mode: MODE,
      timestamp: new Date().toISOString(),
      deployments: deploymentResults
    }, null, 2));
    console.log(`\n💾 Results saved to ${outputFile}`);
  }

  if (failedChains.length > 0) {
    console.log("\n❌ Failed Chains:");
    failedChains.forEach(chain => console.log(`   - ${chain}`));
  }

  console.log(`\n📈 Total: ${deploymentResults.length} successful, ${failedChains.length} failed`);
}

// Export functions for use by other scripts
export { deployToChain, findDeploymentForChain };

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  main().catch((error) => {
    console.error("Deployment failed:", error);
    process.exitCode = 1;
  });
}
