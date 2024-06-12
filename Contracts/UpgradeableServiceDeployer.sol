// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

interface IServiceLocator {
    function getService(bytes32 name) external view returns (address);
    function registerService(string calldata name, string calldata spec, address destination, address owner) external;
}

contract UpgradeableServiceDeployer is Ownable, Pausable, ReentrancyGuard {
    IServiceLocator public serviceLocator;
    uint public counter;

    constructor(IServiceLocator _serviceLocator) Ownable(_msgSender()) {
        serviceLocator = _serviceLocator;
    }
    function deployOrUpgrade(
        string calldata name,
        string calldata spec,
        bytes calldata implementationCode
    ) external whenNotPaused nonReentrant returns (address) {
        address sender = _msgSender();
        counter = counter + 1;

        bytes32 nameHash = keccak256(abi.encodePacked(name));
        address existingProxy = serviceLocator.getService(nameHash);

        // Generate unique salts
        bytes32 implementationSalt = keccak256(abi.encodePacked(sender, counter, "implementation"));
        bytes32 proxySalt = keccak256(abi.encodePacked(sender, counter, "proxy"));

        // Calculate addresses
        address implementationAddress = _computeAddress(implementationCode, implementationSalt);
        address proxyAddress = _computeProxyAddress(proxySalt);

        // Register the proxy address with the service locator
        serviceLocator.registerService(name, spec, proxyAddress, sender);

        // Deploy or upgrade proxy
        if (existingProxy == address(0)) {
            // Deploy implementation contract
            _deployContract(implementationCode, implementationSalt);
            _deployNewProxy(proxySalt, implementationAddress, sender);
        } else {
            require(sender == owner(), "Only the owner can upgrade the proxy");
            _upgradeExistingProxy(existingProxy, implementationAddress);
        }

        emit ServiceDeployed(nameHash, proxyAddress);
        return proxyAddress;
    }

    function _deployContract(bytes memory code, bytes32 salt) private returns (address) {
        address addr;
        assembly ("memory-safe") {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
        return addr;
    }

    function _deployNewProxy(bytes32 salt, address implementationAddress, address sender) private returns (address) {
        bytes memory proxyCode = type(TransparentUpgradeableProxy).creationCode;
        bytes memory initData = abi.encodeWithSignature("initialize(address)", sender);
        bytes memory proxyCodeWithInit = abi.encodePacked(proxyCode, abi.encode(implementationAddress, address(this), initData));
        address addr;
        assembly ("memory-safe") {
            addr := create2(0, add(proxyCodeWithInit, 0x20), mload(proxyCodeWithInit), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
        return addr;
    }

    function _upgradeExistingProxy(address proxyAddress, address implementationAddress) private {
        ITransparentUpgradeableProxy(proxyAddress).upgradeToAndCall(implementationAddress, "");
    }

    function _computeAddress(bytes memory code, bytes32 salt) private view returns (address) {
        bytes32 codeHash = keccak256(code);
        bytes32 rawAddress = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, codeHash));
        return address(uint160(uint(rawAddress)));
    }

    function _computeProxyAddress(bytes32 salt) private view returns (address) {
        bytes memory proxyCode = type(TransparentUpgradeableProxy).creationCode;
        bytes32 codeHash = keccak256(proxyCode);
        bytes32 rawAddress = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, codeHash));
        return address(uint160(uint(rawAddress)));
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    event ServiceDeployed(bytes32 indexed nameHash, address proxyAddress);
}