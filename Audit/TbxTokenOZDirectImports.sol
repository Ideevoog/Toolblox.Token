// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/access/Ownable.sol";
import "./IServiceLocator.sol";

contract TixToken is ERC20PresetMinterPauser, Ownable, IServiceLocator {	
	struct ServiceRegistration {
		address destination;
		address owner;
	}

	bytes32 public constant SERVICE_WORKER = keccak256("SERVICE_WORKER");
	bytes32 public constant BALANCER = keccak256("BALANCER");
	mapping(bytes32 => ServiceRegistration) public repository;
	uint public _registrationFee;
	uint public _counter;

	constructor(uint256 initialSupply) ERC20PresetMinterPauser("Toolblox Token", "TIX") {
		_setupRole(SERVICE_WORKER, _msgSender());
		_setupRole(BALANCER, _msgSender());
		_mint(_msgSender(), initialSupply);
	}

	function setRegistrationFee(uint fee) public {
		require(hasRole(BALANCER, _msgSender()), "TixToken: must have balancer role to update fees");		
		_registrationFee = fee;
	}

	function registerService(string calldata name, bytes calldata code) override public returns (address)
	{
		address sender = _msgSender();
		if (_registrationFee > 0)
		{
			require(balanceOf(sender) >= _registrationFee, "TixToken: Not enough TIX to register a service");
			_transfer(sender, owner(), _registrationFee);
		}
		bytes32 nameHash = keccak256(abi.encodePacked(name));
		address currentOwner = repository[nameHash].owner;
		require(currentOwner == address(0) || currentOwner == sender, "TixToken: Only owner can update a service registration");
		
		_counter = _counter + 1;
		address destination = deploy(code, keccak256(abi.encodePacked(_counter, sender)));
		_registerService(nameHash, destination, sender);
		return destination;
	}
	
	function deploy(bytes memory _initCode, bytes32 _salt)
        private
        returns (address createdContract)
    {
        assembly {
            createdContract := create2(0, add(_initCode, 0x20), mload(_initCode), _salt)
			if iszero(extcodesize(createdContract)) {
				revert(0, 0)
			}
        }
		(bool success, ) = createdContract.call(abi.encodeWithSignature("setOwner(address)", _msgSender()));
		require(success, "Owner cannot be set");
    }

	function _registerService(bytes32 name, address destination, address owner) private
	{
		repository[name] = ServiceRegistration(destination, owner);
		emit ServiceRegistered(name, destination);
	}

	function registerServices(bytes32[] calldata names, ServiceRegistration[] calldata destinations) public {
		require(hasRole(SERVICE_WORKER, _msgSender()), "TixToken: must have service worker role to register services");
		require(names.length == destinations.length, "Input lengths must match");
		for (uint i = 0; i < names.length; i++) {
			bytes32 name = names[i];
			ServiceRegistration calldata destination = destinations[i];
			_registerService(name, destination.destination, destination.owner);
		}
	}

	function areServicesRegistered(bytes32[] calldata names, address[] calldata destinations) external view returns (bool) {
		for (uint i = 0; i < names.length; i++) {
			if (repository[names[i]].destination != destinations[i]) {
				return false;
			}
		}
		return true;
	}

	function getService(bytes32 name) override external view returns (address) {
		return repository[name].destination;
	}

	event ServiceRegistered(bytes32 _name, address _destination);
}
