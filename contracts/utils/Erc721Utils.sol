// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Erc721Utils {
	function trySafeTransferFromExternal(address token_, address from, address to, uint256 tokenId) internal returns (bool) {
		// safeTransferFrom(address,address,uint256) selector = 0x42842e0e
		(bool success, ) = token_.call(abi.encodeWithSelector(0x42842e0e, from, to, tokenId));
		return success;
	}

	function safeTransferFromExternal(address token_, address from, address to, uint256 tokenId) internal {
		require(trySafeTransferFromExternal(token_, from, to, tokenId), 'TransferHelper::safeTransferFromERC721 failed');
	}

	function tryTransferFromExternal(address token_, address from, address to, uint256 tokenId) internal returns (bool) {
		// transferFrom(address,address,uint256) selector = 0x23b872dd
		(bool success, ) = token_.call(abi.encodeWithSelector(0x23b872dd, from, to, tokenId));
		return success;
	}

	function safeTransferFromThis(address token_, address to, uint256 tokenId) internal {
		require(trySafeTransferFromExternal(token_, address(this), to, tokenId), 'TransferHelper::safeTransferFromThisERC721 failed');
	}

	function tryBurnExternal(address token_, uint256 tokenId) internal returns (bool) {
		// burn(uint256) selector = 0x42966c68 (OpenZeppelin ERC721Burnable)
		(bool success, ) = token_.call(abi.encodeWithSelector(0x42966c68, tokenId));
		return success;
	}

	function safeBurnExternal(address token_, uint256 tokenId) internal {
		require(tryBurnExternal(token_, tokenId), 'TransferHelper::burnERC721 failed');
	}
}


