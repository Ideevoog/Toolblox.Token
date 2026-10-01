// The versioned ServiceLocator and the VersionedServiceDeployer (Stategram V2 plan, item 0.14).
// Run on its own: npx hardhat test test/ServiceLocator.test.js
// It uses only Hardhat's bundled ethers (v5) and Node's assert, so it runs without hardhat-toolbox.
const assert = require("assert");
const { ethers } = require("hardhat");

const ADMIN_SLOT = "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103";
const IMPLEMENTATION_SLOT = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc";

const nameHash = (name) => ethers.utils.keccak256(ethers.utils.toUtf8Bytes(name));
const slotAddress = (word) => ethers.utils.getAddress("0x" + word.slice(26));

// Hardhat names most custom errors in the message; one raised after a failed CREATE2 it can only
// show as raw return data, so the selector counts as well.
const ERROR_SIGNATURES = {
	DeploymentFailed: "DeploymentFailed()",
	NotOwner: "NotOwner(bytes32,address,address)",
	UnknownVersion: "UnknownVersion(bytes32,uint64)",
	VersionNotAboveLatest: "VersionNotAboveLatest(bytes32,uint64,uint64)"
};

async function expectRevert(promise, reason) {
	try {
		await promise;
	} catch (e) {
		const text = `${e.message} ${e.errorName || ""}`;
		const selector = ERROR_SIGNATURES[reason] ? ethers.utils.id(ERROR_SIGNATURES[reason]).slice(0, 10) : null;
		assert.ok(text.includes(reason) || (selector && text.includes(selector)), `expected a revert with ${reason}, got: ${e.message}`);
		return;
	}
	assert.fail(`expected a revert with ${reason}, but the call succeeded`);
}

async function deployRegistry() {
	const [signer] = await ethers.getSigners();
	const nonce = await signer.getTransactionCount();
	// The locator needs the deployer's address and the deployer the locator's, so the deployer's
	// address is worked out from the nonce it will be created at.
	const deployerAddress = ethers.utils.getContractAddress({ from: signer.address, nonce: nonce + 2 });
	const placeholder = await (await ethers.getContractFactory("ProxyPlaceholder")).deploy();
	await placeholder.deployed();
	const locator = await (await ethers.getContractFactory("ServiceLocator")).deploy(deployerAddress);
	await locator.deployed();
	const deployer = await (await ethers.getContractFactory("VersionedServiceDeployer")).deploy(locator.address, placeholder.address);
	await deployer.deployed();
	assert.strictEqual(deployer.address, deployerAddress);
	return { locator, deployer, placeholder };
}

async function mockCode(version) {
	const factory = await ethers.getContractFactory(version === 1 ? "VersionedServiceMockV1" : "VersionedServiceMockV2");
	return factory.bytecode;
}

function initData(owner) {
	return new ethers.utils.Interface(["function initialize(address)"]).encodeFunctionData("initialize", [owner]);
}

describe("ServiceLocator", function () {
	let locator, alice, bob, eve;

	beforeEach(async function () {
		[, alice, bob, eve] = await ethers.getSigners();
		({ locator } = await deployRegistry());
	});

	it("makes the first registrant the owner and follows the latest version", async function () {
		const name = "settlement_plan-4f1c";
		await locator.connect(alice).registerVersion(name, 1, bob.address, "spec-1");
		assert.strictEqual(await locator.ownerOf(nameHash(name)), alice.address);
		assert.strictEqual(await locator["getService(bytes32)"](nameHash(name)), bob.address);

		await locator.connect(alice).registerVersion(name, 3, eve.address, "spec-3");
		assert.strictEqual((await locator.latestVersion(nameHash(name))).toNumber(), 3);
		assert.strictEqual(await locator["getService(bytes32)"](nameHash(name)), eve.address);
		assert.strictEqual(await locator["getService(bytes32,uint64)"](nameHash(name), 1), bob.address);
		assert.strictEqual(await locator["getService(bytes32,uint64)"](nameHash(name), 2), ethers.constants.AddressZero);
		const [destination, spec] = await locator.getVersion(nameHash(name), 3);
		assert.strictEqual(destination, eve.address);
		assert.strictEqual(spec, "spec-3");
	});

	it("answers zero for a name nobody registered", async function () {
		assert.strictEqual(await locator["getService(bytes32)"](nameHash("nobody")), ethers.constants.AddressZero);
		assert.strictEqual(await locator.ownerOf(nameHash("nobody")), ethers.constants.AddressZero);
		assert.strictEqual((await locator.latestVersion(nameHash("nobody"))).toNumber(), 0);
	});

	it("lets only the owner add versions", async function () {
		await locator.connect(alice).registerVersion("claims-1", 1, bob.address, "");
		await expectRevert(locator.connect(eve).registerVersion("claims-1", 2, eve.address, ""), "NotOwner");
	});

	it("refuses a version at or below the latest, so a registered address never changes", async function () {
		await locator.connect(alice).registerVersion("claims-1", 2, bob.address, "");
		await expectRevert(locator.connect(alice).registerVersion("claims-1", 2, eve.address, ""), "VersionNotAboveLatest");
		await expectRevert(locator.connect(alice).registerVersion("claims-1", 1, eve.address, ""), "VersionNotAboveLatest");
		assert.strictEqual(await locator["getService(bytes32,uint64)"](nameHash("claims-1"), 2), bob.address);
	});

	it("refuses version zero, an empty name and a zero destination", async function () {
		await expectRevert(locator.connect(alice).registerVersion("claims-1", 0, bob.address, ""), "VersionNotAboveLatest");
		await expectRevert(locator.connect(alice).registerVersion("", 1, bob.address, ""), "EmptyName");
		await expectRevert(locator.connect(alice).registerVersion("claims-1", 1, ethers.constants.AddressZero, ""), "ZeroDestination");
	});

	it("lets only the deployer register or update on someone's behalf", async function () {
		await expectRevert(locator.connect(eve).registerVersionFor(alice.address, "claims-1", 1, bob.address, ""), "NotAllowedToRegisterFor");
		await locator.connect(alice).registerVersion("claims-1", 1, bob.address, "a");
		await expectRevert(locator.connect(eve).updateSpecFor(alice.address, nameHash("claims-1"), 1, "b"), "NotAllowedToRegisterFor");
	});

	it("lets only the owner update a registered version's spec, and never its address", async function () {
		await locator.connect(alice).registerVersion("claims-1", 1, bob.address, "a");
		await expectRevert(locator.connect(eve).updateSpec(nameHash("claims-1"), 1, "b"), "NotOwner");
		await expectRevert(locator.connect(alice).updateSpec(nameHash("claims-1"), 2, "b"), "UnknownVersion");
		await locator.connect(alice).updateSpec(nameHash("claims-1"), 1, "b");
		const [destination, spec] = await locator.getVersion(nameHash("claims-1"), 1);
		assert.strictEqual(destination, bob.address);
		assert.strictEqual(spec, "b");
	});
});

describe("VersionedServiceDeployer", function () {
	let locator, deployer, placeholder, alice, eve;
	const name = "settlement_plan-0b6f2c1e-8a47-4f7e-9d51-3c2a1f0e9b77";

	beforeEach(async function () {
		[, alice, , eve] = await ethers.getSigners();
		({ locator, deployer, placeholder } = await deployRegistry());
	});

	it("shares one proxy creation code, whose hash anyone can recompute", async function () {
		const proxy = await ethers.getContractFactory("TransparentUpgradeableProxy");
		const creationCode = ethers.utils.hexConcat([
			proxy.bytecode,
			ethers.utils.defaultAbiCoder.encode(["address", "address", "bytes"], [placeholder.address, deployer.address, "0x"])
		]);
		assert.strictEqual(await deployer.proxyCreationCodeHash(), ethers.utils.keccak256(creationCode));
	});

	it("deploys at the computed address, registers it, and initialises the real code", async function () {
		const expected = await deployer.computeAddress(alice.address, nameHash(name), 1);
		await (await deployer.connect(alice).deploy(name, 1, await mockCode(1), initData(alice.address), "s1")).wait();

		assert.strictEqual(await locator["getService(bytes32)"](nameHash(name)), expected);
		assert.strictEqual(await locator.ownerOf(nameHash(name)), alice.address);
		const service = await ethers.getContractAt("VersionedServiceMockV1", expected);
		assert.strictEqual(await service.owner(), alice.address);
		assert.strictEqual((await service.implementationVersion()).toNumber(), 1);

		// The proxy's admin is the ProxyAdmin the deployer computes, and the deployer owns it.
		const admin = slotAddress(await ethers.provider.getStorageAt(expected, ADMIN_SLOT));
		assert.strictEqual(admin, await deployer.proxyAdminOf(expected));
		const proxyAdmin = await ethers.getContractAt("ProxyAdmin", admin);
		assert.strictEqual(await proxyAdmin.owner(), deployer.address);
	});

	it("keeps the address and the state across an upgrade", async function () {
		await (await deployer.connect(alice).deploy(name, 1, await mockCode(1), initData(alice.address), "s1")).wait();
		const address = await deployer.computeAddress(alice.address, nameHash(name), 1);
		const service = await ethers.getContractAt("VersionedServiceMockV2", address);
		await (await service.setValue(42)).wait();
		const before = slotAddress(await ethers.provider.getStorageAt(address, IMPLEMENTATION_SLOT));

		await (await deployer.connect(alice).upgrade(name, 1, await mockCode(2), "0x", "s1b")).wait();

		assert.strictEqual(await locator["getService(bytes32,uint64)"](nameHash(name), 1), address);
		assert.notStrictEqual(slotAddress(await ethers.provider.getStorageAt(address, IMPLEMENTATION_SLOT)), before);
		assert.strictEqual((await service.implementationVersion()).toNumber(), 2);
		assert.strictEqual((await service.value()).toNumber(), 42);
		assert.strictEqual(await service.owner(), alice.address);
		assert.strictEqual((await locator.getVersion(nameHash(name), 1))[1], "s1b");
	});

	it("lets only the owner deploy a new version or upgrade one", async function () {
		await (await deployer.connect(alice).deploy(name, 1, await mockCode(1), initData(alice.address), "")).wait();
		await expectRevert(deployer.connect(eve).deploy(name, 2, await mockCode(1), initData(eve.address), ""), "NotOwner");
		await expectRevert(deployer.connect(eve).upgrade(name, 1, await mockCode(2), "0x", ""), "NotOwner");
		await expectRevert(deployer.connect(alice).upgrade(name, 2, await mockCode(2), "0x", ""), "UnknownVersion");
	});

	it("refuses a version at or below the latest", async function () {
		await (await deployer.connect(alice).deploy(name, 2, await mockCode(1), initData(alice.address), "")).wait();
		await expectRevert(deployer.connect(alice).deploy(name, 1, await mockCode(1), initData(alice.address), ""), "VersionNotAboveLatest");
		// Version 2 already has a proxy at its address, so its creation fails before the locator is asked.
		await expectRevert(deployer.connect(alice).deploy(name, 2, await mockCode(1), initData(alice.address), ""), "DeploymentFailed");
	});

	it("gives a new version its own proxy and moves the latest to it", async function () {
		await (await deployer.connect(alice).deploy(name, 1, await mockCode(1), initData(alice.address), "")).wait();
		await (await deployer.connect(alice).deploy(name, 2, await mockCode(2), initData(alice.address), "")).wait();
		const first = await deployer.computeAddress(alice.address, nameHash(name), 1);
		const second = await deployer.computeAddress(alice.address, nameHash(name), 2);
		assert.notStrictEqual(first, second);
		assert.strictEqual(await locator["getService(bytes32)"](nameHash(name)), second);
		assert.strictEqual(await locator["getService(bytes32,uint64)"](nameHash(name), 1), first);
	});

	it("puts another caller's deployment of another name at another address", async function () {
		const other = "settlement_plan-7d3e";
		await (await deployer.connect(alice).deploy(name, 1, await mockCode(1), initData(alice.address), "")).wait();
		await (await deployer.connect(eve).deploy(other, 1, await mockCode(1), initData(eve.address), "")).wait();
		assert.notStrictEqual(await locator["getService(bytes32)"](nameHash(name)), await locator["getService(bytes32)"](nameHash(other)));
		assert.strictEqual(await locator["getService(bytes32)"](nameHash(other)), await deployer.computeAddress(eve.address, nameHash(other), 1));
		assert.notStrictEqual(await deployer.computeAddress(eve.address, nameHash(name), 1), await deployer.computeAddress(alice.address, nameHash(name), 1));
	});

	it("does not let a name registered directly in the locator be deployed under by anyone else", async function () {
		await locator.connect(alice).registerVersion(name, 1, alice.address, "");
		await expectRevert(deployer.connect(eve).deploy(name, 2, await mockCode(1), initData(eve.address), ""), "NotOwner");
	});
});
