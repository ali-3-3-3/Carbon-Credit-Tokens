/**
 * @title Deploy Contracts
 * @dev Truffle migration script to deploy multiple contracts with dependencies.
 */

const ERC20 = artifacts.require("ERC20");
const CarbonCreditToken = artifacts.require("CarbonCreditToken");
const Company = artifacts.require("Company");
const ValidatorRegistry = artifacts.require("ValidatorRegistry");
const CarbonCreditMarket = artifacts.require("CarbonCreditMarket");

module.exports = function(deployer) {
    /**
     * @dev Deploy ERC20 token contract.
     */
    deployer.deploy(ERC20)
    .then(() => {
        /**
         * @dev Deploy CarbonCreditToken contract, which depends on ERC20 token contract.
         */
        return deployer.deploy(CarbonCreditToken, ERC20.address);
    })
    .then(() => {
        /**
         * @dev Deploy Company contract.
         */
        return deployer.deploy(Company);
    })
    .then(() => {
        /**
         * @dev Deploy ValidatorRegistry contract.
         */
        return deployer.deploy(ValidatorRegistry);
    })
    .then(() => {
        /**
         * @dev Deploy CarbonCreditMarket contract, which depends on ValidatorRegistry,
         * Company, ERC20, and CarbonCreditToken contracts.
         */
        return deployer.deploy(CarbonCreditMarket, Company.address, CarbonCreditToken.address, ValidatorRegistry.address);
    });
};