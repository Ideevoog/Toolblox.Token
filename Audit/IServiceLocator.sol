// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IServiceLocator {
    function getService(bytes32 name) external view returns (address);
    function getScheduler(address service) external view returns (address);
    function registerService(bytes32 name, bytes memory code) external returns (address);
}
