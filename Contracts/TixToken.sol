// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IServiceLocator.sol";
/**
	TixToken acts as a service locator and provides utility to register services.
 **/
contract TixToken is ERC20PresetMinterPauser, Ownable, IServiceLocator {	
	struct ServiceRegistration {
		address destination;
		address owner;
		string spec;
	}
	bytes32 public constant SERVICE_WORKER = keccak256("SERVICE_WORKER");
	bytes32 public constant BALANCER = keccak256("BALANCER");
	mapping(bytes32 => ServiceRegistration) public repository;
	uint public _registrationFee;
	uint public _counter;

	constructor(uint256 initialSupply) ERC20PresetMinterPauser("Toolblox Token", "TIX") {
		address sender = _msgSender();
		_setupRole(SERVICE_WORKER, sender);
		_setupRole(BALANCER, sender);
		_mint(sender, initialSupply);
	}

	function setRegistrationFee(uint fee) public {
		require(hasRole(BALANCER, _msgSender()), "TixToken: must have balancer role to update fees");		
		_registrationFee = fee;
	}

	function registerService(string calldata name, string calldata spec, bytes calldata code) override public whenNotPaused returns (address)
	{
		address sender = _msgSender();
		if (_registrationFee > 0)
		{
			//transfer fee to owner (buyback) or burn if no owner.
			require(balanceOf(sender) >= _registrationFee, "TixToken: Not enough TIX to register a service");
			_transfer(sender, owner(), _registrationFee);
		}
		bytes32 nameHash = keccak256(abi.encodePacked(name));
		address currentOwner = repository[nameHash].owner;
		require(currentOwner == address(0) || currentOwner == sender, "TixToken: Only owner can update a service registration");
		
		//pre-compute the destination address
		_counter = _counter + 1;
		address predictedAddress = computeAddress(code, keccak256(abi.encodePacked(_counter, sender)));

		//book service address to the sender
		_registerService(nameHash, predictedAddress, spec, sender);

		//deploy and check if address is the same as precomputed
		address destination = deploy(code, keccak256(abi.encodePacked(_counter, sender)));
		require(predictedAddress == destination, "Deployed address mismatch");

		//call setOwner() init method on the service to transfer ownership to sender
		(bool success, ) = destination.call(abi.encodeWithSignature("setOwner(address)", sender));
		require(success, "Owner cannot be set");
		return destination;
	}

	function computeAddress(bytes memory _initCode, bytes32 _salt) internal view returns (address) {
		bytes32 codeHash = keccak256(_initCode);
		bytes32 rawAddress = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, codeHash));
		return address(uint160(uint(rawAddress)));
	}
	
	function deploy(bytes memory _initCode, bytes32 _salt) private returns (address createdContract)
    {
        assembly {
            createdContract := create2(0, add(_initCode, 0x20), mload(_initCode), _salt)
			if iszero(extcodesize(createdContract)) {
				revert(0, 0)
			}
        }
    }

	function _registerService(bytes32 name, address destination, string memory spec, address owner) private
	{
		repository[name] = ServiceRegistration(destination, owner, spec);
		emit ServiceRegistered(name, destination, spec);
	}

	function registerServices(bytes32[] calldata names, ServiceRegistration[] calldata destinations) public {
		require(hasRole(SERVICE_WORKER, _msgSender()), "TixToken: must have service worker role to register services");
		require(names.length == destinations.length, "Input lengths must match");
		for (uint i = 0; i < names.length; i++) {
			bytes32 name = names[i];
			ServiceRegistration calldata destination = destinations[i];
			_registerService(name, destination.destination, destination.spec, destination.owner);
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

	event ServiceRegistered(bytes32 _name, address _destination, string _spec);
}