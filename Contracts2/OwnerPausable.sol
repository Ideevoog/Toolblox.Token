// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

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