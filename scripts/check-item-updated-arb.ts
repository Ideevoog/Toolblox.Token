#!/usr/bin/env ts-node

import 'dotenv/config';
import { ethers } from 'ethers';

function getArg(flag: string, fallback?: string): string | undefined {
  const i = process.argv.indexOf(flag);
  if (i !== -1 && process.argv[i + 1]) return process.argv[i + 1];
  return fallback;
}

function requireArg(flag: string, name: string): string {
  const v = getArg(flag);
  if (!v) throw new Error(`Missing ${name}. Usage: --address 0x... [--from 192454469] [--to latest] [--id 1]`);
  return v;
}

function getArbRpcUrl(): string {
  const alchemyKey = process.env.ALCHEMY_API_KEY;
  return (
    process.env.ARBITRUM_SEPOLIA_RPC_URL ||
    (alchemyKey ? `https://arb-sepolia.g.alchemy.com/v2/${alchemyKey}` : '')
  );
}

async function main() {
  const tokenAddress = requireArg('--address', 'token --address');
  const fromArg = getArg('--from');
  const toArg = getArg('--to');
  const idArg = getArg('--id');

  const rpc = getArbRpcUrl();
  if (!rpc) throw new Error('Missing ARBITRUM_SEPOLIA_RPC_URL or ALCHEMY_API_KEY');

  const provider = new ethers.providers.JsonRpcProvider(rpc);
  const network = await provider.getNetwork();
  if (Number(network.chainId) !== 421614) {
    console.warn(`⚠️  Connected chainId=${network.chainId} (expected Arbitrum Sepolia 421614)`);
  }

  const iface = new ethers.utils.Interface([
    'event ItemUpdated(uint256 indexed _id, uint64 indexed _status)'
  ]);

  const eventTopic = iface.getEventTopic('ItemUpdated');
  const latest = await provider.getBlockNumber();
  const fromBlock = fromArg ? parseInt(fromArg, 10) : Math.max(0, latest - 5000);
  const toBlock = toArg && toArg !== 'latest' ? parseInt(toArg, 10) : latest;

  const topics: Array<string | null> = [eventTopic];
  if (idArg) {
    const idHex = ethers.utils.hexZeroPad(ethers.utils.hexlify(ethers.BigNumber.from(idArg)), 32);
    topics.push(idHex);
  }

  const logs = await provider.getLogs({
    address: tokenAddress,
    fromBlock,
    toBlock,
    topics
  });

  if (logs.length === 0) {
    console.log(`No ItemUpdated events found for ${tokenAddress} in blocks [${fromBlock}, ${toBlock}]`);
    return;
  }

  console.log(`Found ${logs.length} ItemUpdated event(s):`);
  for (const log of logs) {
    const parsed = iface.parseLog(log);
    const id = parsed.args._id.toString();
    const status = parsed.args._status.toString();
    console.log(`- block=${log.blockNumber} tx=${log.transactionHash} id=${id} status=${status}`);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});


