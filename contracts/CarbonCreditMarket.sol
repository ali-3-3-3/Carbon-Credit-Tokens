pragma solidity ^0.5.0;

import "./ValidatorRegistry.sol";
import "./CarbonCreditToken.sol";
import "./Company.sol";

/**
 * @title CarbonCreditMarket
 * @dev This contract represents a carbon credit market where users can buy and sell carbon credits.
 */
contract CarbonCreditMarket {
    // Events
    event BuyCredit(address buyer, uint256 amount);
    event ReturnCredits(address seller, uint256 amount);
    event ProjectValidated(
        address companyAddress,
        uint256 projectId,
        bool isValid
    );
    event Penalty(address companyAddress, uint256 projectId);

    // State variables
    CarbonCreditToken carbonCreditTokenInstance;
    ValidatorRegistry validatorRegistryInstance;
    Company companyInstance;
    uint256 cctBank = 0;
    address _owner = msg.sender;
    mapping(address => bool) public isVerifier;
    mapping(address => bool) public isSeller;
    mapping(address => uint256[]) public companyProjects; // Mapping of company address to list of projects
    mapping(uint256 => address[]) public projectBuyers; // Mapping of project id to list of buyers
    mapping(address => mapping(uint256 => uint256)) public projectStakes; //mapping of buyer address to project id to amount
    mapping(address => mapping(uint256 => uint256)) public relisted; // Mapping of company address to projectId to their ccts sold, due to listing project that have been validated

    // Constructor
    constructor(
        Company companyAddress,
        CarbonCreditToken carbonCreditTokenAddress,
        ValidatorRegistry validatorRegistryAddress
    ) public {
        carbonCreditTokenInstance = carbonCreditTokenAddress;
        validatorRegistryInstance = validatorRegistryAddress;
        companyInstance = companyAddress;
    }

    /**
     * @dev Modifier that allows only the contract owner to call the function.
     */
    modifier onlyOwner() {
        require(
            msg.sender == _owner,
            "Only contract owner can call this function"
        );
        _;
    }

    /**
     * @dev Modifier that restricts the execution of a function to only be called by a registered validator.
     */
    modifier onlyValidator() {
        require(
            validatorRegistryInstance.isValidator(msg.sender),
            "Only validator can call this function"
        );
        _;
    }

    /**
     * @dev Allows the contract owner to withdraw a specified amount of Ether from the contract balance and transfer it to a specified company address.
     * @param companyAddress The address of the company to which the Ether will be transferred.
     * @param amount The amount of Ether to be withdrawn and transferred.
     * @notice Only the contract owner can call this function.
     * @dev Throws an error if the specified amount is greater than the contract balance.
     */
    // function withdrawEther(
    //     address payable companyAddress,
    //     uint256 amount
    // ) public onlyOwner {
    //     require(
    //         amount <= address(this).balance,
    //         "Insufficient contract balance"
    //     );
    //     companyAddress.transfer(amount);
    // }
        function withdrawEther(
        address payable companyAddress,
        uint256 amount
    ) public onlyValidator() {
        require(
            amount <= address(this).balance,
            "Insufficient contract balance"
        );
        companyAddress.transfer(amount);
    }

    /**
     * @dev Check whether or not a company has provided enough Ether to stake for a project (for penalty purposes).
     * @param _cctAmount The amount of cct they wish to sell from the project.
     * @param etherAmount The amount of Ether supplied.
     */
    function checkSufficientStake(uint256 _cctAmount, uint256 etherAmount)
        public pure
        returns (bool)
    {
        uint256 stakedAmount = (_cctAmount * 13) / 10;
        return etherAmount >= stakedAmount;
    }

    /**
     * @dev Validate a project by a validator, and handle penalty if project is invalid, otherwise transfer CCT to buyers.
     * @param companyAddress The address of the company.
     * @param projectId The ID of the project.
     * @param isValid A boolean indicating whether the project is valid or not.
     * @param actualCCT The actual CCT (Carbon Credit Token) amount for the project.
     * @notice This function can only be called by a validator.
     */
    function validateProject(
        address payable companyAddress,
        uint256 projectId,
        bool isValid,
        uint256 actualCCT
    ) public onlyValidator {
        // Validate a project by a validator, and handle penalty if project is invalid, otherwise transfer CCT to buyers
        require(
            companyInstance.getProjectState(projectId) !=
                Company.ProjectState.completed,
            "Project completed, cannot be validated again"
        ); // Check if project is completed, cannot be validated again
        companyInstance.setProjectStateComplete(projectId); // Set project state to completed
        emit ProjectValidated(companyAddress, projectId, isValid); // Emit event for project validation
        if (!isValid) {
            // Project is invalid
            handlePenalty(companyAddress, projectId, actualCCT);
        } else {
            // Project is valid
            //Transfer CCT to buyers
            address[] storage buyers = projectBuyers[projectId];
            for (uint256 i = 0; i < buyers.length; i++) { // Loop through buyers of the project 
                address buyer = buyers[i];
                uint256 buyerStake = projectStakes[buyer][projectId]; // Get buyer's stake for the project
                carbonCreditTokenInstance.getCCT(buyer, buyerStake); // Mint CCT to buyer
                projectStakes[buyer][projectId] = 0; // Reset buyer's stake to 0
            }
            // Project's CCTAmount left is returned to project
            uint256 cctAmountUnsold = companyInstance.getProjectcctAmount(
                projectId
            );
            companyInstance.setProjectcctAmount(projectId, cctAmountUnsold); // Update project's CCT amount, project can be resold with remaining CCT by seller
            // Return penalty + profit to seller
            uint256 stakedCredits = companyInstance.getStakedCredits( // Get staked credits (sellers stake 130% (of ether)) for the project
                    companyAddress,
                    projectId
                );
            uint256 returnPenalty = (stakedCredits * 3) / 1000; // Calculate penalty amount to return to seller
            withdrawEther(
                companyAddress,
                returnPenalty + companyInstance.getCCTSold(projectId)
            ); // Return penalty amount and profit back to seller
        }
    }

    /**
     * @dev Handles penalty for a project that fails validation.
     * @param companyAddress The address of the company associated with the project.
     * @param projectId The ID of the project.
     * @param actualCCT The actual Carbon Credit Tokens (CCT) generated by the project.
     *
     * Emits a `Penalty` event for the failed project.
     * Loops through the buyers of the project and performs the following actions:
     * - If the actual CCT is greater than or equal to the CCT sold, mints the actual CCT to the buyer.
     * - If the actual CCT is less than the CCT sold, calculates the actual CCT received by the buyer,
     *   mints the actual CCT to the buyer, and transfers the compensation amount to the buyer.
     * Transfers the profits to the company and keeps the penalty amount.
     * Resets the buyer's stake to 0.
     */
    function handlePenalty(
        address payable companyAddress,
        uint256 projectId,
        uint256 actualCCT // Actual CCT generated by the project
    ) internal {
        // Handle penalty for a project that fails validation
        emit Penalty(companyAddress, projectId);
        for (uint256 i = 0; i < projectBuyers[projectId].length; i++) {
            // Loop through buyers of the project
            address buyer = projectBuyers[projectId][i]; // Get buyer address
            address payable buyerPayable;
            assembly {
                buyerPayable := buyer
            } //make buyer payable
            uint256 buyerStake = projectStakes[buyer][projectId]; // Get buyer's stake for the project
            if (actualCCT >= companyInstance.getCCTSold(projectId)) {
                // If actual CCT is greater than or equal to CCT sold
                carbonCreditTokenInstance.getCCT(buyer, buyerStake); // Mint actual CCT to buyer, penalty and profits kept by market
                actualCCT -= buyerStake; // Reduce actual CCT by buyer's stake
                companyInstance.setProjectcctAmount(projectId, actualCCT); // Update project's CCT amount, project can be resold with remaining CCT by seller
            } else {
                // If actual CCT is less than CCT sold
                uint256 actualBuyerCCT = (buyerStake * actualCCT) /
                    companyInstance.getCCTSold(projectId); // Calculate actual CCT received by the buyer
                carbonCreditTokenInstance.getCCT(buyer, actualBuyerCCT); // Mint actual CCT to buyer
                uint256 buyerCompensation = buyerStake - actualBuyerCCT; // Calculate compensation amount to buyer
                withdrawEther(buyerPayable, buyerCompensation); // Transfer compensation amount to buyer
            }
            withdrawEther(
                companyAddress,
                companyInstance.getCCTSold(projectId)
            ); // Transfer profits to company, penalty kept by market
            projectStakes[buyer][projectId] = 0; // Reset buyer's stake to 0
        }
    }

    /**
     * @dev Allows a seller to list and sell carbon credit tokens (CCT) for a specific project.
     * @param _cctAmount The amount of CCT to be sold.
     * @param projectId The ID of the project for which the CCT is being sold.
     *  The seller must have enough CCT listed for the project and sufficient CCT balance to sell.
     *  If the project is completed, the CCT is transferred to the market and the seller receives ether.
     *  If the project is ongoing, the seller must stake 130% of the CCT amount in ether.
     *  The seller's ether is transferred to the contract for staking, with 30% being a penalty.
     *  The CCT is listed and the project is added to the seller's list of projects.
     *  Emits a `ReturnCredits` event with the seller's address and the amount of CCT sold.
     */

    function sell(uint256 _cctAmount, uint256 projectId) public payable {
        //seller lists cct for sale anytime during project
        require(_cctAmount > 0, "Invalid amount");
        require(
            companyInstance.checkCCTListed(msg.sender, projectId, _cctAmount),
            "CCT for project overexceeded"
        ); // Check if cctListed is <= to cctAmount, must have enuf cctAmount in project to sell
        require(
            companyInstance.checkSufficientCCT(
                msg.sender,
                projectId,
                _cctAmount
            ),
            "Insufficient CCT to sell"
        ); // Check if seller has enough cct to sell in project, especially after sold ccts from this project before

        if (
            companyInstance.getProjectState(projectId) ==
            Company.ProjectState.completed
        ) {
            // if project is completed
            cctBank += _cctAmount; // add CCT to bank
            relisted[msg.sender][projectId] += _cctAmount; // add cct from company to relisted
            companyInstance.listCCT(msg.sender, projectId, _cctAmount); //update cctListed in project
            carbonCreditTokenInstance.transferCCT(address(this), _cctAmount); // transfer CCT to market, from seller
        } else {
            //check if company has enough ether to stake only if project is ongoing
            require(
                checkSufficientStake(
                _cctAmount,
                msg.value
                ),
                "Insufficient ether to stake"
            ); // Seller has to transfer 130% ether to contract for staking, 30% is penalty. Ether is transferred as msg.value is called.
            uint256 stakedAmount = (_cctAmount * 13) / 10; // sellers stake 130% (of ether), 30% is penalty
            companyInstance.stakeCredits(msg.sender, projectId, stakedAmount); //stake credits
            companyInstance.listCCT(msg.sender, projectId, _cctAmount); //update cctListed in project

            //Check if project has been listed by company (if company has sold tokens from project before)
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
        }
        emit ReturnCredits(msg.sender, _cctAmount);
    }

    /**
     * @dev Allows a buyer to purchase carbon credits from a project.
     * @param _cctAmount The amount of carbon credits to purchase.
     * @param companyAddress The address of the company selling the carbon credits.
     * @param projectId The ID of the project from which to purchase the carbon credits.
     */
    function buy(
        uint256 _cctAmount,
        address payable companyAddress,
        uint256 projectId
    ) public payable {
        // UI: has to click on a project to buy -- hence project has to be listed for this function to be called; no checks needed
        require(_cctAmount > 0, "Invalid amount");
        require(msg.value == _cctAmount * 1 ether, "Invalid amount"); //ensure buyer gave correct amount of ether to contract for buying
        require(
            companyInstance.checkSufficientCCT(
                companyAddress,
                projectId,
                _cctAmount
            ),
            "Insufficient CCT in project to buy"
        ); // Check if buyer has enough cct to buy in project

         companyInstance.sellCCT(companyAddress, projectId, _cctAmount); // increase cctSold in project by _cctAmount

        if (
            companyInstance.getProjectState(projectId) ==
            Company.ProjectState.completed
        ) { 
            require(
                _cctAmount <= relisted[companyAddress][projectId],
                "Insuffucient CCT to buy"
            );
            cctBank -= _cctAmount; // deduct CCT from bank
            relisted[companyAddress][projectId] -= _cctAmount; // deduct CCT from company's relisted CCT
            carbonCreditTokenInstance.transferCCT(msg.sender, _cctAmount); // transfer CCT to buyer from market
            companyAddress.transfer(msg.value); // transfer ether to company
        } else {
            projectStakes[msg.sender][projectId] += _cctAmount; // add "share" of the project's CCT bought to the buyer

            // check if buyer has bought from project before
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
    function getProjectBuyers(uint256 projectId) public view returns (address[] memory) {
    return projectBuyers[projectId];
}
}
