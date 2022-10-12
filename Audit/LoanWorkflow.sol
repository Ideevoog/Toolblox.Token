// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/token/ERC721/ERC721.sol";

/*
Lendees can request for loans. 
Lenders can issue loans.
Lendees can pay back loans, until they are fully paid back.
Workflow is erc721, which means the loan can be externally transferred to another lender, insured, collaterized
	or otherwise enriched with external DeFi tools.
*/
contract LoanWorkflow is ERC721 {
	struct Loan {
		uint id;
		uint64 status;
		string name;
		address lender;
		address lendee;
		uint deadline;
		uint price;
		uint loanAmount;
		uint paidBack;
		uint64 paybackDays;
	}
	address public owner;

	event ItemUpdated(uint256 _id);

	mapping(uint => Loan) public items;

	bytes32 workflowName;

	xxxxxIServiceLocator serviceLocator;

	address public token = 0x02CBE6055F8aad745321f70d6aDD4711455c7F45;
	function safeTransferFromExternal(address from, address to, uint value) internal {
		(bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
		require(
			success && (data.length == 0 || abi.decode(data, (bool))),
			'TransferHelper::transferFrom: transferFrom failed'
		);
	}
	function safeTransferExternal(address to, uint256 value) internal {
		(bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
		require(
		success && (data.length == 0 || abi.decode(data, (bool))),
		'TransferHelper::safeTransfer: transfer failed'
		);
	}

	mapping(address => bool) public lenderList;
	function _assertOnlyLender(Loan memory item) private view {
		address lender = item.lender;
		if (lender != address(0))
		{
			require(
				msg.sender == lender,
				"Invalid Lender"
			);
			return;
		}
		item.lender = msg.sender;
	}

	mapping(address => bool) public lendeeList;
	function _assertOnlyLendee(Loan memory item) private view {
		address lendee = item.lendee;
		if (lendee != address(0))
		{
			require(
				msg.sender == lendee,
				"Invalid Lendee"
			);
			return;
		}
		item.lendee = msg.sender;
	}

	
	constructor() ERC721("Loan - Loan as NFT721", "LOAN"){
		owner = msg.sender;
		workflowName = keccak256("loan_as_nft721");
		serviceLocator = xxxxxIServiceLocator(0x3a0c2420DaB098B30B866f45538480A765d72Fa4);
		serviceLocator.registerService(workflowName, address(this));
	}

	uint256 private count = 0;
	function _getNextId() private returns (uint256) {
		count = count + 1;
		return count;
	}

	function _assertStatus(Loan memory item, uint64 status) private pure
	{
		require(
			item.status == status,
			"Cannot run Workflow action; unexpected status"
		);
	}

	function _assertValidItem(uint256 id) private view returns (Loan memory)
	{
		Loan memory item = items[id];
		require(
			item.id == id,
			"Cannot find item with given id"
		);
		return item;
	}

	receive() external payable {}

	fallback() external payable {}

	function getLatest(uint256 cnt) public view returns(Loan[] memory) {
		uint256 toIndex = count;
		uint256 fromIndex = 0;
		if (cnt < toIndex)
		{
			fromIndex = toIndex - cnt;
		}
		if (fromIndex > toIndex || toIndex < 0)
		{
			return new Loan[](0);
		}
		Loan[] memory latestItems = new Loan[](cnt);
		uint256 setterCount = 0;
		for(uint256 i=fromIndex; i < toIndex; i++){
			latestItems[setterCount] = items[i + 1];
			setterCount++;
		}
		return latestItems;
	}

	function getItemOwner(Loan memory item) private view returns (address _owner) {
		if (item.status == 1) {
			_owner = item.lender;
		}
		else if (item.status == 2) {
			_owner = item.lender;
		}
		else {
			_owner = address(this);
		}

		if (_owner == address(0))
		{
			_owner = address(this);
		}
	}

	function getItem(uint256 id) public view returns (Loan memory) {
		return _assertValidItem(id);
	}

	function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
		if (from == to)
		{
			return;
		}
		Loan memory item = _assertValidItem(tokenId);
		if (item.status == 1) {
			item.lender = to;
		}
		if (item.status == 2) {
			item.lender = to;
		}
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return "https://app.toolblox.net/flow/loan_as_nft721/";
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

	function requestLoan(uint loanAmount,uint price,uint64 paybackDays) external returns (uint256)
	{
		uint256 id = _getNextId();
		Loan memory item;
		item.id = id;
		items[id] = item;
		_assertOnlyLendee(item);
		require(item.price >= item.loanAmount, "Invalid prices");
		item.loanAmount = loanAmount;
		item.price = price;
		item.paybackDays = paybackDays;

		item.status = 0;
		items[id] = item;
		address newOwner = getItemOwner(item);
		_mint(newOwner, id);

		emit ItemUpdated(id);
		return id;
	}

	function update(uint256 id,uint loanAmount,uint price,uint64 paybackDays) external returns (uint256)
	{
		Loan memory item = _assertValidItem(id);
		_assertOnlyLendee(item);
		_assertStatus(item, 0);
		require(item.price >= item.loanAmount, "Invalid prices");
		item.loanAmount = loanAmount;
		item.price = price;
		item.paybackDays = paybackDays;

		item.status = 0;
		items[id] = item;
		address oldOwner = getItemOwner(item);
		address newOwner = getItemOwner(item);
		if (newOwner != oldOwner) {
			_transfer(oldOwner, newOwner, id);
		}

		emit ItemUpdated(id);
		return id;
	}

	function issueLoan(uint256 id) external returns (uint256)
	{
		Loan memory item = _assertValidItem(id);
		_assertOnlyLender(item);
		_assertStatus(item, 0);

		item.deadline = block.timestamp + ( ( ( item.paybackDays * 60 ) * 60 ) * 24 );
		item.status = 1;
		items[id] = item;
		address oldOwner = getItemOwner(item);
		address newOwner = getItemOwner(item);

		if (newOwner != oldOwner) {
				_transfer(oldOwner, newOwner, id);
		}

		safeTransferFromExternal(msg.sender, item.lendee, item.loanAmount * 1000000000000);
		emit ItemUpdated(id);
		return id;
	}

	function payBack(uint256 id,uint amount) external returns (uint256)
	{
		Loan memory item = _assertValidItem(id);

		_assertStatus(item, 1);

		item.paidBack = item.paidBack + amount;

		if (( item.price <= item.paidBack ))
		{
			item.status = 2;
		} else {
			item.status = 1;
		}
		items[id] = item;
		address oldOwner = getItemOwner(item);
		address newOwner = getItemOwner(item);
		if (newOwner != oldOwner) {
			_transfer(oldOwner, newOwner, id);
		}

		safeTransferFromExternal(msg.sender, item.lender, amount * 1000000000000);
		emit ItemUpdated(id);
		return id;
	}


	function cancel(uint256 id) external returns (uint256)
	{
		Loan memory item = _assertValidItem(id);
		_assertOnlyLendee(item);
		_assertStatus(item, 0);
		item.status = 3;
		items[id] = item;
		address oldOwner = getItemOwner(item);
		address newOwner = getItemOwner(item);

		if (newOwner != oldOwner) {
			_transfer(oldOwner, newOwner, id);
		}
		emit ItemUpdated(id);
		return id;
	}
}

interface xxxxxIServiceLocator {
	function getService(bytes32 name) external view returns (address);
	function getScheduler(address service) external view returns (address);
	function registerService(bytes32 name, address destination) external;
}