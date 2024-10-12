// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @dev Date operations.
 */
library Dates {
    /**
    * @dev Normalizes a timestamp to midnight (00:00:00) of the same date.
    * @param timestamp The original timestamp.
    * @return The normalized timestamp at midnight.
    */
    function getDate(uint256 timestamp) public pure returns (uint256) {
        return (timestamp / 1 days) * 1 days; 
    }
    /**
     * @dev Converts a number of days into seconds.
     * @param numberOfDays The number of days.
     * @return The equivalent number of seconds.
     */
    function daysToSeconds(uint256 numberOfDays) public pure returns (uint256) {
        return numberOfDays * 1 days;
    }
}