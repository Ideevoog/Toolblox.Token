// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IServiceLocator {
    function getService(bytes32 name) external view returns (address);
    function registerService(string calldata name, bytes calldata code) external returns (address);
}
