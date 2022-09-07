import { HardhatUserConfig } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import * as dotenv from "dotenv";

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
    // Local development
    hardhat: {
      chainId: 31337,
    },

    // Ethereum Mainnet
    mainnet: {
      url: process.env.MAINNET_RPC_URL || "https://cloudflare-eth.com",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 1,
    },

    // Ethereum Sepolia
    sepolia: {
      url: process.env.ALCHEMY_API_KEY
        ? `https://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`
        : process.env.SEPOLIA_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 11155111,
    },

    // Arbitrum Mainnet
    arbitrum: {
      url: process.env.ARBITRUM_RPC_URL || "https://arb1.arbitrum.io/rpc",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 42161,
    },

    // Base Sepolia
    baseSepolia: {
      url: process.env.ALCHEMY_API_KEY
        ? `https://base-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`
        : process.env.BASE_SEPOLIA_RPC_URL || "https://sepolia.base.org",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 84532,
    },

    // Base Mainnet
    baseMainnet: {
      url: process.env.ALCHEMY_API_KEY
        ? `https://base-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`
        : process.env.BASE_SEPOLIA_RPC_URL || "https://mainnet.base.org",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 8453,
    },

    // BSC Mainnet
    bsc: {
      url: process.env.BSC_RPC_URL || "https://bsc-dataseed.binance.org",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 56,
    },

    // Polygon Mumbai
    polygonMumbai: {
      url: process.env.ALCHEMY_API_KEY
        ? `https://polygon-mumbai.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`
        : process.env.POLYGON_MUMBAI_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 80001,
    },

    // Avalanche C-Chain Mainnet
    avalanche: {
      url: process.env.AVALANCHE_RPC_URL || "https://api.avax.network/ext/bc/C/rpc",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 43114,
    },

    // Polygon Amoy (new testnet)
    polygonAmoy: {
      url: process.env.ALCHEMY_API_KEY
        ? `https://polygon-amoy.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`
        : process.env.POLYGON_AMOY_RPC_URL || "https://rpc-amoy.polygon.technology",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 80002,
    },

    // Scroll Mainnet
    scroll: {
      url: process.env.SCROLL_RPC_URL || "https://rpc.scroll.io",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 534352,
    },

    // Arbitrum Sepolia
    arbitrumSepolia: {
      url: process.env.ALCHEMY_API_KEY
        ? `https://arb-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`
        : process.env.ARBITRUM_SEPOLIA_RPC_URL || "https://sepolia-rollup.arbitrum.io/rpc",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 421614,
    },

    // Unichain Mainnet
    unichain: {
      url: process.env.UNICHAIN_RPC_URL || "https://unichain.blockpi.network/v1/rpc/public",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 130,
    },

    // Optimism Sepolia
    optimismSepolia: {
      url: process.env.ALCHEMY_API_KEY
        ? `https://opt-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`
        : process.env.OPTIMISM_SEPOLIA_RPC_URL || "https://sepolia.optimism.io",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 11155420,
    },

    // Celo Mainnet
    celo: {
      url: process.env.CELO_RPC_URL || "https://forno.celo.org",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 42220,
    },

    // Celo Testnet (Alfajores)
    celoAlfajores: {
      url: process.env.CELO_TESTNET_RPC_URL || "https://alfajores-forno.celo-testnet.org",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 44787,
    },

    // BSC Testnet
    bscTestnet: {
      url: process.env.BSC_TESTNET_RPC_URL || "https://data-seed-prebsc-1-s1.binance.org:8545",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 97,
    },

    // Zora Mainnet
    zora: {
      url: process.env.ZORA_RPC_URL || "https://rpc.zora.energy",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 7777777,
    },

    // Zora Sepolia Testnet
    zoraSepolia: {
      url: process.env.ZORA_TESTNET_RPC_URL || "https://sepolia.rpc.zora.energy",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      // Zora Sepolia chainId is 999999999 per user's note
      chainId: 999999999,
    },

    // Avalanche Fuji
    fuji: {
      url: process.env.ALCHEMY_API_KEY
        ? `https://avax-fuji.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`
        : process.env.FUJI_RPC_URL || "https://api.avax-test.network/ext/bc/C/rpc",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 43113,
    },

    // Worldchain Mainnet
    worldchain: {
      url: process.env.WORLDCHAIN_RPC_URL || "https://worldchain-mainnet.g.alchemy.com/v2/",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 480,
    },

    // Scroll Sepolia
    scrollSepolia: {
      url: process.env.SCROLL_SEPOLIA_RPC_URL || "https://sepolia-rpc.scroll.io",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 534351,
    },

    // Polygon Mainnet
    polygon: {
      url: process.env.POLYGON_RPC_URL || "https://polygon-rpc.com",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 137,
    },

    // Unichain Sepolia
    unichainSepolia: {
      url: process.env.UNICHAIN_SEPOLIA_RPC_URL || "https://sepolia.unichain.org",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 1301,
    },

    // Optimism Mainnet
    optimism: {
      url: process.env.OPTIMISM_RPC_URL || "https://mainnet.optimism.io",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      // User provided 69; that's older Kovan testnet. Mainnet is 10. We'll use 10.
      chainId: 10,
    },

    // Hedera Mainnet (EVM)
    hederaMainnet: {
      url: process.env.HEDERA_RPC_URL || "https://mainnet.hashio.io/api",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 295,
    },
  },
};

export default config;
