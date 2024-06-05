// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract OwnerPausable is Ownable, Pausable {
	constructor(address owner) Ownable(owner) {
	}
    function pause() external onlyOwner {
        Pausable._pause();
    }
    function unpause() external onlyOwner {
        Pausable._unpause();
    }
}

contract OwnerPausableUpgradeable is Initializable, OwnableUpgradeable, PausableUpgradeable {
    function initialize(address owner) public initializer {
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