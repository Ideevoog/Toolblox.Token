// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "./IServiceLocator.sol";
/**
	TixToken acts as a service locator and provides utility to register services.
 **/
contract TixToken is Context, AccessControlEnumerable, ERC20Burnable, ERC20Pausable, Ownable2Step, IServiceLocator {	
	struct ServiceRegistration {
		address destination;
		address owner;
		string spec;
	}
	bytes32 public constant SERVICE_WORKER = keccak256("SERVICE_WORKER");
	bytes32 public constant BALANCER = keccak256("BALANCER");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
	mapping(bytes32 => ServiceRegistration) public repository;
	uint public _registrationFee;
	uint public _counter;
    bool public _direction;

	constructor(uint256 initialSupply) ERC20("Toolblox Token", "TIX") Ownable(_msgSender()) {
		address sender = _msgSender();
		_grantRole(SERVICE_WORKER, sender);
		_grantRole(BALANCER, sender);
		_grantRole(MINTER_ROLE, sender);
		_grantRole(PAUSER_ROLE, sender);
		_mint(sender, initialSupply);
	}

	function setRegistrationFee(uint fee, bool direction) public {
		require(hasRole(BALANCER, _msgSender()), "TixToken: must have balancer role to update fees");		
		_registrationFee = fee;
        _direction = direction;
	}
	
	function registerService(string calldata name, string calldata spec, address destination, address newOwner) override public whenNotPaused
	{
		require(newOwner != address(0), "TixToken: Invalid owner requested");
		require(destination != address(0), "TixToken: Invalid owner requested");
		address sender = _msgSender();
		bool senderIsService = hasRole(SERVICE_WORKER, sender);

		//the registrant of the request is either the delegated newOwner (if the sender is service worker), or just the msg.sender
		address registrant = senderIsService ? newOwner : sender;

		bytes32 nameHash = keccak256(abi.encodePacked(name));
		address currentOwner = repository[nameHash].owner;

		if (currentOwner == address(0))
		{
			//first time registration
			if (_registrationFee > 0)
			{
				//if no owner, means first registration, requires fee
				//method: transfer fee back to owner() (buyback) or burn if owner is address(0).
				require(balanceOf(registrant) >= _registrationFee, "TixToken: Not enough TIX to register a service");
                if (_direction)
                {
                    _transfer(owner(), registrant, _registrationFee);
                }else{
                    _transfer(registrant, owner(), _registrationFee);
                }
			}
		}
		else{
			//update available only to current owner
			require(currentOwner == registrant, "TixToken: Must own the service or to update");
		}

		//book service address to the newOwner
		_registerService(nameHash, destination, spec, newOwner);
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

	function _registerService(bytes32 name, address destination, string memory spec, address owner) private
	{
		repository[name] = ServiceRegistration(destination, owner, spec);
		emit ServiceRegistered(name, destination, spec);
	}

    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "TixToken: must have minter role to mint");
        _mint(to, amount);
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "TixToken: must have pauser role to pause");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "TixToken: must have pauser role to unpause");
        _unpause();
    }

	function _update(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable) {
		super._update(from, to, amount);
	}

	event ServiceRegistered(bytes32 _name, address _destination, string _spec);
}