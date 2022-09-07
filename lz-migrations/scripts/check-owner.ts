#!/usr/bin/env node

import { ethers } from "ethers";
import * as fs from "fs";
import * as path from "path";

const OUTPUT_DIR = path.resolve(__dirname, "../../deployments");
const ADAPTERS_CSV = path.join(OUTPUT_DIR, "adapters.csv");

// Minimal ABI for owner check
const OWNER_ABI = [
  "function owner() external view returns (address)"
];

type Scope = "all" | string;

function getAlchemyUrl(chainKey: string): string | null {
  const key = process.env.ALCHEMY_API_KEY;
  if (!key) return null;
  switch (chainKey) {
    case "sepolia-testnet": return `https://eth-sepolia.g.alchemy.com/v2/${key}`;
    case "ethereum-mainnet": return `https://eth-mainnet.g.alchemy.com/v2/${key}`;
    case "base-sepolia": return `https://base-sepolia.g.alchemy.com/v2/${key}`;
    case "base-mainnet": return `https://base-mainnet.g.alchemy.com/v2/${key}`;
    case "polygon-mumbai": return `https://polygon-mumbai.g.alchemy.com/v2/${key}`;
    case "amoy-testnet": return `https://polygon-amoy.g.alchemy.com/v2/${key}`;
    case "polygon-mainnet": return `https://polygon-mainnet.g.alchemy.com/v2/${key}`;
    case "arbitrum-sepolia": return `https://arb-sepolia.g.alchemy.com/v2/${key}`;
    case "arbitrum-mainnet": return `https://arb-mainnet.g.alchemy.com/v2/${key}`;
    case "optimism-sepolia": return `https://opt-sepolia.g.alchemy.com/v2/${key}`;
    case "optimism-mainnet": return `https://opt-mainnet.g.alchemy.com/v2/${key}`;
    case "fuji": return `https://avax-fuji.g.alchemy.com/v2/${key}`;
    case "avalanche-mainnet": return `https://avax-mainnet.g.alchemy.com/v2/${key}`;
    default: return null;
  }
}

function getEnvRpcUrl(chainKey: string): string | null {
  const envKey = `${chainKey.toUpperCase().replace(/-/g, "_")}_RPC_URL` as keyof NodeJS.ProcessEnv;
  return process.env[envKey] || null;
}

function getRpcUrl(chainKey: string): string | null {
  return getAlchemyUrl(chainKey) || getEnvRpcUrl(chainKey);
}

function readCsv(file: string): string[][] {
  if (!fs.existsSync(file)) return [];
  const content = fs.readFileSync(file, "utf8").trim();
  if (!content) return [];
  const lines = content.split(/\r?\n/);
  if (lines.length <= 1) return [];
  return lines.slice(1).map(l => l.split(","));
}

function normalizeScope(value: string | undefined | null): Scope | undefined {
  const v = (value || "").trim().toLowerCase();
  if (!v) return undefined;
  return v;
}

function getScopeFromArgs(): Scope {
  const envScope = normalizeScope(process.env.CHECK_SCOPE);
  if (envScope) return envScope;
  const argv = process.argv.slice(2);
  let scope: Scope = "all";
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--scope" && argv[i + 1]) {
      scope = normalizeScope(argv[i + 1]) || scope;
      i++;
      continue;
    }
    if (a.startsWith("--scope=")) {
      scope = normalizeScope(a.split("=")[1]) || scope;
      continue;
    }
  }
  return scope;
}

async function main() {
  console.log("🔍 Checking adapter contract ownership from CSV...\n");

  const scope = getScopeFromArgs();
  const rows = readCsv(ADAPTERS_CSV);
  if (rows.length === 0) {
    console.error("❌ No adapter rows found. Ensure deployments/adapters.csv exists and has data.");
    return;
  }

  const pk = process.env.PRIVATE_KEY || "";

  for (const row of rows) {
    const [chain, eidStr, adapter] = row.map(s => s.trim());
    if (!adapter || adapter === "") continue;
    if (scope !== "all" && scope !== chain) continue;

    const rpcUrl = getRpcUrl(chain);
    if (!rpcUrl) {
      console.log(`   ⚠️  Missing RPC for ${chain}. Skipping.`);
      continue;
    }

    try {
      const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
      const signer = pk ? new ethers.Wallet(pk, provider) : null;
      const signerAddr = signer ? await signer.getAddress() : null;

      console.log(`📡 ${chain} (eid=${eidStr})`);
      console.log(`   - Adapter: ${adapter}`);
      if (signerAddr) console.log(`   - Signer:  ${signerAddr}`);

      const contract = new ethers.Contract(adapter, OWNER_ABI, provider);
      const owner: string = await contract.owner();
      console.log(`   - Owner:   ${owner}`);

      if (signerAddr) {
        if (owner.toLowerCase() === signerAddr.toLowerCase()) {
          console.log("   ✅ Signer IS owner");
        } else {
          console.log("   ❌ Signer is NOT owner");
        }
      }
    } catch (e) {
      console.log(`   ❌ Failed to check ${chain}: ${(e as any)?.message ?? e}`);
    }

    console.log("");
  }

  console.log("✅ Ownership check complete");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
