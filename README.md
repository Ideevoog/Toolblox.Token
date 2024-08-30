# Toolblox.Contracts

## Toolblox Base Contracts

This repository contains the base contracts for Toolblox smart-contract workflows.

* TixToken.sol - ERC20 Token with service registration and management. Implements service locator pattern for composable smart-contracts.
* WorkflowBaseCommon.sol - A base contract providing common functionality for workflow-based contracts. It includes methods for managing item IDs, pagination, and foreign key mappings.
* WorkflowBaseUpgradeable.sol - An upgradeable version of the WorkflowBase contract. It inherits from WorkflowBaseCommon and implements the Initializable interface for proper upgradeability.
* UpgradeableServiceDeployer.sol - A contract for deploying and upgrading services using the proxy pattern. It provides functionality for creating new proxies, upgrading existing ones, and managing service deployments.
* IServiceLocator.sol - An interface defining the core functionality for a service locator. It includes methods for registering and retrieving services.
* NonTransferrableERC721.sol - A modified ERC721 token implementation that restricts token transfers. It maintains the standard ERC721 functionality while ensuring that tokens cannot be transferred between addresses after minting.


## Key Features

* Service Registration: TixToken allows for dynamic registration and management of services, enabling a flexible and extensible smart contract ecosystem.
* Upgradeable Contracts: WorkflowBaseUpgradeable and UpgradeableServiceDeployer support contract upgrades, allowing for future improvements and bug fixes.
* Pagination Support: WorkflowBaseCommon includes built-in pagination methods, facilitating efficient data retrieval for large datasets.
* Access Control: Contracts implement role-based access control, ensuring proper permission management.
* Non-Transferrable NFTs: NonTransferrableERC721 provides a unique implementation for use cases where token transfers should be restricted after minting.

## Usage

These contracts serve as a foundation for building complex, upgradeable, and interoperable smart contract systems. Developers can inherit from these base contracts to quickly implement workflow-based applications with built-in service discovery and management capabilities.

## Security

Security is a top priority in the development of these contracts. We follow best practices and industry standards to ensure the safety and integrity of the smart contracts.

### Audits

We are committed to the security and reliability of our smart contracts. The following contracts have undergone thorough audits by reputable third-party security firms:

* WorkflowBaseCommon.sol - Audited twice for enhanced security assurance
* WorkflowBaseUpgradeable.sol - Successfully audited
* NonTransferrableERC721Upgradeable.sol - Successfully audited

The audit reports are available upon request. While these audits significantly increase our confidence in the contracts' security, we always recommend users to exercise caution and conduct their own review before interacting with any smart contract.

## Contributing

We welcome contributions from the community. Please feel free to submit issues, create pull requests, or reach out with suggestions to improve the contracts.

## License

These contracts are released under the MIT License. See the LICENSE file for more details.







