// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./WorkflowBaseCommon.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract WorkflowBaseUpgradeable is Initializable, WorkflowBaseCommon, ContextUpgradeable {
    function initialize() public initializer {
        __Context_init();
    }
}