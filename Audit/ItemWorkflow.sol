// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/*
Seller can create an auction.
Anyone can bid on the item. If bid is valid the caller becomes highest bidder.
Any new high bid will return the money back to previous high bidder.
When deadline is passed the auction can be ended - the proceeds will be transferred to the Seller.
Highest bidder becomes the new "Seller".
*/
contract ItemWorkflow {

	struct Item {
		uint id;
		uint64 status;
		string name;
		uint price;
		string image;
		string description;
		uint endTime;
		address seller;
		address highestBidder;
	}

	address public owner;

	event ItemUpdated(uint256 _id);

	mapping(uint => Item) public items;

	bytes32 workflowName;

	xxxxxIServiceLocator serviceLocator;


	mapping(address => bool) public sellerList;
	function _assertOnlySeller(Item memory item) private view {
		address seller = item.seller;
		if (seller != address(0))
		{
			require(
				msg.sender == seller,
				"Invalid Seller"
			);
			return;
		}
		item.seller = msg.sender;
	}

	mapping(address => bool) public highestBidderList;
	function _assertOnlyHighestBidder(Item memory item) private view {
		address highestBidder = item.highestBidder;
		if (highestBidder != address(0))
		{
			require(
				msg.sender == highestBidder,
				"Invalid Highest bidder"
			);
			return;
		}
		item.highestBidder = msg.sender;
	}

	
	constructor() {
		owner = msg.sender;
		workflowName = keccak256("auction_with_extending_end");
		serviceLocator = xxxxxIServiceLocator(0xBE1B2722cBC114299C2C15F2dc57D362a7681575);
		serviceLocator.registerService(workflowName, address(this));
	}

	uint256 private count = 0;
	function _getNextId() private returns (uint256) {
		count = count + 1;
		return count;
	}

	function _assertStatus(Item memory item, uint64 status) private pure
	{
		require(
			item.status == status,
			"Cannot run Workflow action; unexpected status"
		);
	}

	function _assertValidItem(uint256 id) private view returns (Item memory)
	{
		Item memory item = items[id];
		require(
			item.id == id,
			"Cannot find item with given id"
		);
		return item;
	}

	receive() external payable {}

	fallback() external payable {}

	function getLatest(uint256 cnt) public view returns(Item[] memory) {
		uint256 toIndex = count;
		uint256 fromIndex = 0;
		if (cnt < toIndex)
		{
			fromIndex = toIndex - cnt;
		}
		if (fromIndex > toIndex || toIndex < 0)
		{
			return new Item[](0);
		}
		Item[] memory latestItems = new Item[](cnt);
		uint256 setterCount = 0;
		for(uint256 i=fromIndex; i < toIndex; i++){
			latestItems[setterCount] = items[i + 1];
			setterCount++;
		}
		return latestItems;
	}

	function getItemOwner(Item memory ) private view returns (address _owner) {
		_owner = address(this);
		if (_owner == address(0))
		{
			_owner = address(this);
		}
	}

	function getItem(uint256 id) public view returns (Item memory) {
		return _assertValidItem(id);
	}

	function getId(uint id) external view returns (uint){
		return _assertValidItem(id).id;
	}
	function getStatus(uint id) external view returns (uint64){
		return _assertValidItem(id).status;
	}
	function getName(uint id) external view returns (string memory){
		return _assertValidItem(id).name;
	}
	function getPrice(uint id) external view returns (uint){
		return _assertValidItem(id).price;
	}
	function getDescription(uint id) external view returns (string memory){
		return _assertValidItem(id).description;
	}
	function getImage(uint id) external view returns (string memory){
		return _assertValidItem(id).image;
	}

	function bidUp(uint256 id,uint bid) external payable returns (uint256)
	{
		Item memory item = _assertValidItem(id);

		_assertStatus(item, 0);
		require(bid > item.price, "Needs to be higher");
		require(item.endTime > block.timestamp, "Is active");

		address previousHighBidder = item.highestBidder;
		uint previousHighBid = item.price;
		item.highestBidder = msg.sender;
		item.price = bid;
		item.endTime = ( ( block.timestamp + ( 5 * 60 ) ) > item.endTime ) ? ( item.endTime + ( 5 * 60 ) ) : item.endTime;
		item.status = 0;
		items[id] = item;

		uint deposit = msg.value;
		uint priceToPay = (item.price) * 1000000000000;  
		require(
			deposit >= priceToPay,
			"Not enough deposit"
		);
		uint moneyToReturn = deposit - priceToPay;
		if(moneyToReturn > 0)
		{
			payable(msg.sender).transfer(moneyToReturn);
		}

		if (previousHighBidder != address(0) && previousHighBid > 0){
			payable(previousHighBidder).transfer(previousHighBid * 1000000000000);
		}
		emit ItemUpdated(id);
		return id;
	}


	function create(string calldata name,string calldata description,string calldata image,uint price) external returns (uint256)
	{
		uint256 id = _getNextId();
		Item memory item;
		item.id = id;
		items[id] = item;
		_assertOnlySeller(item);

		item.name = name;
		item.description = description;
		item.image = image;
		item.price = price;

		item.endTime = block.timestamp + ( ( ( 7 * 60 ) * 60 ) * 24 );
		item.status = 0;
		items[id] = item;
		emit ItemUpdated(id);
		return id;
	}


	function payout(uint256 id) external returns (uint256)
	{
		Item memory item = _assertValidItem(id);
		_assertStatus(item, 1);
		require(item.endTime > block.timestamp, "Has ended");

		address oldSeller = item.seller;
		item.seller = item.highestBidder;
		item.highestBidder = address(0);
		item.status = 3;
		items[id] = item;

		if (oldSeller != address(0) && item.price > 0){
			payable(oldSeller).transfer(item.price * 1000000000000);
		}
		emit ItemUpdated(id);
		return id;
	}


	function endAuction(uint256 id) external returns (uint256)
	{
		Item memory item = _assertValidItem(id);

		_assertStatus(item, 0);
		require(item.endTime < block.timestamp, "Has ended");

		if (( item.price > 0 ))
		{
			item.status = 1;
		} else {
			item.status = 2;
		}
		items[id] = item;

		emit ItemUpdated(id);
		return id;
	}


	function tryAgain(uint256 id,string calldata name,string calldata description,string calldata image,uint price) external returns (uint256)
	{
		Item memory item = _assertValidItem(id);
		_assertOnlySeller(item);
		_assertStatus(item, 2);

		item.name = name;
		item.description = description;
		item.image = image;
		item.price = price;

		item.endTime = block.timestamp + ( ( ( 7 * 60 ) * 60 ) * 24 );
		item.status = 0;
		items[id] = item;

		emit ItemUpdated(id);
		return id;
	}


	function startAgain(uint256 id,string calldata name,string calldata description,string calldata image,uint price) external returns (uint256)
	{
		Item memory item = _assertValidItem(id);
		_assertOnlySeller(item);
		_assertStatus(item, 3);

		item.name = name;
		item.description = description;
		item.image = image;
		item.price = price;


		item.endTime = block.timestamp + ( ( ( 7 * 60 ) * 60 ) * 24 );
		item.status = 0;
		items[id] = item;
		emit ItemUpdated(id);
		return id;
	}

}

interface xxxxxIServiceLocator {
	function getService(bytes32 name) external view returns (address);
	function getScheduler(address service) external view returns (address);
	function registerService(bytes32 name, address destination) external;
}