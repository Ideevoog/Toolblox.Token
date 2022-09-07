#!/usr/bin/env node

import { ethers } from "hardhat";
import * as fs from "fs";
import fetch from "node-fetch";
import { fetchLZMetadata, findDeploymentForChain } from "./deploy";

const OUTPUT_FILE = "deployments/tokenworkflows.csv";

function ensureFile() {
  if (!fs.existsSync(OUTPUT_FILE)) {
    fs.writeFileSync(OUTPUT_FILE, "chain,eid,tokenWorkflow\n");
  }
}

function appendRow(chain: string, eid: string, addr: string) {
  ensureFile();
  fs.appendFileSync(OUTPUT_FILE, `${chain},${eid},${addr}\n`);
}

function getEnvRpcUrl(chainKey: string): string | null {
  const envKey = `${chainKey.toUpperCase().replace(/-/g, '_')}_RPC_URL`;
  return process.env[envKey] || null;
}

const CHAINS: string[] = [
  "arbitrum-sepolia",
  "optimism-sepolia",
  "base-sepolia",
];

async function deployTokenWorkflow(chainKey: string, eid: string) {
  console.log(`\n🚀 Deploying TokenWorkflow on ${chainKey} (EID: ${eid})`);

  const TokenWorkflow = await ethers.getContractFactory("TokenWorkflow");
  const token = await TokenWorkflow.deploy();
  await token.deployed();

  console.log(`✅ TokenWorkflow deployed: ${token.address}`);
  appendRow(chainKey, eid, token.address);
}

async function main() {
  console.log("📋 Preparing TokenWorkflow deployments...");
  const metadata = await fetchLZMetadata();

  for (const chainKey of CHAINS) {
    const dep = findDeploymentForChain(chainKey, metadata);
    if (!dep) {
      console.log(`⚠️  No LayerZero metadata for ${chainKey}; skipping.`);
      continue;
    }

    console.log(`➡️  Target ${chainKey}: EID ${dep.eid}`);
    await deployTokenWorkflow(chainKey, dep.eid);
  }

  console.log("\n📊 All requested TokenWorkflow deployments attempted. Check deployments/tokenworkflows.csv");
}

if (require.main === module) {
  main().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}

export { main };


