// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @dev Validation operations.
 */
library Validation {
    function notEmpty(string memory x) internal pure returns (bool) {
        bytes memory b = bytes(x);
        return b.length > 0;
    }

    function notEmpty(uint256 x) internal pure returns (bool) {
        return x != 0;
    }

    function notEmpty(uint128 x) internal pure returns (bool) {
        return x != 0;
    }

    function notEmpty(uint64 x) internal pure returns (bool) {
        return x != 0;
    }

    function notEmpty(uint32 x) internal pure returns (bool) {
        return x != 0;
    }

    function notEmpty(uint16 x) internal pure returns (bool) {
        return x != 0;
    }

    function notEmpty(uint8 x) internal pure returns (bool) {
        return x != 0;
    }

    function notEmpty(address x) internal pure returns (bool) {
        return x != address(0);
    }
    function onlyAlphaNum(string memory x) internal pure returns (bool) {
        return _validateString(x, false);
    }

    function onlyAlphaNumAndSpace(string memory x) internal pure returns (bool) {
        return _validateString(x, true);
    }

    function _validateString(string memory x, bool allowSpace) internal pure returns (bool) {
        bytes memory b = bytes(x);
        bytes1 lastChar;
        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];
            if (allowSpace && char == 0x20 && lastChar == 0x20) return false; // Cannot contain continuous spaces
            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(allowSpace && char == 0x20) //space
            ) return false;
            lastChar = char;
        }
        return true;
    }
    
    function noSpacePadding(string memory x) internal pure returns (bool) {
        bytes memory b = bytes(x);
        if (b.length == 0) return true; // Empty string is valid
        if (b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space
        return true;
    }
}