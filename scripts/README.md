# Multi-Chain Deployment Scripts

This directory contains deployment scripts for deploying Toolblox contracts across multiple blockchain networks.

## 🚀 Quick Start

### Prerequisites
- Node.js (supported versions for Hardhat)
- Private keys and RPC URLs configured in your Hardhat config
- `node-fetch` package installed

### Available Scripts

#### 1. Deploy to Testnets Only
```bash
npm run deploy:testnet
# or
npx hardhat run scripts/deploy-testnet.ts
```

#### 2. Deploy to Mainnets Only
```bash
npm run deploy:mainnet
# or
npx hardhat run scripts/deploy-mainnet.ts
```

#### 3. Deploy to All Networks
```bash
npm run deploy:all
# or
npx hardhat run scripts/deploy-all.ts
```

#### 4. Deploy with Custom Network (Advanced)
```bash
DEPLOY_MODE=testnet npx hardhat run scripts/deploy.ts --network ethereum
```

## 📋 What Gets Deployed

### For Chains WITHOUT Existing TIX:
1. **TixToken** (ERC20 with service registry functionality)
2. **ServiceDeployer** (For deploying non-upgradeable contracts)
3. **UpgradeableServiceDeployer** (For deploying upgradeable contracts)
4. **TixReadAdapter** (Cross-chain communication adapter)

### For Chains WITH Existing TIX:
1. **TixReadAdapter** only (uses existing TIX infrastructure)

## ⚙️ Configuration

### TIX Addresses
Configure existing TIX addresses in `scripts/deploy.ts`:

```typescript
const TIX_ADDRESSES: { [key: string]: string } = {
  "scroll-sepolia": "0xABD5F9cFB2C796Bbd1647023ee2BEA74B23bf672",
  "polygon-mainnet": "0x6994199717e1396ad91Bf12B41FbEFcD218e25A7",
  // Add more as needed
};
```

### Target Chains
Modify `TARGET_CHAINS` array in `scripts/deploy.ts` to customize which chains to deploy to.

## 📊 Output

- **Console**: Real-time deployment progress and results
- **JSON File**: `deployment-results-{mode}-{date}.json` with all deployed contract addresses

## 🔧 Customization for Other Projects

### 1. Update Contract Names
Modify the contract deployment section in `deployToChain()`:

```typescript
const YourContract = await ethers.getContractFactory("YourContract");
const contract = await YourContract.deploy(/* constructor args */);
```

### 2. Update TIX Addresses
Replace the `TIX_ADDRESSES` object with your project's addresses.

### 3. Update Chain List
Modify `TARGET_CHAINS` and `ALL_CHAINS` arrays for your target networks.

### 4. Update Dependencies
If your contracts have different constructor parameters, update the deployment logic accordingly.

## 🛠️ Troubleshooting

### Common Issues:
1. **"Unrecognized param" errors**: Use the wrapper scripts (`deploy-testnet.ts`, etc.) instead of direct arguments
2. **Network not found**: Ensure your Hardhat config has the required network configurations
3. **Insufficient funds**: Ensure deployment accounts have sufficient native tokens
4. **Contract verification**: Add verification logic if needed for your project

### Debug Mode:
Set `DEBUG=*` environment variable for detailed logging:
```bash
DEBUG=* npm run deploy:testnet
```

## 📁 File Structure

```
scripts/
├── deploy.ts              # Main deployment logic
├── deploy-testnet.ts      # Testnet wrapper
├── deploy-mainnet.ts      # Mainnet wrapper
├── deploy-all.ts          # All networks wrapper
└── README.md             # This file
```

## 🔒 Security Notes

- Never commit private keys to version control
- Use environment variables for sensitive configuration
- Test deployments on testnets first
- Verify contract addresses after deployment
- Consider using multisig for mainnet deployments
