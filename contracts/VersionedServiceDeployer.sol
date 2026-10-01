// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ServiceLocator.sol";

/**
	Deploys versions of named services behind upgradeable proxies, at addresses anyone can compute.

	A proxy is created with CREATE2. Its salt is the caller, the name and the version, and its
	creation code is the same for every proxy: a TransparentUpgradeableProxy on the fixed
	placeholder, administered by this deployer. The real code is put behind it, and initialised, in
	the same call. So a proxy's address doesn't depend on its code, and a checker computes it from
	four values: this deployer, the name's owner, the name and the version (`computeAddress`).

	Only a name's owner can deploy a version of it or upgrade one, as the locator records it; the
	first deployment of a name makes the caller its owner. There is no owner, role or pause here.

	Next to mainline Toolblox's UpgradeableServiceDeployer, which keeps its own deployments and rules.
 **/
contract VersionedServiceDeployer is ReentrancyGuard {
	ServiceLocator public immutable locator;

	/// The implementation every proxy is created on (ProxyPlaceholder).
	address public immutable placeholder;

	event ServiceDeployed(bytes32 indexed nameHash, uint64 indexed version, address indexed owner, address proxy, address implementation);
	event ServiceUpgraded(bytes32 indexed nameHash, uint64 indexed version, address indexed owner, address proxy, address implementation);

	error NotOwner(bytes32 nameHash, address owner, address caller);
	error UnknownVersion(bytes32 nameHash, uint64 version);
	error DeploymentFailed();

	// Neither value may be derived from address(this) here: on a chain whose genesis holds this
	// contract, the constructor never runs at the address the code ends up at.
	constructor(ServiceLocator locator_, address placeholder_) {
		locator = locator_;
		placeholder = placeholder_;
	}

	/// Deploys `version` of `name` for the caller: `code` is created as the implementation, a new
	/// proxy is created at `computeAddress(caller, name, version)`, registered in the locator, then
	/// upgraded to the implementation and called with `initData`.
	function deploy(string calldata name, uint64 version, bytes calldata code, bytes calldata initData, string calldata spec)
		external
		nonReentrant
		returns (address proxy, address implementation)
	{
		bytes32 nameHash = keccak256(bytes(name));
		address owner = locator.ownerOf(nameHash);
		if (owner != address(0) && owner != msg.sender) {
			revert NotOwner(nameHash, owner, msg.sender);
		}
		implementation = _create(code);
		bytes memory proxyCode = _proxyCreationCode();
		bytes32 salt = _salt(msg.sender, nameHash, version);
		assembly {
			proxy := create2(0, add(proxyCode, 0x20), mload(proxyCode), salt)
		}
		if (proxy == address(0) || proxy.code.length == 0) {
			revert DeploymentFailed();
		}
		// Registered before the proxy runs any code: `initData` is the caller's, and the locator
		// refuses a version at or below the latest, so nothing it does can reuse this slot.
		locator.registerVersionFor(msg.sender, name, version, proxy, spec);
		ProxyAdmin(proxyAdminOf(proxy)).upgradeAndCall(ITransparentUpgradeableProxy(proxy), implementation, initData);
		emit ServiceDeployed(nameHash, version, msg.sender, proxy, implementation);
	}

	/// Upgrades an existing version of `name` in place, behind the same proxy, to `code`, and calls
	/// it with `data` when that is not empty. Only the name's owner. The address stays.
	function upgrade(string calldata name, uint64 version, bytes calldata code, bytes calldata data, string calldata spec)
		external
		nonReentrant
		returns (address implementation)
	{
		bytes32 nameHash = keccak256(bytes(name));
		address owner = locator.ownerOf(nameHash);
		if (owner != msg.sender) {
			revert NotOwner(nameHash, owner, msg.sender);
		}
		address proxy = locator.getService(nameHash, version);
		if (proxy == address(0)) {
			revert UnknownVersion(nameHash, version);
		}
		implementation = _create(code);
		locator.updateSpecFor(msg.sender, nameHash, version, spec);
		ProxyAdmin(proxyAdminOf(proxy)).upgradeAndCall(ITransparentUpgradeableProxy(proxy), implementation, data);
		emit ServiceUpgraded(nameHash, version, msg.sender, proxy, implementation);
	}

	/// Where `owner`'s `version` of the name with this hash lives, or will live once deployed.
	function computeAddress(address owner, bytes32 nameHash, uint64 version) public view returns (address) {
		bytes32 digest = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt(owner, nameHash, version), proxyCreationCodeHash()));
		return address(uint160(uint256(digest)));
	}

	/// The hash of the creation code every proxy of this deployer shares. One constant per deployer,
	/// which checkers pin next to the deployer's address.
	function proxyCreationCodeHash() public view returns (bytes32) {
		return keccak256(_proxyCreationCode());
	}

	/// The ProxyAdmin a TransparentUpgradeableProxy creates for itself: the first contract the proxy
	/// creates, so at the proxy's nonce 1.
	function proxyAdminOf(address proxy) public pure returns (address) {
		return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), proxy, bytes1(0x01))))));
	}

	function _salt(address owner, bytes32 nameHash, uint64 version) private pure returns (bytes32) {
		return keccak256(abi.encode(owner, nameHash, version));
	}

	function _proxyCreationCode() private view returns (bytes memory) {
		return abi.encodePacked(type(TransparentUpgradeableProxy).creationCode, abi.encode(placeholder, address(this), bytes("")));
	}

	function _create(bytes calldata code) private returns (address created) {
		bytes memory copy = code;
		assembly {
			created := create(0, add(copy, 0x20), mload(copy))
		}
		if (created == address(0) || created.code.length == 0) {
			revert DeploymentFailed();
		}
	}
}
