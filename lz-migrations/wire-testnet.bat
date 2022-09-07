@echo off
set LZ_ENVIRONMENT=testnet
npx hardhat lz:oapp-read:wire --oapp-config layerzero.config.ts
