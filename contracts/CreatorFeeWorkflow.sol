// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./ICreatorToken.sol";
import "./ICreatorFeeTransferValidator.sol";

abstract contract CreatorFeeWorkflow is ICreatorToken {
    address private _transferValidator;

    function getTransferValidator()
        public
        view
        override
        returns (address validator)
    {
        return _transferValidator;
    }

    /// @dev internal setter; exposed with access control in the final contract
    function _setTransferValidator(address validator) internal {
        address old = _transferValidator;
        _transferValidator = validator;
        emit TransferValidatorUpdated(old, validator);
    }

    function getTransferValidationFunction()
        external
        pure
        override
        returns (bytes4 functionSignature, bool isViewFunction)
    {
        // validateTransfer(address,address,address,uint256)
        return (ICreatorFeeTransferValidator.validateTransfer.selector, true);
        // Selector is 0xcaee23ea as in the OpenSea docs.
    }

    /// @dev Call this from your transfer hook
    function _validateCreatorFeeTransfer(
        address caller,
        address from,
        address to,
        uint256 tokenId
    ) internal view {
        address validator = _transferValidator;
        if (validator != address(0)) {
            ICreatorFeeTransferValidator(validator).validateTransfer(
                caller,
                from,
                to,
                tokenId
            );
        }
    }
}