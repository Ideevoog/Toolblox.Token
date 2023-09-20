// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;
import "../Contracts/WorkflowBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
/*
	### Overview:
	
	This smart contract is designed to manage the auditing process of ERC721 tokens with ReentrancyGuard protection. The contract also involves the use of DERC20 currency. The workflow is structured around the stages of preparing, ordering, progressing, and completing an audit.
	
	### Use Cases:
	
	1.  **Service Account Role**
	    
	    *   **Can**: Prepare an audit
	        *   **So that**: The necessary details like Name, Order, Price, Auditor, Image, and Client are set up for the audit.
	        *   **Conditions**: Only when the audit is in the 'Prepared' state and access is restricted to the service account.
	2.  **Client Role**
	    
	    *   **Can**: Pay for the audit
	        *   **So that**: The audit can move from the 'Prepared' state to the 'Ordered' state.
	        *   **Conditions**: Only when the audit is in the 'Prepared' state and access is restricted to the client.
	3.  **Auditor Role**
	    
	    *   **Can**: Start the audit
	        *   **So that**: The audit can move from the 'Ordered' state to the 'In progress' state.
	        *   **Conditions**: Only when the audit is in the 'Ordered' state and access is restricted to the auditor.
	    *   **Can**: Update the progress of the audit
	        *   **So that**: Necessary updates like Name and Description can be made while the audit is ongoing.
	        *   **Conditions**: Only when the audit is in the 'In progress' state and access is restricted to the auditor.
	    *   **Can**: Complete the audit
	        *   **So that**: Final details like Name, Image, Description, and Report can be provided, marking the audit as completed.
	        *   **Conditions**: Only when the audit is in the 'In progress' state and access is restricted to the auditor.
	
	### Why it makes sense to have this as a smart contract:
	
	1.  **Transparency**: Every step in the auditing process is recorded on the blockchain, ensuring transparency for all parties involved.
	    
	2.  **Security**: The use of restricted access ensures that only authorized parties can perform specific actions, reducing the risk of unauthorized changes or malicious activities.
	    
	3.  **Automation**: The smart contract automates the workflow, ensuring that each step is followed in sequence and conditions are met before progressing.
	    
	4.  **Immutability**: Once data is recorded on the blockchain, it cannot be altered, ensuring the integrity of the audit records.
	    
	5.  **Trust**: With the entire process being transparent and immutable, it builds trust among the parties involved, knowing that the process is fair and tamper-proof.
	    
	6.  **Efficiency**: Transactions and updates are processed in real-time, reducing delays and ensuring timely completion of audits.
*/
contract AuditWorkflow  is WorkflowBase, Ownable, AccessControl, ERC721, ReentrancyGuard{
	struct Audit {
		uint id;
		uint64 status;
		string name;
		address client;
		string order;
		uint price;
		string notes;
		string image;
		address auditor;
		address serviceAccount;
		string description;
		string report;
	}
	mapping(uint => Audit) public items;
	address public token = 0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1;
	function _assertOrAssignClient(Audit memory item) private view {
		address client = item.client;
		if (client != address(0))
		{
			require(_msgSender() == client, "Invalid Client");
			return;
		}
		item.client = _msgSender();
	}
	bytes32 public constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE");
	function _assertOrAssignAuditor(Audit memory item) private view {
		address auditor = item.auditor;
		if (auditor != address(0))
		{
			require(_msgSender() == auditor, "Invalid Auditor");
			return;
		}
		_checkRole(AUDITOR_ROLE);
		item.auditor = _msgSender();
	}
	function addAuditor(address adr) public returns (address) {
		grantRole(AUDITOR_ROLE, adr);
		return adr;
	}
	bytes32 public constant SERVICE_ACCOUNT_ROLE = keccak256("SERVICE_ACCOUNT_ROLE");
	function _assertOrAssignServiceAccount(Audit memory item) private view {
		address serviceAccount = item.serviceAccount;
		if (serviceAccount != address(0))
		{
			require(_msgSender() == serviceAccount, "Invalid Service account");
			return;
		}
		_checkRole(SERVICE_ACCOUNT_ROLE);
		item.serviceAccount = _msgSender();
	}
	function addServiceAccount(address adr) public returns (address) {
		grantRole(SERVICE_ACCOUNT_ROLE, adr);
		return adr;
	}
	constructor() ERC721("Audit - Smart Contract Auditing 8c58d275", "AUDIT") {
		_transferOwnership(_msgSender());
		_grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
	}
	function setOwner(address _newOwner) public {
		transferOwnership(_newOwner);
	}
	function transferOwnership(address newOwner) public override onlyOwner {
		revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
		super.transferOwnership(newOwner);
		_grantRole(DEFAULT_ADMIN_ROLE, newOwner);
	}
/*
	Available statuses:
	0 Prepared (owner Service account)
	1 Ordered (owner Auditor)
	2 In progress (owner Auditor)
	3 Completed (owner Client)
*/
	function _assertStatus(Audit memory item, uint64 status) private pure {
		require(item.status == status, "Cannot run Workflow action; unexpected status");
	}
	function getItem(uint256 id) public view returns (Audit memory) {
		Audit memory item = items[id];
		require(item.id == id, "Cannot find item with given id");
		return item;
	}
	function getLatest(uint256 cnt) public view returns(Audit[] memory) {
		uint256[] memory latestIds = getLatestIds(cnt);
		Audit[] memory latestItems = new Audit[](latestIds.length);
		for (uint256 i = 0; i < latestIds.length; i++) latestItems[i] = items[latestIds[i]];
		return latestItems;
	}
	function getPage(uint256 cursor, uint256 howMany) public view returns(Audit[] memory) {
		uint256[] memory ids = getPageIds(cursor, howMany);
		Audit[] memory result = new Audit[](ids.length);
		for (uint256 i = 0; i < ids.length; i++) result[i] = items[ids[i]];
		return result;
	}
	function getItemOwner(Audit memory item) private view returns (address itemOwner) {
				if (item.status == 0) {
			itemOwner = item.serviceAccount;
		}
		else 		if (item.status == 1) {
			itemOwner = item.auditor;
		}
		else 		if (item.status == 2) {
			itemOwner = item.auditor;
		}
		else 		if (item.status == 3) {
			itemOwner = item.client;
		}
        else {
			itemOwner = address(this);
        }
        if (itemOwner == address(0))
        {
            itemOwner = address(this);
        }
	}
	function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual override {
		super._afterTokenTransfer(from, to, firstTokenId, batchSize);
		if (from == to)
		{
			return;
		}
		Audit memory item = getItem(firstTokenId);
		if (item.status == 0) {
			item.serviceAccount = to;
		}
		if (item.status == 1) {
			item.auditor = to;
		}
		if (item.status == 2) {
			item.auditor = to;
		}
		if (item.status == 3) {
			item.client = to;
		}
	}
	function supportsInterface(bytes4 interfaceId) public view override(AccessControl,ERC721) returns (bool) {
		return super.supportsInterface(interfaceId);
	}
	function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual override (ERC721) {
		super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
	}
	function _baseURI() internal view virtual override returns (string memory) {
		return "https://nft.toolblox.net/api/metadata?workflowId=smart_contract_auditing_8c58d275&id=";
	}
/*
	### Transition: 'Prepare audit'
	This transition creates a new object and puts it into `Prepared` state.
	
	#### Transition Parameters
	For this transition, the following parameters are required: 
	
	* `Name` (Text)
	* `Order` (Text)
	* `Price` (Money)
	* `Auditor` (Restricted user)
	* `Image` (Image)
	* `Client` (User)
	
	#### Access Restrictions
	Access is specifically restricted to the user with the address from the `Service account` property. If `Service account` property is not yet set (and if address is a pre-registered Service account) then the method caller becomes the objects `Service account`.
	
	#### Checks and updates
	The following properties will be updated on blockchain:
	
	* `Name` (String)
	* `Order` (String)
	* `Price` (Money)
	* `Auditor` (RestrictedAddress)
	* `Image` (Image)
	* `Client` (Address)
*/
	function prepareAudit(string calldata name,string calldata order,uint price,address auditor,string calldata image,address client) external nonReentrant returns (uint256) {
		uint256 id = _getNextId();
		Audit memory item;
		item.id = id;
		items[id] = item;
		_assertOrAssignServiceAccount(item);
		item.name = name;
		item.order = order;
		item.price = price;
		item.auditor = auditor;
		item.image = image;
		item.client = client;
		item.status = 0;
		items[id] = item;
		address newOwner = getItemOwner(item);
		_mint(newOwner, id);
		emit ItemUpdated(id, item.status);
		return id;
	}
/*
	### Transition: 'Pay for audit'
	This transition begins from `Prepared` and leads to the state `Ordered`.
	
	#### Access Restrictions
	Access is specifically restricted to the user with the address from the `Client` property. If `Client` property is not yet set then the method caller becomes the objects `Client`.
*/
	function payForAudit(uint256 id) external nonReentrant returns (uint256) {
		Audit memory item = getItem(id);
		_assertOrAssignClient(item);
		_assertStatus(item, 0);
		address oldOwner = getItemOwner(item);

		item.status = 1;
		items[id] = item;
		address newOwner = getItemOwner(item);
		if (newOwner != oldOwner) {
			_transfer(oldOwner, newOwner, id);
		}
		emit ItemUpdated(id, item.status);
		return id;
	}
/*
	### Transition: 'Update progress'
	This transition begins from `In progress` and leads to the state `In progress`.
	
	#### Transition Parameters
	For this transition, the following parameters are required: 
	
	* `Id` (Integer) - Audit identifier
	* `Name` (Text)
	* `Description` (Text)
	
	#### Access Restrictions
	Access is specifically restricted to the user with the address from the `Auditor` property. If `Auditor` property is not yet set (and if address is a pre-registered Auditor) then the method caller becomes the objects `Auditor`.
	
	#### Checks and updates
	The following properties will be updated on blockchain:
	
	* `Name` (String)
	* `Description` (String)
*/
	function updateProgress(uint256 id,string calldata name,string calldata description) external nonReentrant returns (uint256) {
		Audit memory item = getItem(id);
		_assertOrAssignAuditor(item);
		_assertStatus(item, 2);
		address oldOwner = getItemOwner(item);
		item.name = name;
		item.description = description;
		item.status = 2;
		items[id] = item;
		address newOwner = getItemOwner(item);
		if (newOwner != oldOwner) {
			_transfer(oldOwner, newOwner, id);
		}
		emit ItemUpdated(id, item.status);
		return id;
	}
/*
	### Transition: 'Complete'
	This transition begins from `In progress` and leads to the state `Completed`.
	
	#### Transition Parameters
	For this transition, the following parameters are required: 
	
	* `Id` (Integer) - Audit identifier
	* `Name` (Text)
	* `Image` (Image)
	* `Description` (Text)
	* `Report` (Blob)
	
	#### Access Restrictions
	Access is specifically restricted to the user with the address from the `Auditor` property. If `Auditor` property is not yet set (and if address is a pre-registered Auditor) then the method caller becomes the objects `Auditor`.
	
	#### Checks and updates
	The following properties will be updated on blockchain:
	
	* `Name` (String)
	* `Image` (Image)
	* `Description` (String)
	* `Report` (Blob)
*/
	function complete(uint256 id,string calldata name,string calldata image,string calldata description,string calldata report) external nonReentrant returns (uint256) {
		Audit memory item = getItem(id);
		_assertOrAssignAuditor(item);
		_assertStatus(item, 2);
		address oldOwner = getItemOwner(item);
		item.name = name;
		item.image = image;
		item.description = description;
		item.report = report;
		item.status = 3;
		items[id] = item;
		address newOwner = getItemOwner(item);
		if (newOwner != oldOwner) {
			_transfer(oldOwner, newOwner, id);
		}
		emit ItemUpdated(id, item.status);
		return id;
	}
/*
	### Transition: 'Start'
	This transition begins from `Ordered` and leads to the state `In progress`.
	
	#### Transition Parameters
	For this transition, the following parameters are required: 
	
	* `Id` (Integer) - Audit identifier
	* `Description` (Text)
	
	#### Access Restrictions
	Access is specifically restricted to the user with the address from the `Auditor` property. If `Auditor` property is not yet set (and if address is a pre-registered Auditor) then the method caller becomes the objects `Auditor`.
	
	#### Checks and updates
	The following properties will be updated on blockchain:
	
	* `Description` (String)
*/
	function start(uint256 id,string calldata description) external nonReentrant returns (uint256) {
		Audit memory item = getItem(id);
		_assertOrAssignAuditor(item);
		_assertStatus(item, 1);
		address oldOwner = getItemOwner(item);
		item.description = description;
		item.status = 2;
		items[id] = item;
		address newOwner = getItemOwner(item);
		if (newOwner != oldOwner) {
			_transfer(oldOwner, newOwner, id);
		}
		emit ItemUpdated(id, item.status);
		return id;
	}
}