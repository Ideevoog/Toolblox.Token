#!/usr/bin/env node

import { ethers } from "hardhat";

// Configuration
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

const ENDPOINTS = {
  "arbitrum-sepolia": "0x6EDCE65403992e310A62460808c4b910D972f10f",
  "base-sepolia": "0x6EDCE65403992e310A62460808c4b910D972f10f"
};

const READ_LIBS = {
  "arbitrum-sepolia": "0x54320b901FDe49Ba98de821Ccf374BA4358a8bf6",
  "base-sepolia": "0x29270F0CFC54432181C853Cd25E2Fb60A68E03f2"
};

// Minimal ABI for the functions we need
const ENDPOINT_ABI = [
  "function setSendLibrary(address oapp, uint32 eid, address lib) external",
  "function setReceiveLibrary(address oapp, uint32 eid, address lib) external",
  "function getSendLibrary(address sender, uint32 dstEid) external view returns (address lib)",
  "function getReceiveLibrary(address receiver, uint32 srcEid) external view returns (address lib)"
];

async function main() {
  console.log("🔧 Manually configuring ReadLib1002 for LayerZero Read operations...\n");

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
    return;
  }

  console.log(`🔧 Configuring ReadLib1002 for: ${currentChain}\n`);

  const adapterInfo = ADAPTERS[currentChain as keyof typeof ADAPTERS];
  const endpointAddress = ENDPOINTS[currentChain as keyof typeof ENDPOINTS];
  const readLibAddress = READ_LIBS[currentChain as keyof typeof READ_LIBS];

  console.log(`📋 Configuration:`);
  console.log(`   - Adapter: ${adapterInfo.address}`);
  console.log(`   - Endpoint: ${endpointAddress}`);
  console.log(`   - ReadLib1002: ${readLibAddress}`);

  try {
    // Get signer (must be the owner of the adapter)
    const [signer] = await ethers.getSigners();
    console.log(`👤 Using signer: ${signer.address}`);

    // Get endpoint contract
    const endpoint = new ethers.Contract(endpointAddress, ENDPOINT_ABI, signer);
    
    const readChannelId = 1; // READ_CHANNEL_1

    // Check current configuration
    console.log(`\n🔍 Checking current configuration...`);
    try {
      const currentSendLib = await endpoint.getSendLibrary(adapterInfo.address, readChannelId);
      console.log(`   Current send library: ${currentSendLib}`);
    } catch (error) {
      console.log(`   Current send library: NOT SET (this is the problem!)`);
    }

    try {
      const currentReceiveLib = await endpoint.getReceiveLibrary(adapterInfo.address, readChannelId);
      console.log(`   Current receive library: ${currentReceiveLib}`);
    } catch (error) {
      console.log(`   Current receive library: NOT SET`);
    }

    // Set ReadLib1002 as send library
    console.log(`\n🔧 Setting ReadLib1002 as send library...`);
    try {
      const setSendTx = await endpoint.setSendLibrary(adapterInfo.address, readChannelId, readLibAddress, {
        gasLimit: 500000 // Set manual gas limit
      });
      console.log(`   Transaction hash: ${setSendTx.hash}`);
      console.log(`   ⏳ Waiting for confirmation...`);
      await setSendTx.wait();
      console.log(`   ✅ Send library configured!`);
    } catch (error: any) {
      console.error(`   ❌ Failed to set send library: ${error.message}`);
      if (error.message.includes("Ownable")) {
        console.error(`   💡 Make sure you're using the owner account of the adapter contract`);
      }
    }

    // Set ReadLib1002 as receive library
    console.log(`\n🔧 Setting ReadLib1002 as receive library...`);
    try {
      const setReceiveTx = await endpoint.setReceiveLibrary(adapterInfo.address, readChannelId, readLibAddress, {
        gasLimit: 500000 // Set manual gas limit
      });
      console.log(`   Transaction hash: ${setReceiveTx.hash}`);
      console.log(`   ⏳ Waiting for confirmation...`);
      await setReceiveTx.wait();
      console.log(`   ✅ Receive library configured!`);
    } catch (error: any) {
      console.error(`   ❌ Failed to set receive library: ${error.message}`);
    }

    // Verify the configuration
    console.log(`\n✅ Verifying configuration...`);
    try {
      const newSendLib = await endpoint.getSendLibrary(adapterInfo.address, readChannelId);
      const newReceiveLib = await endpoint.getReceiveLibrary(adapterInfo.address, readChannelId);
      
      console.log(`   New send library: ${newSendLib}`);
      console.log(`   New receive library: ${newReceiveLib}`);
      
      if (newSendLib.toLowerCase() === readLibAddress.toLowerCase()) {
        console.log(`   🎉 SUCCESS! Send library is now ReadLib1002!`);
      } else {
        console.log(`   ⚠️  Send library verification failed`);
      }
      
      if (newReceiveLib.toLowerCase() === readLibAddress.toLowerCase()) {
        console.log(`   🎉 SUCCESS! Receive library is now ReadLib1002!`);
      } else {
        console.log(`   ⚠️  Receive library verification failed`);
      }
    } catch (error) {
      console.error(`   ❌ Verification failed: ${error}`);
    }

  } catch (error) {
    console.error(`❌ Configuration failed: ${error}`);
  }

  console.log(`\n📋 Next steps:`);
  console.log(`   1. Run this script on the other chain (if needed)`);
  console.log(`   2. Test your cross-chain lzRead operations`);
  console.log(`   3. Call claimRewards() on TokenWorkflow to test the full flow`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
