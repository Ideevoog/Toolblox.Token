// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title Utils Library
 * @dev Utility functions for token operations
 */
library Utils {
	/**
	 * @notice Gets the number of decimals for a given token
	 * @dev Uses the ERC20 decimals() function selector (0x313ce567)
	 * @dev Falls back to 18 decimals if the call fails or returns invalid data
	 * @param token The address of the token contract
	 * @return uint8 The number of decimals (defaults to 18 if call fails)
	 */
	function getTokenDecimals(address token) internal view returns (uint8) {
		// Make a static call to the token contract to get decimals
		(bool success, bytes memory data) = token.staticcall(
			abi.encodeWithSelector(0x313ce567) // decimals() function selector
		);
		
		// Return decoded decimals if call succeeded and returned exactly 32 bytes
		// Otherwise return 18 as default (most common for ERC20 tokens)
		return (success && data.length == 32) ? abi.decode(data, (uint8)) : 18;
	}
}
