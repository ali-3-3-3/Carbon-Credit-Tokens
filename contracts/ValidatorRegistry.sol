pragma solidity ^0.5.0;

/**
 * @title ValidatorRegistry
 * @dev A contract for managing a registry of validators.
 */
contract ValidatorRegistry {
    // Events
    event ValidatorAdded(address validator);
    event ValidatorRemoved(address validator);

    // State variables
    address _owner = msg.sender;
    mapping(address => bool) public validators;

    /**
     * @dev Modifier to restrict access to only the contract owner.
     */
    modifier onlyContractOwner() {
        require(
            _owner == msg.sender,
            "Only contract owner can call this function"
        );
        _;
    }

    /**
     * @dev Modifier to restrict access to only validators.
     */
    modifier onlyValidator() {
        require(
            validators[msg.sender],
            "Only validator can call this function"
        );
        _;
    }

    /**
     * @dev Adds a new validator to the registry.
     * @param _validator The address of the validator to be added.
     */
    function addValidator(address _validator) public onlyContractOwner {
        validators[_validator] = true;
        emit ValidatorAdded(_validator);
    }

    /**
     * @dev Removes a validator from the registry.
     * @param _validator The address of the validator to be removed.
     */
    function removeValidator(address _validator) public onlyContractOwner {
        validators[_validator] = false;
        emit ValidatorRemoved(_validator);
    }

    /**
     * @dev Checks if an address is a validator.
     * @param _validator The address to be checked.
     * @return A boolean indicating whether the address is a validator.
     */
    function isValidator(address _validator) public view returns (bool) {
        return validators[_validator];
    }
}
