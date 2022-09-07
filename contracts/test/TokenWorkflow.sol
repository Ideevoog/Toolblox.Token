// SPDX-License-Identifier: UNLICENSED
// This smart contract code is proprietary.
// Unauthorized copying, modification, or distribution is strictly prohibited.
// For licensing inquiries or permissions, contact info@toolblox.net.
pragma solidity ^0.8.20;
interface IExternalcommunity_storage_f0ff707d {
	function getStatus(uint id) external view returns (uint64);
	function getName(uint id) external view returns (string memory);
	function getOwner(uint id) external view returns (address);
}



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
/* CHANGE STARTS HERE*/
// Minimal interfaces for cross-chain read via Toolblox Omni Adapter
interface ITixReadAdapter {
	function lzReadByNameWithCtx(
        address refundTo,
		uint32 dstEid,
		bytes32 svcKey,
		bytes4 readSel,
		bytes calldata readArgs,
		bytes4 cbSel,
		bytes calldata ctx
	) external payable;
	function lzReadByNameWithCtx(
        address refundTo,
		uint32 dstEid,
		bytes32 svcKey,
		bytes4 readSel,
		bytes calldata readArgs,
		bytes4 cbSel,
		bytes calldata ctx,
		bytes calldata extraOpts
	) external payable;
}

interface ICommunityRead {
	function getOwner(uint256 id) external view returns (address);
}
/*CHANGE ENDS HERE*/
contract TokenWorkflow  is Ownable, WorkflowBase{
	struct Token {
		uint id;
		uint64 status;
		string name;
		uint communityId;
	}
/* CHANGE STARTS HERE*/
	// Cross-chain read configuration
	ITixReadAdapter public omni;
	uint32 public communityEid;
	address public destTix; // Tix on destination chain (Community lives there)
	bytes32 public constant COMMUNITY_SVC = keccak256("community_contract");

	// Lightweight reentrancy guard (local to this contract)
	bool private _entered;
	modifier nonReentrant() {
		require(!_entered, "ReentrancyGuard");
		_entered = true;
		_;
		_entered = false;
	}
/*CHANGE ENDS HERE*/
	bytes32 communityFlowAddress = keccak256("community_storage_f0ff707d");
	mapping(uint => Token) public items;
	constructor() Ownable(_msgSender()) {
		serviceLocator = IExternalServiceLocator(0x9B3AD2533a7Db882C72E4C403e45c64F4A7E3F5b);
	}
	function setOwner(address _newOwner) public {
		transferOwnership(_newOwner);
	}
	function _assertStatus(Token storage item, uint64 status) private view {
		require(item.status == status, "Cannot run Workflow action; unexpected status");
	}
	function getItem(uint256 id) public view returns (Token memory) {
		return getViewFromItem(getItemInternal(id));
	}
	function getItemInternal(uint256 id) private view returns (Token storage) {
		Token storage item = items[id];
		require(item.id == id, "Cannot find item with given id");
		return item;
	}
	function getViewFromItem(Token storage item) private pure returns (Token memory) {
		return item;
	}
	function getLatest(uint256 cnt) public view returns(Token[] memory) {
		uint256[] memory latestIds = getLatestIds(cnt);
		Token[] memory latestItems = new Token[](latestIds.length);
		for (uint256 i = 0; i < latestIds.length; i++) latestItems[i] = getViewFromItem(items[latestIds[i]]);
		return latestItems;
	}
	function getPage(uint256 cursor, uint256 howMany) public view returns(Token[] memory) {
		uint256[] memory ids = getPageIds(cursor, howMany);
		Token[] memory result = new Token[](ids.length);
		for (uint256 i = 0; i < ids.length; i++) result[i] = getViewFromItem(items[ids[i]]);
		return result;
	}
	
	mapping(uint => uint[]) public itemsByCommunityId;
	function getItemIdsByCommunityId(uint communityId) public view returns (uint[] memory) {
		return itemsByCommunityId[communityId];
	}
	function getItemsByCommunityId(uint communityId) public view returns (Token[] memory) {
		uint[] memory itemIds = getItemIdsByCommunityId(communityId);
		Token[] memory itemsToReturn = new Token[](itemIds.length);
		for(uint256 i=0; i < itemIds.length; i++){
			itemsToReturn[i] = getItem(itemIds[i]);
		}
		return itemsToReturn;
	}
	function _setItemIdByCommunityId(uint oldForeignKey, uint newForeignKey, uint id) private {
		// If the old and new foreign keys are the same, no need to do anything
		if(oldForeignKey == newForeignKey) {
			return;
		}
		// If the old foreign key is not 0, remove the item from the old list
		if(oldForeignKey != 0) {
			removeFkMappingItem(itemsByCommunityId, oldForeignKey, id);
		}
		// If the new foreign key is not 0, add the item to the new list
		if(newForeignKey != 0) {
			addFkMappingItem(itemsByCommunityId, newForeignKey, id);
		}
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
	function getCommunityId(uint id) public view returns (uint){
		return getItemInternal(id).communityId;
	}
	function deploy(string memory name,uint communityId) public returns (uint256) {
		uint256 id = _getNextId();
		Token storage item = items[id];
		item.id = id;
		uint oldCommunityId = item.communityId;
		item.name = name;
		item.communityId = communityId;
		item.status = 0;
		uint newCommunityId = item.communityId;
		_setItemIdByCommunityId(oldCommunityId, newCommunityId, item.id);
		return id;
	}
	/* CHANGE STARTS HERE*/
	// Wire the cross-chain Community endpoint
	function setCrossChainCommunity(address router, uint32 eid, address destTix_) external onlyOwner {
		omni = ITixReadAdapter(router);
		communityEid = eid;
		destTix = destTix_;
	}

	// Initiate single-fee lzRead to fetch community owner wallet on destination chain
	function claimRewards(
		uint256 id,
		uint256 rewardAmount
	)
		external
		payable
		nonReentrant
		returns (uint256)
	{
		Token storage item = getItemInternal(id);
		_assertStatus(item, 0);

        bytes memory ctx     = abi.encode(id, rewardAmount, msg.sender);
        bytes4      readSel  = ICommunityRead.getOwner.selector;
        bytes memory readArgs = abi.encode(item.communityId);
        omni.lzReadByNameWithCtx{ value: msg.value }(
            msg.sender,
            communityEid,
            COMMUNITY_SVC,
            readSel,
            readArgs,
            this.finishClaimRewards.selector,
            ctx
        );

		return id;
	}

	// Callback from adapter after DVNs fetched getOwner(...)
	function finishClaimRewards(bytes calldata ctx, bytes32 svcKey, bytes calldata ret) external nonReentrant {
		require(msg.sender == address(omni), "router-only");
		require(svcKey == COMMUNITY_SVC, "svc mismatch");

        (uint256 id, uint256 rewardAmount, ) = abi.decode(ctx, (uint256, uint256, address));
        address tokenOwner = abi.decode(ret, (address));
		Token storage item = getItemInternal(id);

		_assertStatus(item, 0);

		if (tokenOwner != address(0) && rewardAmount > 0){
			payable(tokenOwner).transfer(rewardAmount);
		}

		emit ItemUpdated(id, item.status);
	}

	// Accept LayerZero executor native refunds and forward to owner; if forwarding fails, keep balance
	receive() external payable {
		(bool ok, ) = payable(owner()).call{ value: msg.value }("");
		if (!ok) {
			// noop: leave funds in contract for manual withdrawal
		}
	}
}