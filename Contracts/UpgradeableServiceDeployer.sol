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

interface IReturnProxyAdmin {
    function getProxyAdminAddress() external view returns (address);
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
        address proxyAddress = serviceLocator.getService(nameHash);

        // Generate unique salts
        bytes32 implementationSalt = keccak256(abi.encodePacked(sender, counter, "implementation"));

        // Calculate addresses
        address implementationAddress = _computeAddress(implementationCode, implementationSalt);

        // Deploy implementation contract
        _deployContract(implementationCode, implementationSalt);

        // Deploy or upgrade proxy
        if (proxyAddress == address(0)) {
            bytes32 proxySalt = keccak256(abi.encodePacked(sender, counter, "proxy"));
            proxyAddress = _computeProxyAddress(proxySalt, implementationAddress, sender);
            serviceLocator.registerService(name, spec, proxyAddress, sender);
            _deployNewProxy(proxySalt, implementationAddress, sender);
        } else {
            serviceLocator.registerService(name, spec, proxyAddress, sender);
            _upgradeExistingProxy(proxyAddress, implementationAddress);
        }

        emit ServiceDeployed(nameHash, proxyAddress);
        return proxyAddress;
    }

    function _deployContract(bytes memory code, bytes32 salt) private returns (address createdContract) {
        assembly {
            createdContract := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(createdContract)) { revert(0, 0) }
        }
    }

    function _deployNewProxy(bytes32 salt, address implementationAddress, address sender) private returns (address createdContract) {
        bytes memory proxyCode = type(TransparentUpgradeableProxy).creationCode;
        bytes memory initData = abi.encodeWithSignature("initialize(address)", sender);
        bytes memory proxyCodeWithInit = abi.encodePacked(proxyCode, abi.encode(implementationAddress, address(this), initData));
        assembly {
            createdContract := create2(0, add(proxyCodeWithInit, 0x20), mload(proxyCodeWithInit), salt)
            if iszero(extcodesize(createdContract)) { revert(0, 0) }
        }
    }

    function _upgradeExistingProxy(address proxyAddress, address implementationAddress) private {
        address adminProxyAddress = IReturnProxyAdmin(proxyAddress).getProxyAdminAddress();
        ProxyAdmin(adminProxyAddress).upgradeAndCall(ITransparentUpgradeableProxy(payable(proxyAddress)), implementationAddress, "");
    }

    function _computeAddress(bytes memory code, bytes32 salt) private view returns (address) {
        bytes32 codeHash = keccak256(code);
        bytes32 rawAddress = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, codeHash));
        return address(uint160(uint(rawAddress)));
    }
    function _computeProxyAddress(bytes32 salt, address implementationAddress, address sender) private view returns (address) {
        bytes memory proxyCode = type(TransparentUpgradeableProxy).creationCode;
        bytes memory initData = abi.encodeWithSignature("initialize(address)", sender);
        bytes memory proxyCodeWithInit = abi.encodePacked(proxyCode, abi.encode(implementationAddress, address(this), initData));

        bytes32 codeHash = keccak256(proxyCodeWithInit);
        bytes32 rawAddress = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                codeHash
            )
        );
        return address(uint160(uint(rawAddress)));
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

	event ServiceDeployed(bytes32 _name, address _destination);
}