#!/usr/bin/env node

import { ethers } from "ethers";
import * as fs from "fs";

const OUTPUT_DIR = "deployments";
const TIX_CSV = `${OUTPUT_DIR}/tix.csv`;
const ADAPTERS_CSV = `${OUTPUT_DIR}/adapters.csv`;
const FINAL_OWNER = process.env.FINAL_OWNER || "";

type Scope = "all" | "tix" | "adapters";

// Known chainId map for chain keys present in CSVs
const CHAIN_KEY_TO_CHAIN_ID: Record<string, number> = {
  // Ethereum
  "ethereum-mainnet": 1,
  "sepolia-testnet": 11155111,

  // Base
  "base": 8453,
  "base-mainnet": 8453,
  "base-sepolia": 84532,

  // Polygon
  "polygon": 137,
  "polygon-mainnet": 137,
  "polygon-mumbai": 80001,
  "amoy-testnet": 80002,

  // Arbitrum
  "arbitrum": 42161,
  "arbitrum-mainnet": 42161,
  "arbitrum-sepolia": 421614,

  // Scroll
  "scroll": 534352,
  "scroll-mainnet": 534352,
  "scroll-testnet": 534351,
  "scroll-sepolia": 534351,

  // Optimism
  "optimism": 10,
  "optimism-mainnet": 10,
  "optimism-sepolia": 11155420,

  // Avalanche
  "fuji": 43113,
  "avalanche-mainnet": 43114,

  // Hedera
  "hedera-testnet": 296,
  "hedera-mainnet": 295,
};

// Conservative default RPCs for common networks in our CSVs (safe, public where possible)
const DEFAULT_RPC_URLS: Record<string, string> = {
  // Ethereum
  "ethereum-mainnet": "https://cloudflare-eth.com",
  "sepolia-testnet": "https://rpc.sepolia.org",

  // Base
  "base": "https://mainnet.base.org",
  "base-mainnet": "https://mainnet.base.org",
  "base-sepolia": "https://sepolia.base.org",

  // Polygon
  "polygon": "https://polygon-rpc.com",
  "polygon-mainnet": "https://polygon-rpc.com",
  // Mumbai is deprecated, use a community RPC if needed
  "polygon-mumbai": "https://rpc.ankr.com/polygon_mumbai",
  "amoy-testnet": "https://rpc-amoy.polygon.technology",

  // Arbitrum
  "arbitrum": "https://arb1.arbitrum.io/rpc",
  "arbitrum-mainnet": "https://arb1.arbitrum.io/rpc",
  "arbitrum-sepolia": "https://sepolia-rollup.arbitrum.io/rpc",

  // Scroll
  "scroll": "https://rpc.scroll.io",
  "scroll-mainnet": "https://rpc.scroll.io",
  "scroll-testnet": "https://sepolia-rpc.scroll.io",
  "scroll-sepolia": "https://sepolia-rpc.scroll.io",

  // Optimism
  "optimism": "https://mainnet.optimism.io",
  "optimism-mainnet": "https://mainnet.optimism.io",
  "optimism-sepolia": "https://sepolia.optimism.io",

  // Avalanche
  "fuji": "https://api.avax-test.network/ext/bc/C/rpc",
  "avalanche-mainnet": "https://api.avax.network/ext/bc/C/rpc",

  // Hedera
  "hedera-testnet": "https://testnet.hashio.io/api",
  "hedera-mainnet": "https://mainnet.hashio.io/api",
};

function getAlchemyUrl(chainKey: string): string | null {
  const key = process.env.ALCHEMY_API_KEY;
  if (!key) return null;
  switch (chainKey) {
    case 'sepolia-testnet': return `https://eth-sepolia.g.alchemy.com/v2/${key}`;
    case 'ethereum-mainnet': return `https://eth-mainnet.g.alchemy.com/v2/${key}`;
    case 'base-sepolia': return `https://base-sepolia.g.alchemy.com/v2/${key}`;
    case 'base-mainnet': return `https://base-mainnet.g.alchemy.com/v2/${key}`;
    case 'base': return `https://base-mainnet.g.alchemy.com/v2/${key}`;
    // Mumbai is deprecated on many providers; prefer env/defaults instead of Alchemy
    // case 'polygon-mumbai': return `https://polygon-mumbai.g.alchemy.com/v2/${key}`;
    case 'amoy-testnet': return `https://polygon-amoy.g.alchemy.com/v2/${key}`;
    case 'polygon-mainnet': return `https://polygon-mainnet.g.alchemy.com/v2/${key}`;
    case 'polygon': return `https://polygon-mainnet.g.alchemy.com/v2/${key}`;
    case 'arbitrum-sepolia': return `https://arb-sepolia.g.alchemy.com/v2/${key}`;
    case 'arbitrum-mainnet': return `https://arb-mainnet.g.alchemy.com/v2/${key}`;
    case 'arbitrum': return `https://arb-mainnet.g.alchemy.com/v2/${key}`;
    case 'optimism-sepolia': return `https://opt-sepolia.g.alchemy.com/v2/${key}`;
    case 'optimism-mainnet': return `https://opt-mainnet.g.alchemy.com/v2/${key}`;
    case 'fuji': return `https://avax-fuji.g.alchemy.com/v2/${key}`;
    case 'avalanche-mainnet': return `https://avax-mainnet.g.alchemy.com/v2/${key}`;
    default: return null;
  }
}

function getEnvRpcUrl(chainKey: string): string | null {
  const envKey = `${chainKey.toUpperCase().replace(/-/g, '_')}_RPC_URL`;
  return (process.env as any)[envKey] || null;
}

function getRpcUrl(chainKey: string): string | null {
  // Prefer explicit env var, then Alchemy, then conservative defaults
  return getEnvRpcUrl(chainKey) || getAlchemyUrl(chainKey) || DEFAULT_RPC_URLS[chainKey] || null;
}

function normalizeScope(value: string | undefined | null): Scope | undefined {
  const v = (value || "").trim().toLowerCase();
  if (v === "tix" || v === "adapters" || v === "all") return v as Scope;
  return undefined;
}

function getScopeFromArgs(): Scope {
  // 1) ENV override (works with npm scripts on Windows)
  const envScope = normalizeScope(process.env.TRANSFER_SCOPE);
  if (envScope) return envScope;

  // 2) CLI args (works when running the script directly with node)
  const argv = process.argv.slice(2);
  let scope: Scope = "all";
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--scope" && argv[i + 1]) {
      const v = normalizeScope(argv[i + 1]);
      if (v) scope = v;
      i++;
      continue;
    }
    if (a.startsWith("--scope=")) {
      const v = normalizeScope(a.split("=")[1]);
      if (v) scope = v;
      continue;
    }
  }
  return scope;
}

function readCsv(file: string): string[][] {
  if (!fs.existsSync(file)) return [];
  const raw = fs.readFileSync(file, "utf8").trim();
  if (!raw) return [];
  const lines = raw.split(/\r?\n/);
  if (lines.length <= 1) return [];
  const rows: string[][] = [];
  for (let i = 1; i < lines.length; i++) {
    const line = lines[i];
    const parts = line.split(",");
    if (parts.length < 3) {
      console.log(`   ⚠️  Malformed CSV row skipped: "${line}"`);
      continue;
    }
    rows.push(parts);
  }
  return rows;
}

async function tryTransferOwnable(address: string, abi: string[], label: string, wallet: ethers.Wallet) {
  try {
    if (!ethers.utils.isAddress(address)) {
      console.log(`   ↪️  Skipping ${label} ${address} (invalid address)`);
      return;
    }
    const code = await wallet.provider.getCode(address);
    if (!code || code === "0x") {
      console.log(`   ↪️  Skipping ${label} ${address} (no code at address)`);
      return;
    }
    const contract = new ethers.Contract(address, abi, wallet);
    const currentOwner = await contract.owner();
    
    // Check for pending owner (Ownable2Step)
    try {
      const pendingOwner = await contract.pendingOwner();
      if (pendingOwner && pendingOwner !== ethers.constants.AddressZero) {
        console.log(`   ↪️  Skipping ${label} ${address} (pending owner exists: ${pendingOwner})`);
        return;
      }
    } catch {
      // Not Ownable2Step, continue
    }
    
    const signerAddress = await wallet.getAddress();
    if (currentOwner.toLowerCase() !== signerAddress.toLowerCase()) {
      console.log(`   ↪️  Skipping ${label} ${address} (not owner)`);
      return;
    }
    if (currentOwner.toLowerCase() === FINAL_OWNER.toLowerCase()) {
      console.log(`   ↪️  Skipping ${label} ${address} (already owned by final owner)`);
      return;
    }
    console.log(`   👑 Transferring ownership of ${label} (${address}) ${currentOwner} -> ${FINAL_OWNER}`);
    let gasLimitOverride: ethers.BigNumber | number | undefined = undefined;
    try {
      const est = await contract.estimateGas.transferOwnership(FINAL_OWNER);
      // add 20% buffer
      gasLimitOverride = est.mul(12).div(10);
    } catch {
      // Some RPCs (e.g., Base) restrict estimation; fall back to a safe ceiling
      console.log(`   ⚠️  Could not estimate gas for ${label} ${address}: ${e}`);
      gasLimitOverride = 200000;
    }
    const tx = await contract.transferOwnership(FINAL_OWNER, { gasLimit: gasLimitOverride });
    await tx.wait();
    console.log(`   ✅ Transferred ${label}`);
  } catch (e) {
    const err: any = e;
    if (err?.code === 'INSUFFICIENT_FUNDS') {
      console.log(`   ⚠️  Could not transfer ${label} ${address}: insufficient funds on sender`);
      return;
    }
    console.log(`   ⚠️  Could not transfer ${label} ${address}: ${err?.message ?? e}`);
  }
}

async function run() {
  if (!FINAL_OWNER || !ethers.utils.isAddress(FINAL_OWNER)) {
    console.error("❌ FINAL_OWNER env var is missing or not a valid address");
    process.exit(1);
  }

  const scope = getScopeFromArgs();
  console.log(`🔎 Ownership cleanup across multiple chains | scope=${scope}`);

  const tixRows = readCsv(TIX_CSV);
  const adapterRows = readCsv(ADAPTERS_CSV);

  // Transfer for TIX, ServiceDeployer, UpgradeableServiceDeployer
  if (scope === "all" || scope === "tix") {
    for (const row of tixRows) {
      const [chain, _eid, tix, serviceDeployer, upgradeableDeployer] = row;
      const rpcUrl = getRpcUrl(chain);
      if (!rpcUrl) {
        console.log(`   ⚠️  Missing RPC for ${chain}. Skipping.`);
        continue;
      }
      const pk = process.env.PRIVATE_KEY;
      if (!pk) {
        console.error(`❌ PRIVATE_KEY is required to sign transactions`);
        process.exit(1);
      }
      const knownChainId = CHAIN_KEY_TO_CHAIN_ID[chain];
      const provider = knownChainId
        ? new ethers.providers.StaticJsonRpcProvider(rpcUrl, { chainId: knownChainId, name: chain })
        : new ethers.providers.JsonRpcProvider(rpcUrl);
      const wallet = new ethers.Wallet(pk, provider);
      if (tix && tix !== "") {
        await tryTransferOwnable(tix, [
          "function owner() view returns (address)",
          "function pendingOwner() view returns (address)",
          "function transferOwnership(address newOwner)"
        ], `TixToken (${chain})`, wallet);
      }
      if (serviceDeployer && serviceDeployer !== "" && serviceDeployer !== "existing/lookup-failed") {
        await tryTransferOwnable(serviceDeployer, [
          "function owner() view returns (address)",
          "function pendingOwner() view returns (address)",
          "function transferOwnership(address newOwner)"
        ], `ServiceDeployer (${chain})`, wallet);
      }
      if (upgradeableDeployer && upgradeableDeployer !== "" && upgradeableDeployer !== "existing/lookup-failed") {
        await tryTransferOwnable(upgradeableDeployer, [
          "function owner() view returns (address)",
          "function pendingOwner() view returns (address)",
          "function transferOwnership(address newOwner)"
        ], `UpgradeableServiceDeployer (${chain})`, wallet);
      }
    }
  }

  // Transfer for Adapters
  if (scope === "all" || scope === "adapters") {
    for (const row of adapterRows) {
      const [chain, _eid, adapter] = row;
      const rpcUrl = getRpcUrl(chain);
      if (!rpcUrl) {
        console.log(`   ⚠️  Missing RPC for ${chain}. Skipping.`);
        continue;
      }
      const pk = process.env.PRIVATE_KEY;
      if (!pk) {
        console.error(`❌ PRIVATE_KEY is required to sign transactions`);
        process.exit(1);
      }
      const knownChainId = CHAIN_KEY_TO_CHAIN_ID[chain];
      const provider = knownChainId
        ? new ethers.providers.StaticJsonRpcProvider(rpcUrl, { chainId: knownChainId, name: chain })
        : new ethers.providers.JsonRpcProvider(rpcUrl);
      const wallet = new ethers.Wallet(pk, provider);
      if (adapter && adapter !== "") {
        await tryTransferOwnable(adapter, [
          "function owner() view returns (address)",
          "function pendingOwner() view returns (address)",
          "function transferOwnership(address newOwner)"
        ], `Adapter (${chain})`, wallet);
      }
    }
  }

  console.log("✅ Ownership cleanup complete");
}

if (require.main === module) {
  run().catch((e) => {
    console.error(e);
    process.exit(1);
  });
}


