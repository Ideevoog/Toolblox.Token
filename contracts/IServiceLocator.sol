// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IServiceLocator {
    function getService(bytes32 name) external view returns (address);
    function registerService(string calldata name, string calldata spec, address destination, address owner) external;
}