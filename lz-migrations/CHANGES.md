# LayerZero Wire-Read Enhancement

## 🎯 Summary

Enhanced the wire-read functionality to dynamically handle all adapters from `adapters.csv` instead of being hardcoded to only `arbitrum-sepolia` and `base-sepolia`. Added cost-saving features to check if adapters are already wired before attempting to wire them.

## 🔧 Changes Made

### 1. Dynamic Configuration (`layerzero.config.ts`)
- **Before**: Hardcoded to only `arbitrum-sepolia` and `base-sepolia`
- **After**: Dynamically reads all adapters from `adapters.csv` and filters by environment
- Added environment detection (testnet vs mainnet) based on chain key patterns
- Added command-line argument support (`--testnet`, `--mainnet`) and environment variable (`LZ_ENVIRONMENT`)

### 2. Cost-Saving Check Script (`scripts/check-wired-status.ts`)
- **New**: Checks if adapters are already properly wired before attempting to wire them
- Prevents unnecessary high-cost transactions
- Provides detailed status reporting for each adapter
- Supports environment filtering (testnet/mainnet)
- Returns appropriate exit codes for CI/CD integration

### 3. Enhanced Sync Script (`scripts/sync-deployments.ts`)
- **Before**: Only synced `arbitrum-sepolia` and `base-sepolia`
- **After**: Dynamically syncs all adapters from `adapters.csv`
- Added environment filtering support
- Added proper network directory mapping for all supported chains

### 4. New Package Scripts (`package.json`)
- **Added**: `check-wired`, `check-wired:testnet`, `check-wired:mainnet` - Check wiring status
- **Added**: `wire-read:testnet`, `wire-read:mainnet` - Environment-specific wiring
- **Added**: `fix-all:testnet`, `fix-all:mainnet` - Complete check and fix process
- **Preserved**: All existing scripts for backward compatibility

### 5. Updated Documentation (`README.md`)
- Added comprehensive script documentation with categories
- Added new recommended workflow using check-first approach
- Preserved legacy documentation for backward compatibility

## 🚀 New Recommended Workflow

### Check First, Wire Only If Needed
```bash
# Check which adapters need wiring (free operation)
npm run check-wired:testnet   # or :mainnet

# Wire only if the check shows adapters need it (high-cost operation)
npm run wire-read:testnet     # or :mainnet

# Or use the complete process (checks first, wires only if needed)
npm run fix-all:testnet       # or :mainnet
```

## 🔍 Environment Detection Logic

**Testnet chains** (detected by keywords):
- Contains `sepolia`, `testnet`, `mumbai`, `amoy`, or `fuji`
- Examples: `arbitrum-sepolia`, `base-sepolia`, `polygon-mumbai`, `amoy-testnet`, `fuji`

**Mainnet chains** (everything else):
- Examples: `arbitrum`, `base`, `ethereum`, `polygon`, `optimism`

## 💰 Cost Savings

The new `check-wired-status.ts` script performs read-only operations to check if adapters are already properly configured. This prevents unnecessary wire operations that can be expensive on mainnet.

**Before**: Wire operations would run regardless of current state
**After**: Wire operations only run if adapters actually need configuration

## 🔄 Backward Compatibility

All existing scripts and workflows continue to work:
- `npm run wire-read` - Still works (wires all adapters)
- `npm run verify:arbitrum` / `npm run verify:base` - Still work
- `npm run fix-all` - Still works (legacy version)

## 🎯 Current Adapters in CSV

Based on your `adapters.csv`:
- **Testnet**: `base-sepolia`, `arbitrum-sepolia` 
- **Mainnet**: `arbitrum`, `base`

The system will automatically classify and handle each environment separately.
