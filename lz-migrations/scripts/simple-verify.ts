#!/usr/bin/env node

import { ethers } from "hardhat";

// Adapter addresses from your CSV
const ADAPTERS = {
  "arbitrum-sepolia": {
    eid: 40231,
    address: "0xaeE469283fF371919019c87dB6D7792976AF75DD"
  },
  "base-sepolia": {
    eid: 40245,
    address: "0x317A866f79aea22bD8B12BE5AD218A2141dbbB32"
  }
};

// LayerZero V2 Endpoints
const ENDPOINTS = {
  "arbitrum-sepolia": "0x6EDCE65403992e310A62460808c4b910D972f10f",
  "base-sepolia": "0x6EDCE65403992e310A62460808c4b910D972f10f"
};

// ReadLib1002 addresses (from LayerZero metadata)
const READ_LIBS = {
  "arbitrum-sepolia": "0x54320b901FDe49Ba98de821Ccf374BA4358a8bf6",
  "base-sepolia": "0x29270F0CFC54432181C853Cd25E2Fb60A68E03f2"
};

// Minimal ABI for the functions we need
const ADAPTER_ABI = [
  "function READ_CHANNEL() external view returns (uint32)",
  "function peers(uint32 eid) external view returns (bytes32)"
];

const ENDPOINT_ABI = [
  "function getSendLibrary(address sender, uint32 dstEid) external view returns (address lib)",
  "function getReceiveLibrary(address receiver, uint32 srcEid) external view returns (address lib)"
];

async function main() {
  console.log("🔍 Verifying LayerZero Read Configuration...\n");

  const network = await ethers.provider.getNetwork();
  console.log(`📡 Connected to network: ${network.name} (Chain ID: ${network.chainId})`);

  // Determine which chain we're on
  let currentChain: string;
  if (Number(network.chainId) === 421614) {
    currentChain = "arbitrum-sepolia";
  } else if (Number(network.chainId) === 84532) {
    currentChain = "base-sepolia";
  } else {
    console.error(`❌ Unsupported network. Please run on Arbitrum Sepolia (421614) or Base Sepolia (84532)`);
    console.error(`   Current network chainId: ${network.chainId}`);
    return;
  }

  console.log(`🔧 Checking configuration for: ${currentChain}\n`);

  const adapterInfo = ADAPTERS[currentChain as keyof typeof ADAPTERS];
  const endpointAddress = ENDPOINTS[currentChain as keyof typeof ENDPOINTS];
  const expectedReadLib = READ_LIBS[currentChain as keyof typeof READ_LIBS];

  try {
    // Check if adapter exists
    const adapterCode = await ethers.provider.getCode(adapterInfo.address);
    if (adapterCode === "0x") {
      console.error(`❌ Adapter contract not found at: ${adapterInfo.address}`);
      return;
    }
    console.log(`✅ Adapter contract found at: ${adapterInfo.address}`);

    // Get adapter contract with minimal ABI
    const adapter = new ethers.Contract(adapterInfo.address, ADAPTER_ABI, ethers.provider);
    
    // Check READ_CHANNEL configuration
    try {
      const readChannel = await adapter.READ_CHANNEL();
      console.log(`📖 READ_CHANNEL: ${readChannel}`);
      
      if (readChannel.toString() === "0") {
        console.warn(`⚠️  READ_CHANNEL is 0 - this means lzRead is not configured!`);
      } else {
        console.log(`✅ READ_CHANNEL is properly set to: ${readChannel}`);
      }
    } catch (error) {
      console.error(`❌ Failed to read READ_CHANNEL: ${error}`);
    }

    // Check endpoint configuration
    const endpoint = new ethers.Contract(endpointAddress, ENDPOINT_ABI, ethers.provider);
    
    // Check what send library is configured for channel 1
    const readChannelId = 1;
    try {
      const currentSendLib = await endpoint.getSendLibrary(adapterInfo.address, readChannelId);
      console.log(`📚 Current send library for channel ${readChannelId}: ${currentSendLib}`);
      console.log(`📚 Expected ReadLib1002: ${expectedReadLib}`);
      
      if (currentSendLib.toLowerCase() === expectedReadLib.toLowerCase()) {
        console.log(`🎉 SUCCESS! ReadLib1002 is properly configured!`);
      } else {
        console.error(`❌ PROBLEM FOUND! Send library is NOT ReadLib1002`);
        console.error(`   Current: ${currentSendLib}`);
        console.error(`   Expected: ${expectedReadLib}`);
        console.error(`\n🔧 To fix this, run:`);
        console.error(`   npm run wire-read`);
      }
    } catch (error) {
      console.error(`❌ Failed to check send library: ${error}`);
    }

    // Check receive library configuration
    try {
      const currentReceiveLib = await endpoint.getReceiveLibrary(adapterInfo.address, readChannelId);
      console.log(`📥 Current receive library for channel ${readChannelId}: ${currentReceiveLib}`);
    } catch (error) {
      console.error(`❌ Failed to check receive library: ${error}`);
    }

    // Check if peer is set for read channel
    try {
      const peer = await adapter.peers(readChannelId);
      console.log(`🤝 Peer for channel ${readChannelId}: ${peer}`);
      
      if (peer === "0x0000000000000000000000000000000000000000000000000000000000000000") {
        console.warn(`⚠️  No peer set for read channel - this is expected for lzRead`);
      } else {
        console.log(`✅ Peer configured for read channel`);
      }
    } catch (error) {
      console.error(`❌ Failed to check peer: ${error}`);
    }

  } catch (error) {
    console.error(`❌ Verification failed: ${error}`);
  }

  console.log(`\n📋 Summary:`);
  console.log(`   - Chain: ${currentChain}`);
  console.log(`   - Adapter: ${adapterInfo.address}`);
  console.log(`   - Endpoint: ${endpointAddress}`);
  console.log(`   - Expected ReadLib1002: ${expectedReadLib}`);
  console.log(`\n🔧 Next steps if ReadLib1002 is not configured:`);
  console.log(`   1. npm run wire-read (to configure ReadLib1002 properly)`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

