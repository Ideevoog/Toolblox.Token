// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @dev Date operations.
 */
library Dates {
    uint256 constant SECONDS_PER_DAY = 86400;
    function getDate(uint256 timestamp) public pure returns (uint256) {
        return (timestamp / SECONDS_PER_DAY) * SECONDS_PER_DAY;
    }
}