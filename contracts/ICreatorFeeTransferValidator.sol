// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// Validator interface matching:
// validateTransfer(address caller, address from, address to, uint256 tokenId)
interface ICreatorFeeTransferValidator {
    function validateTransfer(
        address caller,
        address from,
        address to,
        uint256 tokenId
    ) external view;
}