import { ChannelId } from '@layerzerolabs/lz-definitions';
import { ExecutorOptionType } from '@layerzerolabs/lz-v2-utilities';
import { type OAppReadOmniGraphHardhat, type OmniPointHardhat } from '@layerzerolabs/toolbox-hardhat';
import * as fs from 'fs';
import * as path from 'path';

type CsvRow = { chain: string; eid: string; adapter: string };

function readAdaptersCsv(): CsvRow[] {
  try {
    const csvPath = path.resolve(__dirname, '..', 'deployments', 'adapters.csv');
    if (!fs.existsSync(csvPath)) return [];
    const lines = fs.readFileSync(csvPath, 'utf8').trim().split(/\r?\n/);
    const rows: CsvRow[] = [];
    for (let i = 1; i < lines.length; i++) {
      const [chain, eid, adapter] = lines[i].split(',');
      if (chain && adapter) rows.push({ chain, eid, adapter });
    }
    return rows;
  } catch {
    return [];
  }
}

function getAdapter(chainKey: string): { address: string; eid: number } | null {
  const rows = readAdaptersCsv();
  // Use last occurrence for the chain
  for (let i = rows.length - 1; i >= 0; i--) {
    if (rows[i].chain === chainKey && rows[i].adapter) {
      const eid = Number(rows[i].eid);
      return { address: rows[i].adapter, eid: Number.isNaN(eid) ? 0 : eid };
    }
  }
  return null;
}

type Metadata = any;
function readMetadata(): Metadata {
  try {
    const p = path.resolve(__dirname, 'metadata.json');
    if (!fs.existsSync(p)) throw new Error('metadata.json not found. Run npm run fetch-addresses');
    return JSON.parse(fs.readFileSync(p, 'utf8'));
  } catch {
    throw new Error('Failed to read metadata.json');
  }
}

function resolveReadParams(chainKey: string) {
  const meta = readMetadata();
  const values = Object.values(meta) as any[];
  const chain = values.find((v) => v?.chainKey === chainKey || v?.chainDetails?.chainKey === chainKey);
  if (!chain) throw new Error(`Chain ${chainKey} not found in metadata.json`);
  const dep = Array.isArray(chain?.deployments) ? chain.deployments.find((d: any) => d.version === 2 && d.chainKey === chainKey) : null;
  const readLibrary = dep?.readLib1002?.address;
  const executor = dep?.executor?.address;
  // Choose a DVN that is lzReadCompatible; prefer layerzero-labs
  let requiredDVN: string | undefined;
  if (chain?.dvns) {
    for (const [addr, info] of Object.entries<any>(chain.dvns)) {
      const id = (info as any)?.id;
      const lzReadOk = (info as any)?.lzReadCompatible || false;
      if (id === 'layerzero-labs' && lzReadOk) { requiredDVN = addr; break; }
    }
    if (!requiredDVN) {
      for (const [addr, info] of Object.entries<any>(chain.dvns)) {
        const lzReadOk = (info as any)?.lzReadCompatible || false;
        if (lzReadOk) { requiredDVN = addr; break; }
      }
    }
  }
  if (!readLibrary || !executor || !requiredDVN) {
    throw new Error(`Missing read params in metadata for ${chainKey}`);
  }
  return { readLibrary, executor, requiredDVNs: [requiredDVN] };
}

function makeContract(chainKey: string): { contract: OmniPointHardhat; config: any } {
  const adapter = getAdapter(chainKey);
  if (!adapter) throw new Error(`Adapter for ${chainKey} not found in adapters.csv`);
  if (!adapter.eid) throw new Error(`Missing EID in adapters.csv for ${chainKey}`);
  const read = resolveReadParams(chainKey);
  return {
    contract: {
      eid: (adapter.eid as unknown) as any, // numeric EID sourced from CSV/metadata
      contractName: 'TixReadAdapter',
      address: adapter.address
    },
    config: {
      readChannelConfigs: [
        {
          channelId: ChannelId.READ_CHANNEL_1,
          active: true,
          readLibrary: read.readLibrary,
          ulnConfig: {
            requiredDVNs: read.requiredDVNs,
            executor: read.executor
          },
          enforcedOptions: [
            {
              msgType: 1,
              optionType: ExecutorOptionType.LZ_READ,
              gas: 200000,
              size: 512,
              value: 0
            }
          ]
        }
      ]
    }
  };
}

function getEnvironmentForChainKey(chainKey: string): 'mainnet' | 'testnet' {
  const ck = chainKey.toLowerCase();
  if (
    ck.includes('sepolia') ||
    ck.includes('testnet') ||
    ck.includes('mumbai') ||
    ck.includes('amoy') ||
    ck.includes('fuji')
  ) {
    return 'testnet';
  }
  return 'mainnet';
}

function getContractsForEnvironment(environment?: 'testnet' | 'mainnet' | 'all'): { contract: OmniPointHardhat; config: any }[] {
  const rows = readAdaptersCsv();
  const contracts: { contract: OmniPointHardhat; config: any }[] = [];
  
  for (const row of rows) {
    if (!row.chain || !row.adapter) continue;
    
    const chainEnvironment = getEnvironmentForChainKey(row.chain);
    
    // Filter by environment if specified
    if (environment && environment !== 'all' && chainEnvironment !== environment) {
      continue;
    }
    
    try {
      contracts.push(makeContract(row.chain));
      console.log(`✅ Added ${row.chain} (${chainEnvironment}) to wire-read config`);
    } catch (error) {
      console.warn(`⚠️  Skipping ${row.chain}: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }
  
  return contracts;
}

// Get environment from environment variable or process arguments
const targetEnv = process.env.LZ_ENVIRONMENT as 'testnet' | 'mainnet' | undefined ||
                 (process.argv.includes('--testnet') ? 'testnet' : 
                  process.argv.includes('--mainnet') ? 'mainnet' : undefined);

const config: OAppReadOmniGraphHardhat = {
  contracts: getContractsForEnvironment(targetEnv),
  connections: []
};

export default config;

