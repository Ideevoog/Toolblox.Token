// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "./ERC20PresetMinterPauser.sol";
import "./IServiceLocator.sol";

contract TbxToken is ERC20PresetMinterPauser, IServiceLocator {
    bytes32 public constant SERVICE_WORKER = keccak256("SERVICE_WORKER");
    mapping(bytes32 => address) public repository;
    mapping(address => address) public schedulers;

    constructor(uint256 initialSupply) ERC20PresetMinterPauser("Toolblox Token", "TBX") {
        _setupRole(SERVICE_WORKER, _msgSender());
        _mint(_msgSender(), initialSupply);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function registerService(bytes32[] calldata names, address[] calldata destinations) public {
        require(hasRole(SERVICE_WORKER, _msgSender()), "TbxToken: must have service worker role to register services");
        require(names.length == destinations.length, "Input lengths must match");

        for (uint i = 0; i < names.length; i++) {
            bytes32 name = names[i];
            address destination = destinations[i];
            repository[name] = destination;
            emit ServiceRegistered(name, destination);
        }
    }

    function registerScheduler(address[] calldata services, address[] calldata destinations) public {
        require(hasRole(SERVICE_WORKER, _msgSender()), "TbxToken: must have service worker role to register schedulers");
        require(services.length == destinations.length, "Input lengths must match");

        for (uint i = 0; i < services.length; i++) {
            address service = services[i];
            address destination = destinations[i];
            schedulers[service] = destination;
            emit SchedulerRegistered(service, destination);
        }
    }

    /* ========== VIEWS ========== */

    function areServicesRegistered(bytes32[] calldata names, address[] calldata destinations) external view returns (bool) {
        for (uint i = 0; i < names.length; i++) {
            if (repository[names[i]] != destinations[i]) {
                return false;
            }
        }
        return true;
    }

    function areSchedulersRegistered(address[] calldata services, address[] calldata destinations) external view returns (bool) {
        for (uint i = 0; i < services.length; i++) {
            if (schedulers[services[i]] != destinations[i]) {
                return false;
            }
        }
        return true;
    }

    function getService(bytes32 name) external view returns (address) {
        return repository[name];
    }

    function getScheduler(address service) external view returns (address) {
        return schedulers[service];
    }

    /* ========== EVENTS ========== */

    event ServiceRegistered(bytes32 name, address destination);
    event SchedulerRegistered(address service, address scheduler);
}