pragma solidity ^0.5.0;

contract ValidatorRegistry {

    event ValidatorAdded(address validator);
    event ValidatorRemoved(address validator);

    address _owner = msg.sender;
    mapping(address => bool) public validators;

    constructor() public {
        marketContractAddress = msg.sender;
    }

    modifier onlyContractOwner() {
        require(_owner == msg.sender);
        _;
    }

    modifier onlyValidator() {
        require(
            validators[msg.sender],
            "Only validator can call this function"
        );
        _;
    }

    function addValidator(address _validator) public onlyContractOwner() { // only contract owner can add validators
        validators[_validator] = true;
        emit ValidatorAdded(_validator);
    }

    function removeValidator(address _validator) public onlyContractOwner() { // only contract owner can remove validators
        validators[_validator] = false;
        emit ValidatorRemoved(_validator);
    }

    function isValidator(address _validator) public view returns (bool) { // check if address is a validator
        return validators[_validator];
    }
}
