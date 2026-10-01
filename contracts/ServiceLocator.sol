// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
	A registry of named services, each with an append-only list of versions.

	The first registration of a name makes the registrant its owner, for good. Only the owner adds
	versions, each numbered above the latest, and a registered version's address never changes. So
	the trail only grows: nobody can add a version to someone else's name or re-point an old one,
	and there is no owner, role or pause here that could change those rules.

	`getService(name)` answers with the latest version, so a contract that looks a service up by
	name follows it as versions are added. `getService(name, version)` pins one.

	Who may register on an owner's behalf is decided in one place, `_canRegisterFor`. Here it is
	only the deployer fixed at construction; a registry with its own rules (TixToken's service
	workers and registration fee) can override it and `_beforeFirstRegistration`.
 **/
contract ServiceLocator {
	struct Version {
		address destination;
		string spec;
	}

	struct Service {
		address owner;
		uint64 latest;
		mapping(uint64 => Version) versions;
	}

	mapping(bytes32 => Service) private _services;

	/// The only contract allowed to register or update on an owner's behalf.
	address public immutable deployer;

	event ServiceRegistered(bytes32 indexed nameHash, uint64 indexed version, address indexed owner, address destination, string name, string spec);
	event SpecUpdated(bytes32 indexed nameHash, uint64 indexed version, string spec);

	error EmptyName();
	error ZeroDestination();
	error NotOwner(bytes32 nameHash, address owner, address registrant);
	error VersionNotAboveLatest(bytes32 nameHash, uint64 version, uint64 latest);
	error UnknownVersion(bytes32 nameHash, uint64 version);
	error NotAllowedToRegisterFor(address caller, address owner);

	constructor(address deployer_) {
		deployer = deployer_;
	}

	/// Registers `version` of `name` for the caller. The first registration of a name makes the
	/// caller its owner; after that only the owner can add versions, each above the latest.
	function registerVersion(string calldata name, uint64 version, address destination, string calldata spec) external {
		_register(msg.sender, name, version, destination, spec);
	}

	/// The same, on behalf of `owner`. Only callers `_canRegisterFor` allows may do this.
	function registerVersionFor(address owner, string calldata name, uint64 version, address destination, string calldata spec) external {
		if (!_canRegisterFor(msg.sender, owner)) {
			revert NotAllowedToRegisterFor(msg.sender, owner);
		}
		_register(owner, name, version, destination, spec);
	}

	/// Replaces a registered version's spec, for instance after an in-place upgrade. Its address stays.
	function updateSpec(bytes32 nameHash, uint64 version, string calldata spec) external {
		_updateSpec(msg.sender, nameHash, version, spec);
	}

	function updateSpecFor(address owner, bytes32 nameHash, uint64 version, string calldata spec) external {
		if (!_canRegisterFor(msg.sender, owner)) {
			revert NotAllowedToRegisterFor(msg.sender, owner);
		}
		_updateSpec(owner, nameHash, version, spec);
	}

	/// The latest version's address, or zero when the name is not registered.
	function getService(bytes32 nameHash) external view returns (address) {
		Service storage service = _services[nameHash];
		return service.versions[service.latest].destination;
	}

	/// One version's address, or zero when that version is not registered.
	function getService(bytes32 nameHash, uint64 version) external view returns (address) {
		return _services[nameHash].versions[version].destination;
	}

	function getVersion(bytes32 nameHash, uint64 version) external view returns (address destination, string memory spec) {
		Version storage entry = _services[nameHash].versions[version];
		return (entry.destination, entry.spec);
	}

	function ownerOf(bytes32 nameHash) external view returns (address) {
		return _services[nameHash].owner;
	}

	/// The highest version registered under a name; zero when there is none. Versions below it
	/// may be missing, since an owner can skip numbers.
	function latestVersion(bytes32 nameHash) external view returns (uint64) {
		return _services[nameHash].latest;
	}

	function _register(address registrant, string calldata name, uint64 version, address destination, string calldata spec) private {
		if (bytes(name).length == 0) {
			revert EmptyName();
		}
		if (destination == address(0)) {
			revert ZeroDestination();
		}
		bytes32 nameHash = keccak256(bytes(name));
		Service storage service = _services[nameHash];
		if (service.owner == address(0)) {
			_beforeFirstRegistration(registrant, nameHash);
			service.owner = registrant;
		} else if (service.owner != registrant) {
			revert NotOwner(nameHash, service.owner, registrant);
		}
		// A version number is never reused and never goes back, so an address once registered
		// under it stays the answer for it.
		if (version <= service.latest) {
			revert VersionNotAboveLatest(nameHash, version, service.latest);
		}
		service.latest = version;
		service.versions[version] = Version(destination, spec);
		emit ServiceRegistered(nameHash, version, registrant, destination, name, spec);
	}

	function _updateSpec(address registrant, bytes32 nameHash, uint64 version, string calldata spec) private {
		Service storage service = _services[nameHash];
		if (service.owner != registrant) {
			revert NotOwner(nameHash, service.owner, registrant);
		}
		Version storage entry = service.versions[version];
		if (entry.destination == address(0)) {
			revert UnknownVersion(nameHash, version);
		}
		entry.spec = spec;
		emit SpecUpdated(nameHash, version, spec);
	}

	/// Who may register on an owner's behalf. Only the deployer fixed at construction.
	function _canRegisterFor(address caller, address /*owner*/) internal view virtual returns (bool) {
		return caller == deployer;
	}

	/// Runs once per name, before its first registration. Nothing here; a registry that charges for
	/// names takes its fee in an override.
	function _beforeFirstRegistration(address registrant, bytes32 nameHash) internal virtual {}
}
