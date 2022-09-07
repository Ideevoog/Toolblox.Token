#!/usr/bin/env node
/**
 * Deploy to a specific network
 *
 * Usage:
 *   npx hardhat run scripts/deploy-to-network.ts --network baseSepolia
 *   npx hardhat run scripts/deploy-to-network.ts --network sepolia
 *   npx hardhat run scripts/deploy-to-network.ts --network polygonMumbai
 */

import { ethers } from "hardhat";
import { deployToChain, findDeploymentForChain } from "./deploy";
import fetch from "node-fetch";
import type { Response } from "node-fetch";

async function fetchLZMetadata(): Promise<any> {
  // In single-network mode we only need metadata to resolve endpoint/eid.
  const res: Response = await fetch('https://metadata.layerzero-api.com/v1/metadata/deployments');
  if (!res.ok) throw new Error(`LayerZero metadata fetch failed: ${res.status}`);
  return res.json();
}

async function main() {
  const network = await ethers.provider.getNetwork();
  console.log(`🚀 Deploying to network: ${network.name} (Chain ID: ${network.chainId})`);

  // For single network deployment, we need to map the network name to our chain keys
  const networkToChainKey: { [key: number]: string } = {
    // Testnets
    11155111: "sepolia-testnet",      // Ethereum Sepolia
    84532: "base-sepolia",            // Base Sepolia
    8453: "base",            // Base
    80001: "polygon-mumbai",          // Polygon Mumbai
    80002: "amoy-testnet",            // Polygon Amoy
    421614: "arbitrum-sepolia",       // Arbitrum Sepolia
    11155420: "optimism-sepolia",     // Optimism Sepolia
    97: "bsc-testnet",                // BSC Testnet
    43113: "fuji",                    // Avalanche Fuji
    534351: "scroll-sepolia",         // Scroll Sepolia
    1301: "unichain-testnet",         // Unichain Sepolia

    // Mainnets (exact LZ chainKeys requested)
    1: "ethereum",
    42161: "arbitrum",
    56: "bsc",
    43114: "avalanche-mainnet",
    534352: "scroll-mainnet",
    130: "unichain-mainnet",
    42220: "celo-mainnet",
    44787: "celo-testnet",
    7777777: "zora",
    999999999: "zora-testnet",
    480: "worldchain",
    137: "polygon",
    10: "optimism",
    69: "optimism",                    // legacy/testnet id mapping for safety
    295: "hedera-mainnet",
  };

  const chainKey = networkToChainKey[Number(network.chainId)];
  if (!chainKey) {
    console.error(`❌ Unsupported network: ${network.name} (Chain ID: ${network.chainId})`);
    console.log("Supported networks:");
    Object.entries(networkToChainKey).forEach(([chainId, key]) => {
      console.log(`  - Chain ID ${chainId}: ${key}`);
    });
    process.exit(1);
  }

  console.log(`📋 Using chain key: ${chainKey}`);

  // Fetch LayerZero metadata and find deployment for this chain
  console.log("🌐 Fetching LayerZero metadata...");
  const metadata = await fetchLZMetadata();
  const deployment = findDeploymentForChain(chainKey, metadata);

  if (!deployment) {
    console.error(`❌ No deployment data found for ${chainKey}`);
    process.exit(1);
  }

  console.log(`📋 Found deployment for ${chainKey} (EID: ${deployment.eid})`);

  // Deploy to this specific chain
  const result = await deployToChain(chainKey, deployment);

  if (result) {
    console.log("\n✅ Deployment successful!");
    console.log("📊 Results:");
    console.log(`   🌐 Chain: ${result.chain} (EID: ${result.eid})`);
    console.log(`   📄 TixToken: ${result.tixToken}`);
    if (result.serviceDeployer && result.serviceDeployer !== "existing/lookup-failed") {
      console.log(`   🔧 ServiceDeployer: ${result.serviceDeployer}`);
    }
    if (result.upgradeableDeployer && result.upgradeableDeployer !== "existing/lookup-failed") {
      console.log(`   ⬆️  UpgradeableDeployer: ${result.upgradeableDeployer}`);
    }
    console.log(`   🌐 OmniAdapter: ${result.omniAdapter}`);
  } else {
    console.error("❌ Deployment failed!");
    process.exit(1);
  }
}

if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

export { main };
