#!/usr/bin/env node

import fetch from "node-fetch";
import * as fs from "fs";
import * as path from "path";

interface LZDeployment {
  eid: string;
  endpoint?: { address: string };
  endpointV2?: { address: string };
  readLib1002?: { address: string };
  sendUln302?: { address: string };
  receiveUln302?: { address: string };
  dvn?: { address: string };
  executor?: { address: string };
  chainKey: string;
  stage: string;
  version: number;
}

interface LZChainData {
  deployments: LZDeployment[];
  chainKey: string;
}

interface LZMetadata {
  [slug: string]: LZChainData;
}

async function fetchLZMetadata(): Promise<LZMetadata> {
  try {
    const response = await fetch('https://metadata.layerzero-api.com/v1/metadata/deployments');
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    const data = await response.json() as LZMetadata;
    return data;
  } catch (error) {
    console.error('Failed to fetch LayerZero metadata:', error);
    throw error;
  }
}

function getChainDataByChainKey(metadata: LZMetadata, chainKey: string): LZChainData | undefined {
  for (const [, chainData] of Object.entries(metadata)) {
    if (chainData.chainKey === chainKey) {
      return chainData;
    }
  }
  return undefined;
}

function getLatestDeployment(chainData: LZChainData): LZDeployment | undefined {
  if (!chainData.deployments || chainData.deployments.length === 0) {
    return undefined;
  }
  
  // Sort by version descending, then by stage (mainnet > testnet)
  const sorted = chainData.deployments.sort((a, b) => {
    if (a.version !== b.version) {
      return b.version - a.version;
    }
    if (a.stage !== b.stage) {
      return a.stage === 'mainnet' ? -1 : 1;
    }
    return 0;
  });
  
  return sorted[0];
}

async function main() {
  console.log("🔍 Fetching LayerZero addresses for Arbitrum Sepolia and Base Sepolia...\n");

  try {
    const metadata = await fetchLZMetadata();
    // Persist full metadata for layerzero.config.ts consumption
    const outPath = path.resolve(__dirname, '..', 'metadata.json');
    fs.writeFileSync(outPath, JSON.stringify(metadata, null, 2));
    console.log(`💾 Saved full metadata to ${outPath}`);
    
    const chains = ['arbitrum-sepolia', 'base-sepolia'];
    
    for (const chainKey of chains) {
      console.log(`\n📡 ${chainKey.toUpperCase()}:`);
      
      const chainData = getChainDataByChainKey(metadata, chainKey);
      if (!chainData) {
        console.log(`   ❌ Chain data not found`);
        continue;
      }
      
      const deployment = getLatestDeployment(chainData);
      if (!deployment) {
        console.log(`   ❌ No deployments found`);
        continue;
      }
      
      console.log(`   EID: ${deployment.eid}`);
      console.log(`   Endpoint: ${deployment.endpointV2?.address || deployment.endpoint?.address || 'N/A'}`);
      console.log(`   ReadLib1002: ${deployment.readLib1002?.address || 'N/A'}`);
      console.log(`   SendUln302: ${deployment.sendUln302?.address || 'N/A'}`);
      console.log(`   ReceiveUln302: ${deployment.receiveUln302?.address || 'N/A'}`);
      // Select a DVN from the chain-level dvns map (prefer lzReadCompatible + layerzero-labs)
      const dvns: Record<string, any> | undefined = (chainData as any).dvns;
      let selectedDvn: string | undefined;
      if (dvns) {
        // Prefer layerzero-labs with lzReadCompatible
        for (const [addr, info] of Object.entries(dvns)) {
          const id = (info as any)?.id;
          const lzReadOk = (info as any)?.lzReadCompatible || false;
          if (id === 'layerzero-labs' && lzReadOk) { selectedDvn = addr; break; }
        }
        // Fallback to first lzReadCompatible DVN
        if (!selectedDvn) {
          for (const [addr, info] of Object.entries(dvns)) {
            const lzReadOk = (info as any)?.lzReadCompatible || false;
            if (lzReadOk) { selectedDvn = addr; break; }
          }
        }
      }
      console.log(`   DVN: ${selectedDvn || 'N/A'}`);
      console.log(`   Executor: ${deployment.executor?.address || 'N/A'}`);
    }
    
    console.log(`\n📋 layerzero.config.ts will now auto-read metadata.json if present.`);
    
  } catch (error) {
    console.error(`❌ Failed to fetch addresses: ${error}`);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

