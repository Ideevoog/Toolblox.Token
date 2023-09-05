// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IServiceLocator {
    function getService(bytes32 name) external view returns (address);
    function registerService(string calldata name, string calldata spec, bytes calldata code) external returns (address);
}