// SPDX-License-Identifier: UNLICENSED
// This smart contract code is proprietary.
// Unauthorized copying, modification, or distribution is strictly prohibited.
// For licensing inquiries or permissions, contact info@toolblox.net.
pragma solidity ^0.8.20;



abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}



abstract contract Ownable is Context {
    address private _owner;

    
    error OwnableUnauthorizedAccount(address account);

    
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



library Math {
    
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, 
        Ceil, 
        Trunc, 
        Expand 
    }

    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            
            
            
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        
        return (a & b) + (a ^ b) / 2;
    }

    
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            
            return a / b;
        }

        
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            
            
            
            uint256 prod0 = x * y; 
            uint256 prod1; 
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            
            if (prod1 == 0) {
                
                
                
                return prod0 / denominator;
            }

            
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            
            
            

            
            uint256 remainder;
            assembly {
                
                remainder := mulmod(x, y, denominator)

                
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            
            

            uint256 twos = denominator & (0 - denominator);
            assembly {
                
                denominator := div(denominator, twos)

                
                prod0 := div(prod0, twos)

                
                twos := add(div(sub(0, twos), twos), 1)
            }

            
            prod0 |= prod1 * twos;

            
            
            
            uint256 inverse = (3 * denominator) ^ 2;

            
            
            inverse *= 2 - denominator * inverse; 
            inverse *= 2 - denominator * inverse; 
            inverse *= 2 - denominator * inverse; 
            inverse *= 2 - denominator * inverse; 
            inverse *= 2 - denominator * inverse; 
            inverse *= 2 - denominator * inverse; 

            
            
            
            
            result = prod0 * inverse;
            return result;
        }
    }

    
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        
        
        
        
        
        
        
        
        
        
        uint256 result = 1 << (log2(a) >> 1);

        
        
        
        
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}



library SignedMath {
    
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    
    function average(int256 a, int256 b) internal pure returns (int256) {
        
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            
            return uint256(n >= 0 ? n : -n);
        }
    }
}



library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    
    error StringsInsufficientHexLength(uint256 value, uint256 length);

    
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                
                assembly {
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
    }

    
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

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
		
		for(uint i = 0; i < itemArray.length; i++) {
			if(itemArray[i] == itemId) {
				indexToBeDeleted = i;
				itemFound = true;
				break;
			}
		}
		
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
contract WorkflowBase is WorkflowBaseCommon  {
}
contract CommunityWorkflow  is Ownable, WorkflowBase{
	struct Community {
		uint id;
		uint64 status;
		string name;
		address owner;
	}
	mapping(uint => Community) public items;
	function _assertOrAssignOwner(Community storage item) private {
		address owner = item.owner;
		if (owner != address(0))
		{
			require(_msgSender() == owner, "Invalid Owner");
			return;
		}
		item.owner = _msgSender();
	}
	constructor() Ownable(_msgSender()) {
	}
	function setOwner(address _newOwner) public {
		transferOwnership(_newOwner);
	}
	function _assertStatus(Community storage item, uint64 status) private view {
		require(item.status == status, "Cannot run Workflow action; unexpected status");
	}
	function getItem(uint256 id) public view returns (Community memory) {
		return getViewFromItem(getItemInternal(id));
	}
	function getItemInternal(uint256 id) private view returns (Community storage) {
		Community storage item = items[id];
		require(item.id == id, "Cannot find item with given id");
		return item;
	}
	function getViewFromItem(Community storage item) private pure returns (Community memory) {
		return item;
	}
	function getLatest(uint256 cnt) public view returns(Community[] memory) {
		uint256[] memory latestIds = getLatestIds(cnt);
		Community[] memory latestItems = new Community[](latestIds.length);
		for (uint256 i = 0; i < latestIds.length; i++) latestItems[i] = getViewFromItem(items[latestIds[i]]);
		return latestItems;
	}
	function getPage(uint256 cursor, uint256 howMany) public view returns(Community[] memory) {
		uint256[] memory ids = getPageIds(cursor, howMany);
		Community[] memory result = new Community[](ids.length);
		for (uint256 i = 0; i < ids.length; i++) result[i] = getViewFromItem(items[ids[i]]);
		return result;
	}
	
	mapping(address => uint) public itemsByOwner;
	function getItemIdByOwner(address owner) public view returns (uint) {
		return itemsByOwner[owner];
	}
	function getItemByOwner(address owner) public view returns (Community memory) {
		return getItem(getItemIdByOwner(owner));
	}
	function _setItemIdByOwner(Community storage item, uint id) private {
		if (item.owner == address(0))
		{
			return;
		}
		uint existingItemByOwner = itemsByOwner[item.owner];
		require(
			existingItemByOwner == 0 || existingItemByOwner == item.id,
			"Cannot set Owner. Another item already exist with same value."
		);
		itemsByOwner[item.owner] = id;
	}
	function getId(uint id) public view returns (uint){
		return getItemInternal(id).id;
	}
	function getStatus(uint id) public view returns (uint64){
		return getItemInternal(id).status;
	}
	function getName(uint id) public view returns (string memory){
		return getItemInternal(id).name;
	}
	function getOwner(uint id) public view returns (address){
		return getItemInternal(id).owner;
	}
	function registerCommunity(string calldata name,address owner) public returns (uint256) {
		uint256 id = _getNextId();
		Community storage item = items[id];
		item.id = id;
		_assertOrAssignOwner(item);
		item.name = name;
		item.owner = owner;
		item.status = 0;
		_setItemIdByOwner(item, id);
		emit ItemUpdated(id, item.status);
		return id;
	}
}