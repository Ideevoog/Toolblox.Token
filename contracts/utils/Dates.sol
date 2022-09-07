// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @dev Date operations.
 */
library Dates {
    /**
    * @dev Rounds a timestamp to the start of its day (00:00:00).
    * @param timestamp The original timestamp.
    * @return The timestamp rounded to the start of the day.
    */
    function roundToStartOfDay(uint256 timestamp) internal pure returns (uint256) {
        return (timestamp / 1 days) * 1 days; 
    }
    /**
    * @dev Rounds a timestamp to the start of its hour (HH:00:00).
    * @param timestamp The original timestamp.
    * @return The timestamp rounded to the start of the hour.
    */
    function roundToStartOfHour(uint256 timestamp) internal pure returns (uint256) {
        return (timestamp / 1 hours) * 1 hours;
    }
    /**
     * @dev Converts a number of days into seconds.
     * @param numberOfDays The number of days.
     * @return The equivalent number of seconds.
     */
    function daysToSeconds(uint256 numberOfDays) internal pure returns (uint256) {
        return numberOfDays * 1 days;
    }

    /**
     * @dev Converts a number of hours into seconds.
     * @param numberOfHours The number of hours.
     * @return The equivalent number of seconds.
     */
    function hoursToSeconds(uint256 numberOfHours) internal pure returns (uint256) {
        return numberOfHours * 1 hours;
    }
    /**
     * @dev Converts a number of months into seconds.
     * @param numberOfMonths The number of months.
     * @return The equivalent number of seconds.
     */
    function monthsToSeconds(uint256 numberOfMonths) internal pure returns (uint256) {
        // Note: This is a simplified implementation assuming 30 days per month
        return numberOfMonths * 30 days;
    }
    /**
     * @dev Converts a number of years into seconds.
     * @param numberOfYears The number of years.
     * @return The equivalent number of seconds.
     */
    function yearsToSeconds(uint256 numberOfYears) internal pure returns (uint256) {
        // Note: This is a simplified implementation assuming 365 days per year
        return numberOfYears * 365 days;
    }
    /**
     * @dev Adds a specified number of hours to a timestamp.
     * @param timestamp The original timestamp.
     * @param hoursToAdd The number of hours to add.
     * @return The resulting timestamp after adding the hours.
     */
    function addHours(uint256 timestamp, uint256 hoursToAdd) internal pure returns (uint256) {
        return timestamp + (hoursToAdd * 1 hours);
    }
    /**
     * @dev Adds a specified number of days to a timestamp.
     * @param timestamp The original timestamp.
     * @param daysToAdd The number of days to add.
     * @return The resulting timestamp after adding the days.
     */
    function addDays(uint256 timestamp, uint256 daysToAdd) internal pure returns (uint256) {
        return timestamp + (daysToAdd * 1 days);
    }

    /**
     * @dev Adds a specified number of months to a timestamp.
     * @param timestamp The original timestamp.
     * @param monthsToAdd The number of months to add.
     * @return The resulting timestamp after adding the months.
     */
    function addMonths(uint256 timestamp, uint256 monthsToAdd) internal pure returns (uint256) {
        // Note: This is a simplified implementation and doesn't account for varying month lengths
        return timestamp + (monthsToAdd * 30 days);
    }
    /**
     * @dev Adds a specified number of years to a timestamp.
     * @param timestamp The original timestamp.
     * @param yearsToAdd The number of years to add.
     * @return The resulting timestamp after adding the years.
     */
    function addYears(uint256 timestamp, uint256 yearsToAdd) internal pure returns (uint256) {
        // Note: This is a simplified implementation and doesn't account for leap years
        return timestamp + (yearsToAdd * 365 days);
    }
}
