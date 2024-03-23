pragma solidity ^0.5.0;

contract ValidatorRegistry {
    mapping(address => bool) public validators;

    event ValidatorAdded(address validator);
    event ValidatorRemoved(address validator);

    constructor() public {
        // Add initial validators during contract deployment, so that they can start validating, no constructor arguments needed
        // Example:
        // validators[0xValidator1] = true;
        // validators[0xValidator2] = true;
    }

    modifier onlyValidator() {
        require(validators[msg.sender], "Only validator can call this function");
        _;
    }

    function addValidator(address _validator) public onlyValidator {
        validators[_validator] = true;
        emit ValidatorAdded(_validator);
    }

    function removeValidator(address _validator) public onlyValidator {
        validators[_validator] = false;
        emit ValidatorRemoved(_validator);
    }

    function isValidator(address _validator) public view returns (bool) {
        return validators[_validator];
    }
}
