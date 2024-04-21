pragma solidity ^0.5.0;

import "./ERC20.sol";

/**
 * @title CarbonCreditToken
 * @dev A token contract representing Carbon Credit Tokens.
 */
contract CarbonCreditToken {
    // Events
    event CCTMinted(address recipient, uint256 amt);

    // State variables
    ERC20 erc20Contract;
    address owner = msg.sender;

    constructor(address _erc20TokenAddress) public {
        ERC20 e = new ERC20();
        erc20Contract = e;
        owner = msg.sender;
    }

    /**
     * @dev Function to mint Carbon Credit Tokens (CCT) to the recipient.
     * @param recipient Address of the recipient that will receive the CCT.
     * @param amtOfCCT Amount of CCT to mint.
     * @return The amount of CCT minted.
     */
    function getCCT(
        address recipient,
        uint256 amtOfCCT
    ) public payable returns (uint256) {
        require(amtOfCCT > 0, "Amount must be greater than zero");
        //1 ether = 1 CCT, no need to convert weiAmt to CCT
        erc20Contract.mint(recipient, amtOfCCT);
        emit CCTMinted(recipient, amtOfCCT);
        return amtOfCCT;
    }

    /**
     * @dev Function to check the credit of the owner
     * @param ad address of the owner
     * @return uint256 credit of the owner
     */
    function checkCCT(address ad) public view returns (uint256) {
        uint256 credit = erc20Contract.balanceOf(ad);
        return credit;
    }

    /**
     * @dev Function to transfer CCT from the owner to the recipient
     * @param recipient address of the recipient
     * @param amt amount of CCT to transfer
     */
    function transferCCT(address recipient, uint256 amt) public {
        // Transfers from tx.origin to receipient
        erc20Contract.transfer(recipient, amt);
    }

    /**
     * @dev Function to transfer CCT from the owner to the recipient
     * @param sender address of the sender
     * @param recipient address of the recipient
     * @param amt amount of CCT to transfer
     */
    function transferCCTFrom(
        address sender,
        address recipient,
        uint256 amt
    ) public {
        // Transfers from tx.origin to receipient
        erc20Contract.transferFrom(sender, recipient, amt);
    }

    /**
     * @dev Function to destroy CCT
     * @param tokenOwner address of the owner
     * @param tokenAmount amount of CCT to destroy
     * @return uint256 amount of CCT destroyed
     */
    function destroyCCT(
        address tokenOwner,
        uint256 tokenAmount
    ) public returns (uint256) {
        require(
            checkCCT(tokenOwner) >= tokenAmount,
            "Insufficient CCT to burn"
        );
        erc20Contract.burn(tokenOwner, tokenAmount);
        return tokenAmount;
    }
}
