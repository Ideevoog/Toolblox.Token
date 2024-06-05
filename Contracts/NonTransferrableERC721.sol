// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract NonTransferrableERC721Upgradeable is Initializable, ERC721Upgradeable {
    function initialize(string memory name_, string memory symbol_) public initializer {
        __ERC721_init(name_, symbol_);
    }
    function _update(address to, uint256 tokenId, address auth) internal virtual override(ERC721Upgradeable) returns (address)
    {
        address from = _ownerOf(tokenId);        
        require(from == address(0), "NonTransferrableERC721: Token not transferable");
        return super._update(to, tokenId, auth);
    }
}

contract NonTransferrableERC721 is ERC721 {    
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}
    function _update(address to, uint256 tokenId, address auth) internal virtual override(ERC721) returns (address)
    {
        address from = _ownerOf(tokenId);        
        require(from == address(0), "NonTransferrableERC721: Token not transferable");
        return super._update(to, tokenId, auth);
    }
}