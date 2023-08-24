// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "../Contracts/WorkflowBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RentalWorkflow  is WorkflowBase, Ownable{
	struct Rental {
		uint id;
		string name;
		address renter;
		uint startTime;
		uint pricePerDay;
		uint daysCharged;
		uint collateral;
		uint leftoverCharge;
		uint64 numberOfDays;
		uint64 status;
	}
	event ItemUpdated(uint256 _id, uint64 _status);
	mapping(uint => Rental) public items;
	IExternalServiceLocator serviceLocator;
	address public token = 0x02CBE6055F8aad745321f70d6aDD4711455c7F45;
	bytes32 public constant RENTER_ROLE = keccak256("RENTER_ROLE");
	function _assertOnlyRenter(Rental memory item) private view {
		address renter = item.renter;
		if (renter != address(0))
		{
			require(_msgSender() == renter, "Invalid Renter");
			return;
		}
		item.renter = _msgSender();
	}
	
	constructor()  {
		_transferOwnership(_msgSender());
		serviceLocator = IExternalServiceLocator(0xaD26E98e521ef7Cd31c4a915Fe71560C968C37Db);
	}
	receive() external payable {}
	fallback() external payable {}
	function setOwner(address _newOwner) public {
		transferOwnership(_newOwner);
	}
	function _assertStatus(Rental memory item, uint64 status) private pure {
		require(item.status == status, "Cannot run Workflow action; unexpected status");
	}
	function getItem(uint256 id) public view returns (Rental memory) {
		Rental memory item = items[id];
		require(item.id == id, "Cannot find item with given id");
		return item;
	}
	function getLatest(uint256 cnt) public view returns(Rental[] memory) {
        uint256[] memory latestIds = getLatestIds(cnt);
        Rental[] memory latestItems = new Rental[](latestIds.length);
        for (uint256 i = 0; i < latestIds.length; i++) latestItems[i] = items[latestIds[i]];
        return latestItems;
	}
	function getPage(uint256 cursor, uint256 howMany) public view returns(Rental[] memory) {
        uint256[] memory ids = getPageIds(cursor, howMany);
        Rental[] memory result = new Rental[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) result[i] = items[ids[i]];
        return result;
	}
	function startRent(uint256 id,uint64 numberOfDays,uint allowance) external returns (uint256) {
		Rental memory item = getItem(id);
		_assertOnlyRenter(item);
		_assertStatus(item, 3);
		require(allowance == ( numberOfDays * item.pricePerDay ), "Allowance is correct?");
		item.numberOfDays = numberOfDays;
		item.startTime = block.timestamp;
		item.status = 1;
		items[id] = item;
		if (address(this) != address(0) && item.collateral > 0){
			safeTransferFromExternal(token, _msgSender(), address(this), item.collateral);
		}
		emit ItemUpdated(id, item.status);
		return id;
	}
	function charge(uint256 id) external returns (uint256) {
		Rental memory item = getItem(id);
		_checkOwner();
		_assertStatus(item, 1);
		uint daysToCharge = ( ( block.timestamp - item.startTime ) / ( ( 24 * 60 ) * 60 ) ) - item.daysCharged;
		item.daysCharged = item.daysCharged + daysToCharge;
		item.leftoverCharge = daysToCharge * item.pricePerDay;
		item.status = 1;
		items[id] = item;
		if (owner() != address(0) && item.renter != address(0) && item.leftoverCharge > 0){
			safeTransferFromExternal(token, item.renter, owner(), item.leftoverCharge);
		}
		emit ItemUpdated(id, item.status);
		return id;
	}
	function endRental(uint256 id) external returns (uint256) {
		Rental memory item = getItem(id);
		_checkOwner();
		_assertStatus(item, 1);
		uint nominalFee = ( item.numberOfDays - item.daysCharged ) * item.pricePerDay;
		uint endTime = item.startTime + ( ( ( item.numberOfDays * 24 ) * 60 ) * 60 );
		item.leftoverCharge = nominalFee + ( ( block.timestamp > endTime ) ? ( ( endTime - block.timestamp ) * ( ( ( item.pricePerDay / 24 ) / 60 ) / 60 ) ) : 0 );
		item.status = 2;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		return id;
	}
	function registerItem(string calldata name,uint collateral,uint pricePerDay) external returns (uint256) {
		uint256 id = _getNextId();
		Rental memory item;
		item.id = id;
		items[id] = item;
		_checkOwner();
		item.name = name;
		item.collateral = collateral;
		item.pricePerDay = pricePerDay;
		item.status = 3;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		return id;
	}
	function finalCharge(uint256 id,uint chargeAmount) external returns (uint256) {
		Rental memory item = getItem(id);
		_checkOwner();
		_assertStatus(item, 2);
		require(chargeAmount <= item.leftoverCharge, "Cannot charge more than leftover");

		item.status = ( chargeAmount == item.leftoverCharge ) ? 4 : 2;
		items[id] = item;
		if (owner() != address(0) && item.renter != address(0) && chargeAmount > 0){
			safeTransferFromExternal(token, item.renter, owner(), chargeAmount);
		}
		emit ItemUpdated(id, item.status);
		return id;
	}
	function increaseAllowance(uint256 id) external returns (uint256) {
		Rental memory item = getItem(id);
		_assertOnlyRenter(item);
		_assertStatus(item, 2);

		item.status = 2;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		return id;
	}
	function chargeWithCollateral(uint256 id) external returns (uint256) {
		Rental memory item = getItem(id);
		_checkOwner();
		_assertStatus(item, 2);
		require(item.collateral >= item.leftoverCharge, "Has collateral");
		item.collateral = item.collateral - item.leftoverCharge;
		item.status = 4;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		return id;
	}
	function releaseCollateral(uint256 id,uint chargeAmount,string calldata /*evidence*/) external returns (uint256) {
		Rental memory item = getItem(id);
		_assertStatus(item, 4);
		require(item.collateral >= chargeAmount, "Has collateral?");
		item.collateral = item.collateral - chargeAmount;
		item.status = 5;
		items[id] = item;
		if (item.renter != address(0) && item.collateral > 0){
			safeTransferExternal(token, item.renter, item.collateral);
		}
		emit ItemUpdated(id, item.status);
		return id;
	}
	function makeAvailable(uint256 id,string calldata name,uint collateral,uint pricePerDay) external returns (uint256) {
		Rental memory item = getItem(id);
		_checkOwner();
		_assertStatus(item, 5);
		item.name = name;
		item.collateral = collateral;
		item.pricePerDay = pricePerDay;
		item.renter = address(0);
		item.startTime = 0;
		item.leftoverCharge = 0;
		item.daysCharged = 0;
		item.numberOfDays = 0;
		item.collateral = 0;
		item.status = 3;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		return id;
	}
	function update(uint256 id,string calldata name,uint collateral,uint pricePerDay) external returns (uint256) {
		Rental memory item = getItem(id);
		_checkOwner();
		_assertStatus(item, 3);
		item.name = name;
		item.collateral = collateral;
		item.pricePerDay = pricePerDay;
		item.status = 3;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		return id;
	}
	function endAndSettle(uint256 id) external returns (uint256) {
		Rental memory item = getItem(id);
		_checkOwner();
		_assertStatus(item, 1);
		uint nominalFee = ( item.numberOfDays - item.daysCharged ) * item.pricePerDay;
		uint endTime = item.startTime + ( ( ( item.numberOfDays * 24 ) * 60 ) * 60 );
		item.leftoverCharge = nominalFee + ( ( block.timestamp > endTime ) ? ( ( endTime - block.timestamp ) * ( ( ( item.pricePerDay / 24 ) / 60 ) / 60 ) ) : 0 );
		item.status = 5;
		items[id] = item;
		if (item.renter != address(0) && item.collateral > 0){
			safeTransferExternal(token, item.renter, item.collateral);
		}
		if (owner() != address(0) && item.renter != address(0) && item.leftoverCharge > 0){
			safeTransferFromExternal(token, item.renter, owner(), item.leftoverCharge);
		}
		emit ItemUpdated(id, item.status);
		return id;
	}
	function updateAllowance(uint256 id) external returns (uint256) {
		Rental memory item = getItem(id);
		_assertOnlyRenter(item);
		_assertStatus(item, 1);

		item.status = 1;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		return id;
	}
	function updateDuration(uint256 id,uint64 numberOfDays) external returns (uint256) {
		Rental memory item = getItem(id);
		_checkOwner();
		_assertStatus(item, 1);
		item.numberOfDays = numberOfDays;
		item.status = 1;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		return id;
	}
}