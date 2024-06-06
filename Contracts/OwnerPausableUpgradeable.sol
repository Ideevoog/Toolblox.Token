// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract OwnerPausableUpgradeable is Initializable, OwnableUpgradeable, PausableUpgradeable {
    function __OwnerPausable_init(address owner) internal onlyInitializing {
        __Ownable_init_unchained(owner);
    }
    function __OwnerPausable_init_unchained(address owner) internal onlyInitializing {
        __Ownable_init(owner);
        __Pausable_init();
    }
    function pause() external onlyOwner {
        _pause();
    }
    function unpause() external onlyOwner {
        _unpause();
    }
}