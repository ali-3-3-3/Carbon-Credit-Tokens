pragma solidity ^0.5.0;

import "./ERC20.sol";

contract CarbonCreditToken {
    ERC20 erc20Contract;
    address owner;

    constructor() public {
        ERC20 e = new ERC20();
        erc20Contract = e;
        owner = msg.sender;
    }
    /**
    * @dev Function to give CCT to the recipient for a given wei amount
    * @param recipient address of the recipient that wants to buy the DT
    * @param weiAmt uint256 amount indicating the amount of wei that was passed
    * @return A uint256 representing the amount of DT bought by the msg.sender.
    */
    function getCCT(address recipient, uint256 amtOfCCT)
        public
        returns (uint256)
    {
        erc20Contract.mint(recipient, amtOfCCT);
        return amt; 
    }
    // function getCCT(address recipient, uint256 weiAmt)
    //     public
    //     returns (uint256)
    // {
    //     //1 ether = 1 CCT
    //     uint256 amt = weiAmt / (1000000000000000000); // Convert weiAmt to Carbon Credit Token
    //     erc20Contract.mint(recipient, amt);
    //     return amt; 
    // }
    /**
    * @dev Function to check the amount of CCT the msg.sender has
    * @param ad address of the recipient that wants to check their DT
    * @return A uint256 representing the amount of DT owned by the msg.sender.
    */
   
    function checkCCT(address ad) public view returns (uint256) {
        uint256 credit = erc20Contract.balanceOf(ad);
        return credit; 
    }
    /**
    * @dev Function to transfer the credit from the owner to the recipient
    * @param recipient address of the recipient that will gain in DT
    * @param amt uint256 aount of DT to transfer
    */
    function transferCCT(address recipient, uint256 amt) public {
        // Transfers from tx.origin to receipient
        erc20Contract.transfer(recipient, amt);
    }

    function transferCCTFrom(address sender, address recipient, uint256 amt) public {
        // Transfers from tx.origin to receipient
        erc20Contract.transferFrom(sender,recipient,amt);
    }

    function destroyCCT(address tokenOwner, uint256 tokenAmount) public returns (uint256) {
        require(checkCCT(tokenOwner) >= tokenAmount, "Insufficient BT to burn");
        erc20Contract.burn(tokenOwner, tokenAmount);
        return tokenAmount;
    }
}
