import { HardhatUserConfig } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import "@layerzerolabs/toolbox-hardhat";
import "hardhat-deploy";
import { EndpointId } from "@layerzerolabs/lz-definitions";
import * as dotenv from "dotenv";

// Load environment variables from current directory (copied from parent)
dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.20",
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    // Arbitrum Sepolia with EID mapping for LayerZero CLI
    arbitrumSepolia: {
      eid: EndpointId.ARBSEP_V2_TESTNET,   // 40231
      chainId: 421614,
      url: process.env.ALCHEMY_API_KEY
        ? `https://arb-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`
        : process.env.ARBITRUM_SEPOLIA_RPC_URL || "https://sepolia-rollup.arbitrum.io/rpc",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },

    // Base Sepolia with EID mapping for LayerZero CLI
    baseSepolia: {
      eid: EndpointId.BASESEP_V2_TESTNET,  // 40245
      chainId: 84532,
      url: process.env.ALCHEMY_API_KEY
        ? `https://base-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`
        : process.env.BASE_SEPOLIA_RPC_URL || "https://sepolia.base.org",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },

    // Arbitrum mainnet with EID mapping
    arbitrum: {
      eid: EndpointId.ARBITRUM_V2_MAINNET, // 30110
      chainId: 42161,
      url: process.env.ALCHEMY_API_KEY
        ? `https://arb-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`
        : process.env.ARBITRUM_RPC_URL || "https://arb1.arbitrum.io/rpc",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },

    // Base mainnet with EID mapping
    baseMainnet: {
      eid: EndpointId.BASE_V2_MAINNET, // 30184
      chainId: 8453,
      url: process.env.ALCHEMY_API_KEY
        ? `https://base-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`
        : process.env.BASE_MAINNET_RPC_URL || "https://mainnet.base.org",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
  },
  paths: {
    sources: "./contracts", // We'll create symlinks or copy needed contracts
    artifacts: "../artifacts",
    cache: "../cache",
    tests: "./test"
  }
};

export default config;
