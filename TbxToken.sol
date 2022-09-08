// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "./ERC20PresetMinterPauser.sol";
import "./Ownable2Step.sol";
import "./IServiceLocator.sol";

contract TbxToken is ERC20PresetMinterPauser, Ownable2Step, IServiceLocator {
    bytes32 public constant SERVICE_WORKER = keccak256("SERVICE_WORKER");
    bytes32 public constant BALANCER = keccak256("BALANCER");
    mapping(bytes32 => address) public repository;
    mapping(address => address) public schedulers;
    uint public _registrationFee;
    uint public _schedulerFee;

    constructor(uint256 initialSupply) ERC20PresetMinterPauser("Toolblox Token", "TBX") {
        _setupRole(SERVICE_WORKER, _msgSender());
        _mint(_msgSender(), initialSupply);
    }

    function setRegistrationFee(uint fee) public {
        _setupRole(BALANCER, _msgSender());
        _registrationFee = fee;
    }

    function setSchedulerFee(uint fee) public {
        _setupRole(BALANCER, _msgSender());
        _schedulerFee = fee;
    }

    function registerService(bytes32 name, address destination) public
    {
        if (_registrationFee > 0)
        {
            _burn(_msgSender(), _registrationFee);
            //_transfer(_msgSender(), _owner, _registrationFee);
        }
        repository[name] = destination;
        emit ServiceRegistered(name, destination);
    }

    function registerServices(bytes32[] calldata names, address[] calldata destinations) public {
        require(hasRole(SERVICE_WORKER, _msgSender()), "TbxToken: must have service worker role to register services");
        require(names.length == destinations.length, "Input lengths must match");
        for (uint i = 0; i < names.length; i++) {
            bytes32 name = names[i];
            address destination = destinations[i];
            registerService(name, destination);
        }
    }

    function registerSchedulers(address[] calldata services, address[] calldata destinations) public {
        require(hasRole(SERVICE_WORKER, _msgSender()), "TbxToken: must have service worker role to register schedulers");
        require(services.length == destinations.length, "Input lengths must match");
        for (uint i = 0; i < services.length; i++) {
            address service = services[i];
            address destination = destinations[i];
            schedulers[service] = destination;
            emit SchedulerRegistered(service, destination);
        }
    }

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

    function getService(bytes32 name) override external view returns (address) {
        return repository[name];
    }

    function getScheduler(address service) override external view returns (address) {
        return schedulers[service];
    }

    event ServiceRegistered(bytes32 name, address destination);
    event SchedulerRegistered(address service, address scheduler);
}