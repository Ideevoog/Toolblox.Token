// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/utils/Strings.sol";
contract WorkflowBaseCommon {
	uint256 public count = 0;
	IExternalServiceLocator internal serviceLocator;
	event ItemUpdated(uint256 indexed _id, uint64 indexed _status);
	function _getNextId() internal returns (uint256) {
		count++;
		return count;
	}
	function getLatestIds(uint256 cnt) public view returns(uint256[] memory) {
		uint256 toIndex = count;
		uint256 fromIndex = 0;
		if (cnt < toIndex) {
			fromIndex = toIndex - cnt;
		}
		if (fromIndex > toIndex || toIndex == 0) {
			return new uint256[](0);
		}
		uint256[] memory latestIds = new uint256[](toIndex - fromIndex);
		uint256 setterCount = 0;
		for(uint256 i=fromIndex; i < toIndex; i++) {
			latestIds[setterCount] = i + 1;
			setterCount++;
		}
		return latestIds; 
	}
	function getPageIds(uint256 cursor, uint256 howMany) public view returns(uint256[] memory) {
		uint256[] memory idsToReturn = new uint256[](howMany);
		uint256 len = 0;
		while (cursor <= count && len < howMany) {
			idsToReturn[len] = cursor;
			len++;
			cursor++;
		}
		return idsToReturn;
	}	
	function addFkMappingItem(mapping(uint => uint[]) storage itemMap, uint foreignKey, uint itemId) internal {
		itemMap[foreignKey].push(itemId);
	}
	function removeFkMappingItem(mapping(uint => uint[]) storage itemMap, uint foreignKey, uint itemId) internal {
		uint[] storage itemArray = itemMap[foreignKey];
		uint indexToBeDeleted;
		bool itemFound = false;
		// Find the index of the item to be deleted
		for(uint i = 0; i < itemArray.length; i++) {
			if(itemArray[i] == itemId) {
				indexToBeDeleted = i;
				itemFound = true;
				break;
			}
		}
		// If the item is found, remove it from the list
		if(itemFound) {
			itemArray[indexToBeDeleted] = itemArray[itemArray.length - 1];
			itemArray.pop();
		}
	}
	function toString(uint256 value) internal pure returns (string memory) {
		return Strings.toString(value);
	}	
	function trySafeTransferFromExternal(address token_, address from, address to, uint value) internal returns (bool) {
		(bool success, bytes memory data) = token_.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
		return success && (data.length == 0 || abi.decode(data, (bool)));
	}
	function trySafeTransferExternal(address token_, address to, uint256 value) internal returns (bool) {
		(bool success, bytes memory data) = token_.call(abi.encodeWithSelector(0xa9059cbb, to, value));
		return success && (data.length == 0 || abi.decode(data, (bool)));
	}
	function safeTransferFromExternal(address token_, address from, address to, uint value) internal {
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
interface IExternalServiceLocator {
	function getService(bytes32 name) external view returns (address);
}