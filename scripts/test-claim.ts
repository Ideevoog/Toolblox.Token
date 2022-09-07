#!/usr/bin/env ts-node

import 'dotenv/config';
import fs from 'fs';
import path from 'path';
import { ethers } from 'ethers';

type Addresses = {
  baseTix: string;
  arbTix: string;
  baseAdapter: string;
  arbAdapter: string;
};

const EID_BASE_SEPOLIA = 40245;
const EID_ARB_SEPOLIA = 40231;

function getRpcUrl(chain: 'base' | 'arb'): string {
  const alchemyKey = process.env.ALCHEMY_API_KEY;
  if (chain === 'base') {
    return (
      process.env.BASE_SEPOLIA_RPC_URL ||
      (alchemyKey ? `https://base-sepolia.g.alchemy.com/v2/${alchemyKey}` : '')
    );
  }
  return (
    process.env.ARBITRUM_SEPOLIA_RPC_URL ||
    (alchemyKey ? `https://arb-sepolia.g.alchemy.com/v2/${alchemyKey}` : '')
  );
}

function requireEnv(name: string): string {
  const v = process.env[name];
  if (!v) throw new Error(`Missing env ${name}`);
  return v;
}

function readCsvLast(filepath: string, chainKey: string, colIdx: number): string | null {
  if (!fs.existsSync(filepath)) return null;
  const lines = fs.readFileSync(filepath, 'utf8').trim().split(/\r?\n/);
  if (lines.length <= 1) return null;
  for (let i = lines.length - 1; i >= 1; i--) {
    const parts = lines[i].split(',');
    if (parts[0] === chainKey && parts[colIdx] && parts[colIdx].length > 0) {
      return parts[colIdx];
    }
  }
  return null;
}

function resolveAddresses(): Addresses {
  const tixCsv = path.resolve('deployments', 'tix.csv');
  const adaptersCsv = path.resolve('deployments', 'adapters.csv');

  const baseTix =
    readCsvLast(tixCsv, 'base-sepolia', 2) || requireEnv('BASE_TIX');
  const arbTix =
    readCsvLast(tixCsv, 'arbitrum-sepolia', 2) || requireEnv('ARB_TIX');

  const baseAdapter =
    readCsvLast(adaptersCsv, 'base-sepolia', 2) || requireEnv('BASE_ADAPTER');
  const arbAdapter =
    readCsvLast(adaptersCsv, 'arbitrum-sepolia', 2) || requireEnv('ARB_ADAPTER');

  return { baseTix, arbTix, baseAdapter, arbAdapter };
}

function readArtifact(contractPath: string, contractName: string): { abi: any; bytecode: string } {
  const artifactPath = path.resolve(
    'artifacts',
    'contracts',
    contractPath,
    `${contractName}.json`
  );
  if (!fs.existsSync(artifactPath)) {
    throw new Error(`Artifact not found: ${artifactPath}. Run 'npx hardhat compile'.`);
  }
  const json = JSON.parse(fs.readFileSync(artifactPath, 'utf8'));
  return { abi: json.abi, bytecode: json.bytecode };
}

async function main() {
  const pk = requireEnv('PRIVATE_KEY');
  const baseRpc = getRpcUrl('base');
  const arbRpc = getRpcUrl('arb');
  if (!baseRpc || !arbRpc) throw new Error('Missing BASE/ARB RPC URLs');

  const baseProvider = new ethers.providers.JsonRpcProvider(baseRpc);
  const arbProvider = new ethers.providers.JsonRpcProvider(arbRpc);
  const baseWallet = new ethers.Wallet(pk, baseProvider);
  const arbWallet = new ethers.Wallet(pk, arbProvider);

  const { baseTix, arbTix, baseAdapter, arbAdapter } = resolveAddresses();
  console.log('Resolved addresses:', { baseTix, arbTix, baseAdapter, arbAdapter });

  // Minimal ABIs for Tix
  const TIX_ABI = [
    'function registerService(string name,string spec,address destination,address owner) external',
    'function getService(bytes32 name) external view returns (address)'
  ];

  const baseTixContract = new ethers.Contract(baseTix, TIX_ABI, baseWallet);
  const arbTixContract = new ethers.Contract(arbTix, TIX_ABI, arbWallet);

  // Read artifacts for deployments
  const communityArt = readArtifact('test/CommunityWorkflow.sol', 'CommunityWorkflow');
  const tokenArt = readArtifact('test/TokenWorkflow.sol', 'TokenWorkflow');

  // 1) Deploy CommunityWorkflow on Base Sepolia
  console.log('\nDeploying CommunityWorkflow (base-sepolia)...');
  const CommunityFactory = new ethers.ContractFactory(communityArt.abi, communityArt.bytecode, baseWallet);
  const community = await CommunityFactory.deploy();
  await community.deployed();
  console.log('CommunityWorkflow:', community.address);

  // Register community service in TIX (base)
  const communitySvc = 'community_contract';
  await (await baseTixContract.registerService(communitySvc, '', community.address, await baseWallet.getAddress())).wait();
  console.log('Registered community_contract in Base TIX');

  // Create a community id=1 (owner=self)
  const COMMUNITY_ABI = [
    'function registerCommunity(string name,address owner) public returns (uint256)',
    'function getOwner(uint id) public view returns (address)'
  ];
  const communityRW = new ethers.Contract(community.address, COMMUNITY_ABI, baseWallet);
  const regTx = await communityRW.registerCommunity(
    'Test Community',
    await baseWallet.getAddress(),
    { gasLimit: 250000 }
  );
  const regRcpt = await regTx.wait();
  console.log('Community registered, tx:', regRcpt.transactionHash);

  // 2) Deploy TokenWorkflow on Arbitrum Sepolia
  console.log('\nDeploying TokenWorkflow (arbitrum-sepolia)...');
  const TokenFactory = new ethers.ContractFactory(tokenArt.abi, tokenArt.bytecode, arbWallet);
  const token = await TokenFactory.deploy();
  await token.deployed();
  console.log('TokenWorkflow:', token.address);

  // Register token service in TIX (arb)
  const tokenSvc = 'token_contract';
  await (await arbTixContract.registerService(tokenSvc, '', token.address, await arbWallet.getAddress())).wait();
  console.log('Registered token_contract in Arbitrum TIX');

  // Wire cross-chain on TokenWorkflow
  const TOKEN_WRITE_ABI = [
    'function setCrossChainCommunity(address router,uint32 eid,address destTix_) external',
    'function deploy(string name,uint communityId) public returns (uint256)',
    'function claimRewards(uint256 id,uint256 rewardAmount) external payable returns (uint256)'
  ];
  const tokenRW = new ethers.Contract(token.address, TOKEN_WRITE_ABI, arbWallet);
  await (await tokenRW.setCrossChainCommunity(arbAdapter, EID_BASE_SEPOLIA, baseTix)).wait();
  console.log('Cross-chain community configured');

  // Peers are expected to be wired during deployment via scripts/deploy.ts and lz-migrations.

  // 3) Create token (bind to communityId=1)
  const depTx = await tokenRW.deploy('Test Token', 1);
  const depRcpt = await depTx.wait();
  console.log('Token created, tx:', depRcpt.transactionHash);

  // 4) Trigger claim (rewardAmount = 0 for smoke test)
  const fee = ethers.utils.parseEther('0.01');
  const claimTx = await tokenRW.claimRewards(1, ethers.constants.Zero, { value: fee });
  const claimRcpt = await claimTx.wait();
  console.log('\nClaim sent on Arbitrum. Tx:', claimRcpt.transactionHash);
  console.log('Monitor delivery on LayerZero Scan for the GUID in logs.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});


