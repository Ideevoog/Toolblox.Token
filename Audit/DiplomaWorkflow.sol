// SPDX-License-Identifier: UNLICENSED

// This smart contract code is proprietary.
// Unauthorized copying, modification, or distribution is strictly prohibited.
// For licensing inquiries or permissions, contact info@toolblox.net.

pragma solidity ^0.8.19;
import "../Contracts/WorkflowBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../Contracts/NonTransferrableERC721.sol";
/*
	**Toolblox Workflow Analysis: Diplomas as NFTs**
	
	### Overview:
	
	The "Diplomas as NFTs" workflow in Toolblox is designed to facilitate the issuance of diplomas or certificates as non-transferrable NFTs (Non-Fungible Tokens) on the blockchain. This workflow leverages the NonTransferrableERC721, ERC721, and ERC721Enumerable standards, ensuring that the diploma, once minted, remains with the original holder and cannot be transferred to another address.
	
	### Use Cases:
	
	1.  **Issuance of Diplomas/Certificates**:
	    
	    *   Educational institutions, training organizations, or any certification body can utilize this workflow to issue diplomas or certificates to their students or participants.
	    *   The diploma details, including its name, description, and an image (possibly a visual representation or scan), are stored on the blockchain.
	    *   The holder's address ensures that the diploma is associated with a specific individual or entity.
	2.  **Verification and Authentication**:
	    
	    *   Employers, institutions, or any third party can verify the authenticity of a diploma by checking its presence on the blockchain. This ensures that the diploma is genuine and has been issued by a recognized entity.
	    *   The non-transferrable nature of the NFT ensures that the diploma remains with the original recipient, preventing any potential misuse or misrepresentation.
	3.  **Digital Showcase**:
	    
	    *   Graduates or certificate holders can showcase their achievements on digital platforms, portfolios, or social media by sharing their NFT-based diplomas. This provides a modern, digital alternative to traditional paper certificates.
	
	### Why Diplomas as a Smart Contract Makes Sense:
	
	1.  **Immutable Record**: Once a diploma is minted as an NFT and added to the blockchain, it becomes an immutable record. This ensures that the diploma cannot be tampered with or altered, providing a high level of trust and authenticity.
	    
	2.  **Reduction in Forgery**: The blockchain-based nature of the diploma reduces the chances of forgery. Traditional paper-based diplomas can be replicated or falsified, but an NFT-based diploma on the blockchain provides a verifiable proof of its legitimacy.
	    
	3.  **Easy Verification**: For entities that need to verify the authenticity of a diploma (e.g., employers during hiring), the blockchain provides a quick and reliable method. They can easily check the diploma against the blockchain record.
	    
	4.  **Environmental Benefits**: Digital diplomas reduce the need for paper, ink, and other resources associated with traditional diploma issuance, contributing to environmental sustainability.
	    
	5.  **Global Accessibility**: NFT-based diplomas are accessible from anywhere in the world, making it easier for international students or professionals to share and verify their qualifications across borders.
	    
	
	In summary, the "Diplomas as NFTs" workflow in Toolblox offers a modern, secure, and efficient solution to the challenges associated with traditional diploma issuance and verification. It harnesses the power of blockchain technology to bring trust, transparency, and convenience to the world of academic and professional achievements.
*/
contract DiplomaWorkflow  is WorkflowBase, Ownable, ERC721, ERC721Enumerable, NonTransferrableERC721{
	struct Diploma {
		uint id;
		uint64 status;
		string name;
		string description;
		string image;
		address holder;
	}
	mapping(uint => Diploma) public items;
	function _assertOrAssignHolder(Diploma memory item) private view {
		address holder = item.holder;
		if (holder != address(0))
		{
			require(_msgSender() == holder, "Invalid Holder");
			return;
		}
		item.holder = _msgSender();
	}
	constructor() NonTransferrableERC721("Diploma - Diplomas as NFTs", "CERT") {
		_transferOwnership(_msgSender());
	}
	function setOwner(address _newOwner) public {
		transferOwnership(_newOwner);
	}
/*
	Available statuses:
	0 Issued (owner Holder)
*/
	function _assertStatus(Diploma memory item, uint64 status) private pure {
		require(item.status == status, "Cannot run Workflow action; unexpected status");
	}
	function getItem(uint256 id) public view returns (Diploma memory) {
		Diploma memory item = items[id];
		require(item.id == id, "Cannot find item with given id");
		return item;
	}
	function getLatest(uint256 cnt) public view returns(Diploma[] memory) {
		uint256[] memory latestIds = getLatestIds(cnt);
		Diploma[] memory latestItems = new Diploma[](latestIds.length);
		for (uint256 i = 0; i < latestIds.length; i++) latestItems[i] = items[latestIds[i]];
		return latestItems;
	}
	function getPage(uint256 cursor, uint256 howMany) public view returns(Diploma[] memory) {
		uint256[] memory ids = getPageIds(cursor, howMany);
		Diploma[] memory result = new Diploma[](ids.length);
		for (uint256 i = 0; i < ids.length; i++) result[i] = items[ids[i]];
		return result;
	}
	function getItemOwner(Diploma memory item) private view returns (address itemOwner) {
				if (item.status == 0) {
			itemOwner = item.holder;
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
		Diploma memory item = getItem(firstTokenId);
		if (item.status == 0) {
			item.holder = to;
		}
	}
	function supportsInterface(bytes4 interfaceId) public view override(ERC721,ERC721Enumerable) returns (bool) {
		return super.supportsInterface(interfaceId);
	}
	function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual override (ERC721,ERC721Enumerable,NonTransferrableERC721) {
		super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
	}
	function _baseURI() internal view virtual override returns (string memory) {
		return "https://nft.toolblox.net/api/metadata?workflowId=diplomas_as_nfts&id=";
	}
/*
	### Transition: 'Issue'
	This transition creates a new object and puts it into `Issued` state.
	
	#### Transition Parameters
	For this transition, the following parameters are required: 
	
	* `Name` (Text)
	* `Description` (Text)
	* `Image` (Image)
	* `Holder` (User)
	
	#### Access Restrictions
	Access is exclusively limited to the owner of the workflow.
	
	#### Checks and updates
	The following properties will be updated on blockchain:
	
	* `Name` (String)
	* `Description` (String)
	* `Image` (Image)
	* `Holder` (Address)
*/
	function issue(string calldata name,string calldata description,string calldata image,address holder) external onlyOwner returns (uint256) {
		uint256 id = _getNextId();
		Diploma memory item;
		item.id = id;
		items[id] = item;
		item.name = name;
		item.description = description;
		item.image = image;
		item.holder = holder;
		item.status = 0;
		items[id] = item;
		address newOwner = getItemOwner(item);
		_mint(newOwner, id);
		emit ItemUpdated(id, item.status);
		return id;
	}
}