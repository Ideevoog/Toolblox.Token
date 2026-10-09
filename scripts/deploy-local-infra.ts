#!/usr/bin/env node
/**
 * Deploy the Toolblox infrastructure to a local Anvil chain and wire it up so
 * Toolblox can deploy workflows through the ServiceDeployer factory.
 *
 *   1. TixToken(initialSupply = 1e25)        -> the service locator + TIX token
 *   2. ServiceDeployer(tix)                   -> the v2 factory
 *   3. UpgradeableServiceDeployer(tix)        -> the upgradeable factory
 *   4. grantRole(SERVICE_WORKER, ServiceDeployer)
 *   5. grantRole(SERVICE_WORKER, UpgradeableServiceDeployer)
 *
 * Reports Tix / Deployer / UpgradeableDeployer for NetworkService.cs.
 *
 * Prereq: Anvil running on http://127.0.0.1:8545.
 * Usage:  npx hardhat run scripts/deploy-local-infra.ts --network localhost
 */
import { ethers } from "hardhat";

const INITIAL_SUPPLY = "10000000000000000000000000"; // 1e25 (10,000,000 TIX * 1e18)

async function main() {
  const [deployer] = await ethers.getSigners();
  const net = await ethers.provider.getNetwork();
  const deployerAddress = await deployer.getAddress();
  console.log(`Deploying Toolblox infra to chainId ${net.chainId} as ${deployerAddress}`);

  const Tix = await ethers.getContractFactory("TixToken");
  const tix = await Tix.deploy(ethers.BigNumber.from(INITIAL_SUPPLY));
  await tix.deployed();
  console.log(`  TixToken                   ${tix.address}`);

  const ServiceDeployer = await ethers.getContractFactory("ServiceDeployer");
  const serviceDeployer = await ServiceDeployer.deploy(tix.address);
  await serviceDeployer.deployed();
  console.log(`  ServiceDeployer            ${serviceDeployer.address}`);

  const UpgradeableServiceDeployer = await ethers.getContractFactory("UpgradeableServiceDeployer");
  const upgradeableDeployer = await UpgradeableServiceDeployer.deploy(tix.address);
  await upgradeableDeployer.deployed();
  console.log(`  UpgradeableServiceDeployer  ${upgradeableDeployer.address}`);

  const SERVICE_WORKER: string = await tix.SERVICE_WORKER();
  console.log(`  SERVICE_WORKER = ${SERVICE_WORKER}`);

  let tx = await tix.grantRole(SERVICE_WORKER, serviceDeployer.address);
  await tx.wait();
  console.log(`  grantRole(SERVICE_WORKER, ServiceDeployer)`);

  tx = await tix.grantRole(SERVICE_WORKER, upgradeableDeployer.address);
  await tx.wait();
  console.log(`  grantRole(SERVICE_WORKER, UpgradeableServiceDeployer)`);

  console.log("\n=== NetworkService.cs values (LocalTestnet, Version = 2) ===");
  console.log(`Tix                 = "${tix.address}",`);
  console.log(`Deployer            = "${serviceDeployer.address}",`);
  console.log(`UpgradeableDeployer = "${upgradeableDeployer.address}",`);
  console.log(`\nSETUP_JSON:${JSON.stringify({
    tix: tix.address,
    deployer: serviceDeployer.address,
    upgradeableDeployer: upgradeableDeployer.address,
    serviceWorker: SERVICE_WORKER,
    chainId: Number(net.chainId),
  })}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
