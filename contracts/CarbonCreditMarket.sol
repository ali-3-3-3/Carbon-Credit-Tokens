pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ValidatorRegistry.sol";
import "./CarbonCreditToken.sol";
import "./Company.sol";

contract CarbonCreditMarket {
    
    event BuyCredit(address buyer, uint256 amount);
    event ReturnCredits(address seller, uint256 amount);
    event ProjectValidated(uint256 projectId, bool isValid);

    CarbonCreditToken carbonCreditTokenInstance;
    ValidatorRegistry validatorRegistryInstance;
    Company companyInstance;
    address _owner = msg.sender;
    mapping(address => bool) public isVerifier;
    mapping(address => bool) public isSeller;
    mapping(address => uint256[]) public companyProjects; // Mapping of company address to list of projects
    mapping(uint256 => address[]) public projectBuyers; // Mapping of project id to list of buyers
    mapping(address => mapping(uint256 => uint256)) public projectStakes; //mapping of buyer address to project id to amount 
    uint256 public penaltyRate = 30; // Penalty rate (30% for example, not sure if this is the right value)

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

       // Validate a project by a validator, and handle penalty if project is invalid
    function validateProject(address companyAddress, uint256 projectId, bool isValid) public onlyValidator {
        emit ProjectValidated(companyAddress, isValid);
        if (!isValid) {
            handlePenalty(companyAddress, projectId);
        }
    }

       // Handle penalty for a project that fails validation
    function handlePenalty(address companyAddress, uint256 projectId) internal {
        uint256 penaltyAmount = companyInstance.getStakedCredits(projectId) * penaltyRate / 100; // Calculate total penalty amount
        emit Penalty(companyAddress, projectId, penaltyAmount); 
        for(uint256 i = 0; i < projectBuyers[projectId].length; i++) { // Loop through buyers of the project
            address buyer = projectBuyers[projectId][i]; // Get buyer address
            uint256 buyerStake = projectStakes[buyer][projectId]; // Get buyer's stake for the project
            uint256 buyerPenalty = buyerStake * penaltyRate / 100; // Calculate penalty amount for each buyer
          
            projectStakes[buyer][projectId] -= buyerPenalty; // Reduce buyer's stake by penalty amount on the project
            carbonCreditTokenInstance.transfer(buyer, buyerPenalty); // Transfer penalty amount to buyer
        }
    }

    function sell(uint256 _cctAmount, uint256 projectId) public {
        require(_cctAmount > 0, "Invalid amount");
        require(carbonCreditTokenInstance.checkCCT(msg.sender) >= _cctAmount, "Insufficient CCT balance");
        require(companyContractInstance.checkCCTListed(msg.sender, projectId, _cctAmount), "CCT for project overexceeded");

         // Add stake for the project
        require(companyInstance.checkSufficientStakedCredits(_cctAmount, projectId), "Insufficient tokens to stake"); // check if company has enough tokens to stake
        companyInstance.addStake(msg.sender, projectId, _cctAmount); //companyAddress, projectId, cctAmount

        carbonCreditTokenInstance.transferFrom(msg.sender, address(this), _cctAmount); //company, this contract, cctAmount
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

    function buy(uint256 _cctAmount, address companyAddress, uint256 projectId) public payable {
        require(_cctAmount > 0, "Invalid amount");
        require(companyInstance.checkSufficientCCT(companyAddress, projectId, _cctAmount), "Insufficient tokens to buy"); // check if company has enough tokens to sell
        
        carbonCreditTokenInstance.transfer(msg.sender, _cctAmount);
        companyInstance.sellCCT(companyAddress, projectId, _cctAmount); //sell, and check will update cctSold in project
        projectStakes[msg.sender][projectId] += _cctAmount; // add "share" of the project's CCT bought to the buyer

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
