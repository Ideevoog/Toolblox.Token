// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// Two implementations with the same storage layout, for the VersionedServiceDeployer tests.
contract VersionedServiceMockV1 {
	address public owner;
	uint256 public value;
	bool private _initialized;

	function initialize(address owner_) external {
		require(!_initialized, "already initialised");
		_initialized = true;
		owner = owner_;
	}

	function setValue(uint256 value_) external {
		value = value_;
	}

	function implementationVersion() external pure virtual returns (uint256) {
		return 1;
	}
}

contract VersionedServiceMockV2 is VersionedServiceMockV1 {
	function implementationVersion() external pure override returns (uint256) {
		return 2;
	}
}
