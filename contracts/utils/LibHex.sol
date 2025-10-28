// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library LibHex {
    bytes16 private constant _HEX = 0x30313233343536373839616263646566;

    function toHexAddress(address a) internal pure returns (string memory) {
        return toHex(uint256(uint160(a)), 20);
    }

    function toHex(uint256 value, uint256 byteLen) internal pure returns (string memory str) {
        uint256 len = 2 * byteLen;
        str = new string(len + 2);
        bytes memory b = bytes(str);
        b[0] = "0";
        b[1] = "x";
        for (uint256 i; i < len; ) {
            uint8 nibble = uint8(value >> ((len - 1 - i) * 4)) & 0xf;
            b[i + 2] = bytes1(_HEX[nibble]);
            unchecked { i++; }
        }
    }
}