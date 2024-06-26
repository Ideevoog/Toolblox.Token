// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract OwnerPausableUpgradeable is Initializable, OwnableUpgradeable, PausableUpgradeable {
    function __OwnerPausable_init() internal onlyInitializing {
        __OwnerPausable_init_unchained();
    }
    function __OwnerPausable_init_unchained() internal onlyInitializing {
    }
    function pause() external onlyOwner {
        _pause();
    }
    function unpause() external onlyOwner {
        _unpause();
    }
}