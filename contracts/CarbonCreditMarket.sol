pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ValidatorRegistry.sol";
import "./CarbonCreditToken.sol";
import "./Company.sol";

contract CarbonCreditMarket {
    CarbonCreditToken carbonCreditTokenInstance;
    ValidatorRegistry validatorRegistryInstance;
    Company companyInstance;
    address _owner;

    mapping(address => bool) public isVerifier;
    mapping(address => bool) public isSeller;
    mapping(address => uint256[]) public companyProjects;
    mapping(uint256 => address[]) public projectBuyers;

    event BuyCredit(address buyer, uint256 amount);
    event ReturnCredits(address seller, uint256 amount);

      constructor(Company companyAddress, CarbonCreditToken carbonCreditTokenAddress, ValidatorRegistry validatorRegistryAddress) public {
        carbonCreditTokenInstance = carbonCreditTokenAddress;
        validatorRegistryInstance = validatorRegistryAddress;
        companyInstance = companyAddress;
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
        companyInstance.listCCT(msg.sender, projectId, _cctAmount); //companyAddress, projectId, cctAmount
        
        // check if project has been added by company
        uint256[] storage projectList = companyProjects[msg.sender];
        bool projectAdded = false;
        for (uint256 i = 0; i < projectList.length; i++) {
            if (projectList[i] == projectId) {
                projectAdded = true; // project already added
            }
        }
        if (!projectAdded) {
            companyProjects[msg.sender].push(projectId); // add project to list of projects
        }

        isSeller[msg.sender] = true; // add address of seller to list of sellers

        emit ReturnCredits(msg.sender, _cctAmount);
    }

     // Buy carbon credits
    function buy(uint256 _cctAmount, address companyAddress, uint256 projectId) public payable {
        require(_cctAmount > 0, "Invalid amount");
        require(companyInstance.checkSufficientCCT(companyAddress, projectId, _cctAmount), "Insufficient tokens to buy");
        
        carbonCreditTokenInstance.transfer(msg.sender, _cctAmount);
        companyInstance.sellCCT(companyAddress, projectId, _cctAmount);

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
