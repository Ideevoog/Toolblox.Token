# LayerZero Read Migrations

This subfolder contains isolated LayerZero configuration tools to fix ReadLib1002 setup without ethers version conflicts.

## 🚀 Quick Start

```bash
# Navigate to migrations folder
cd lz-migrations

# Install dependencies (isolated from main project)
npm install

# Check which adapters need wiring (recommended approach)
npm run check-wired:testnet   # Check testnet adapters
npm run check-wired:mainnet   # Check mainnet adapters

# Wire only the adapters that need it
npm run wire-read:testnet     # Wire testnet adapters (if any need it)
npm run wire-read:mainnet     # Wire mainnet adapters (if any need it)

# Or use the complete fix process (checks first, then wires if needed)
npm run fix-all:testnet       # Complete testnet fix
npm run fix-all:mainnet       # Complete mainnet fix
```

### 🔄 Legacy Quick Start (for backward compatibility)
```bash
# Old approach - wires arbitrum-sepolia and base-sepolia only
npm run verify:arbitrum
npm run verify:base
npm run wire-read
npm run verify:arbitrum
npm run verify:base
```

## 📋 Available Scripts

### 🔍 Check Status
- `npm run check-wired` - Check if all adapters are properly wired (from adapters.csv)
- `npm run check-wired:testnet` - Check only testnet adapters
- `npm run check-wired:mainnet` - Check only mainnet adapters

### 🔧 Wire Configuration
- `npm run wire-read` - Configure ReadLib1002 for all adapters (legacy - not recommended)
- `npm run wire-read:testnet` - Configure ReadLib1002 for testnet adapters only
- `npm run wire-read:mainnet` - Configure ReadLib1002 for mainnet adapters only

### 🚀 Complete Fix Process
- `npm run fix-all:testnet` - Check status and wire testnet adapters if needed
- `npm run fix-all:mainnet` - Check status and wire mainnet adapters if needed

### 🔍 Legacy/Individual Chain Scripts
- `npm run verify` - Verify configuration on default network
- `npm run verify:arbitrum` - Check Arbitrum Sepolia adapter
- `npm run verify:base` - Check Base Sepolia adapter
- `npm run wire:arbitrum` - Configure only Arbitrum Sepolia
- `npm run wire:base` - Configure only Base Sepolia
- `npm run fix-all` - Complete verification and fix process (legacy)

### 🌐 Utilities
- `npm run fetch-addresses` - Fetch latest LayerZero addresses

## 🔧 What This Fixes

Your adapters are currently NOT using ReadLib1002 for channel 1, which breaks lzRead operations.

**Current Problem:**
- Channel 1 is using default message library instead of ReadLib1002
- DVNs are not configured for archival node access
- Executors are not properly configured for read responses

**After Fix:**
- Channel 1 will use proper ReadLib1002 addresses
- DVNs will support cross-chain read operations
- Executors will handle read responses correctly

## 🎯 Target Flow

Once fixed, your cross-chain flow will work:

1. **TokenWorkflow (Arbitrum Sepolia)** calls `claimRewards(id, amount)`
2. **lzRead** queries `CommunityWorkflow.getOwner(communityId)` on Base Sepolia
3. **Callback** receives owner address and processes payment
4. **Context preserved** throughout the entire operation

## 📁 Files

- `package.json` - Isolated dependencies with ethers v6
- `hardhat.config.ts` - Hardhat config pointing to parent contracts
- `layerzero.config.ts` - LayerZero Read configuration
- `scripts/verify-lz-config.ts` - Verification script
- `scripts/fetch-lz-addresses.ts` - Address fetching utility

## ⚠️ Requirements

- Owner permissions on both adapter contracts
- Gas fees on both Arbitrum Sepolia and Base Sepolia
- Private key with sufficient ETH on both chains

