// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Erc20Utils {
	function trySafeTransferFromExternal(address token_, address from, address to, uint256 value) internal returns (bool) {
		(bool success, bytes memory data) = token_.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
		return success && (data.length == 0 || abi.decode(data, (bool)));
	}

	function trySafeTransferExternal(address token_, address to, uint256 value) internal returns (bool) {
		(bool success, bytes memory data) = token_.call(abi.encodeWithSelector(0xa9059cbb, to, value));
		return success && (data.length == 0 || abi.decode(data, (bool)));
	}

	function safeTransferFromExternal(address token_, address from, address to, uint256 value) internal {
		require(trySafeTransferFromExternal(token_, from, to, value), 'TransferHelper::transferFrom: transferFrom failed');
	}

	function safeTransferExternal(address token_, address to, uint256 value) internal {
		require(trySafeTransferExternal(token_, to, value), 'TransferHelper::safeTransfer: transfer failed');
	}

	function safeApproveExternal(address token_, address spender, uint256 value) internal {
		(bool success, bytes memory data) = token_.call(abi.encodeWithSelector(0x095ea7b3, spender, value));
		require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper::safeApprove: approve failed');
	}
}


