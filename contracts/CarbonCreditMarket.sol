pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ValidatorRegistry.sol";
import "./CarbonCreditToken.sol";
import "./CompanyContract.sol";

contract CarbonCreditMarket {
    CarbonCreditToken carbonCreditTokenInstance;
    ValidatorRegistry validatorRegistryInstance;
    CompanyContract companyContractInstance;
    address _owner;

    mapping(address => bool) public isVerifier;
    mapping(address => bool) public isSeller;
    mapping(address => uint256[]) public companyProjects;
    mapping(uint256 => address[]) public projectBuyers;

    event BuyCredit(address buyer, uint256 amount);
    event ReturnCredits(address seller, uint256 amount);

      constructor(CompanyContract companyContractAddress, CarbonCreditToken carbonCreditTokenAddress, ValidatorRegistry validatorRegistryAddress) public {
        carbonCreditTokenInstance = carbonCreditTokenAddress;
        validatorRegistryInstance = validatorRegistryAddress;
        companyContractInstance = companyContractAddress;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only contract owner can call this function");
        _;
    }

    modifier onlyValidator() {
        require(validatorRegistryInstance.isValidator(msg.sender), "Only validator can call this function");
        _;
    }

        // Sell carbon credits
    function sell(uint256 _cctAmount, uint256 projectId) public {
        require(_cctAmount > 0, "Invalid amount");
        require(carbonCreditTokenInstance.checkCCT(msg.sender) >= _cctAmount, "Insufficient CCT balance");
        require(companyContractInstance.checkCCTListed(msg.sender, projectId, _cctAmount), "CCT for project overexceeded");

        carbonCreditTokenInstance.transferFrom(msg.sender, address(this), _cctAmount); //sender, recipient
        companyContractInstance.listCCT(msg.sender, projectId, _cctAmount);
        
        // check if project has been added by company
        uint256[] storage projectList = companyProjects[msg.sender];
        bool projectAdded = false;
        for (uint256 i = 0; i < projectList.length; i++) {
            if (projectList[i] == projectId) {
                projectAdded = true;
            }
        }
        if (!projectAdded) {
            companyProjects[msg.sender].push(projectId);
        }

        isSeller[msg.sender] = true;

        emit ReturnCredits(msg.sender, _cctAmount);
    }

     // Buy carbon credits
    function buy(uint256 _cctAmount, address companyAddress, uint256 projectId) public payable {
        require(_cctAmount > 0, "Invalid amount");
        require(companyContractInstance.checkSufficientCCT(companyAddress, projectId, _cctAmount), "Insufficient tokens to buy");
        
        carbonCreditTokenInstance.transfer(msg.sender, _cctAmount);
        companyContractInstance.sellCCT(companyAddress, projectId, _cctAmount);

        address[] storage buyerList = projectBuyers[projectId];
        bool buyerAdded = false;
        for (uint256 i = 0; i < buyerList.length; i++) {
            if (buyerList[i] == msg.sender) {
                buyerAdded = true;
            }
        }
        if (!buyerAdded) {
            projectBuyers[projectId].push(msg.sender);
        }
        
        emit BuyCredit(msg.sender, _cctAmount);
    }

}
