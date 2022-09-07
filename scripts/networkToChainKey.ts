export const networkToChainKey: { [key: number]: string } = {
  // Testnets
  11155111: "sepolia-testnet",      // Ethereum Sepolia
  84532: "base-sepolia",            // Base Sepolia
  8453: "base",                     // Base (mainnet)
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

export type NetworkToChainKey = typeof networkToChainKey;


