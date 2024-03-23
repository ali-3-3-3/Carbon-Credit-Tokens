pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ValidatorRegistry.sol";

contract CarbonCreditMarket {
    CarbonCreditToken carbonCreditTokenInstance;
    ValidatorRegistry validatorRegistry;
    address _owner;

    mapping(address => bool) public isVerifier;
    mapping(address => bool) public isSeller;

    event BuyCredit(address buyer, uint256 amount);
    event ReturnCredits(address seller, uint256 amount);

      constructor(CarbonCreditToken carbonCreditTokenAddress, ValidatorRegistry validatorRegistryAddress) public {
        carbonCreditTokenInstance = carbonCreditTokenAddress;
        validatorRegistry = validatorRegistryAddress;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only contract owner can call this function");
        _;
    }

    modifier onlyValidator() {
        require(validatorRegistry.isValidator(msg.sender), "Only validator can call this function");
        _;
    }

        // Sell carbon credits
    function sell(uint256 _cctAmount) public {
        require(_cctAmount > 0, "Invalid amount");
        require(carbonCreditTokenInstance.balanceOf(msg.sender) >= _cctAmount, "Insufficient CCT balance");

        carbonCreditTokenInstance.transferFrom(msg.sender, address(this), _cctAmount); //sender, recipient

        emit ReturnCredits(msg.sender, _cctAmount);
    }

     // Buy carbon credits
    function buy(uint256 _cctAmount) public payable{
        require(_cctAmount > 0, "Invalid amount");

        carbonCreditTokenInstance.transfer(msg.sender, _cctAmount);

        emit BuyCredit(msg.sender, _cctAmount);
    }




}
