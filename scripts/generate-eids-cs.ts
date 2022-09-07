import fs from "fs";
import path from "path";
import { networkToChainKey } from "./networkToChainKey";

type DeploymentV1 = { eid: string; version: 1 } & Record<string, unknown>;
type DeploymentV2 = { eid: string; version: 2 } & Record<string, unknown>;

type ChainEntry = {
  deployments?: Array<DeploymentV1 | DeploymentV2>;
  chainKey?: string;
  chainDetails?: {
    nativeChainId?: number;
    chainKey?: string;
  };
};

function preferV2Eid(deployments: Array<DeploymentV1 | DeploymentV2> | undefined): string | undefined {
  if (!deployments || deployments.length === 0) return undefined;
  const v2 = deployments.find((d) => (d as DeploymentV2).version === 2) as DeploymentV2 | undefined;
  if (v2 && v2.eid) return v2.eid;
  const v1 = deployments.find((d) => (d as DeploymentV1).version === 1) as DeploymentV1 | undefined;
  return v1?.eid;
}

function main() {
  const metadataPath = path.join("lz-migrations", "metadata.json");
  const raw = fs.readFileSync(metadataPath, "utf8");
  const metadata: Record<string, ChainEntry> = JSON.parse(raw);

  const result: Array<{ nativeChainId: number; eid: string }> = [];

  for (const [nativeChainIdStr, chainKey] of Object.entries(networkToChainKey)) {
    const entry = Object.values(metadata).find((v) => v && (v.chainKey === chainKey || v.chainDetails?.chainKey === chainKey));
    if (!entry) continue;
    const eid = preferV2Eid(entry.deployments);
    const nativeChainId = Number(nativeChainIdStr);
    if (eid && Number.isFinite(nativeChainId)) {
      result.push({ nativeChainId, eid });
    }
  }

  // Sort by nativeChainId for deterministic output
  result.sort((a, b) => a.nativeChainId - b.nativeChainId);

  // Emit C# Dictionary<int, int>
  const lines: string[] = [];
  lines.push("new Dictionary<int, int> {");
  for (const { nativeChainId, eid } of result) {
    lines.push(`  { ${nativeChainId}, ${parseInt(eid, 10)} },`);
  }
  lines.push("}");

  console.log(lines.join("\n"));
}

if (require.main === module) {
  main();
}

export { main };


