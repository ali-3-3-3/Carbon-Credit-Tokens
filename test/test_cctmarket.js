const _deploy_contracts = require("../migrations/5_deploy_contracts");
var assert = require("assert");
var truffleAssert = require("truffle-assertions");

var CarbonCreditMarket = artifacts.require("CarbonCreditMarket");
var Company = artifacts.require("Company");
var ValidatorRegistry = artifacts.require("ValidatorRegistry");

const oneEth = 1000000000000000000; // 1 eth

contract("CarbonCreditMarket", function (accounts) {
  let companyInstance = null;
  const owner = accounts[0]; // contract owner
  const companyAddress = accounts[1]; // company address

  before(async () => {
    validatorRegistryInstance = await ValidatorRegistry.deployed();
    companyInstance = await Company.deployed();
    carbonCreditMarketInstance = await CarbonCreditMarket.deployed();
  });
  console.log("Testing CarbonCreditMarket contract");

  it("Should add a company", async () => {
    await companyInstance.addCompany(companyAddress, "Test Company", {
      from: owner,
    });
    const companyInstanceData = await companyInstance.getCompanyName(
      companyAddress
    );
    assert(companyInstanceData === "Test Company");
  });

  it("Should not add a company if not owner", async () => {
    try {
      await companyInstance.addCompany(companyAddress, "Test Company", {
        from: companyAddress,
      });
    } catch (e) {
      assert(
        e.message.includes("Only contract owner can execute this function")
      );
      return;
    }
    assert(false);
  });

  it("Should add a project", async () => {
    await companyInstance.addProject(
      "Test Project",
      "Test Description",
      1000,
      3,
      { from: companyAddress }
    );
    const projectData = await companyInstance.projects(0);
    assert(projectData.projectName === "Test Project");
    assert(projectData.cctAmount.toNumber() === 3);
  });

  it("Selling CCT from Project", async () => {
    let sellCCT = await carbonCreditMarketInstance.sell(3, 0, {
      from: companyAddress,
      value: oneEth * 3.9,
    });

    const projectData = await companyInstance.projects(0);
    assert(projectData.cctListed.toNumber() === 3, "CCT not listed");
    const project = await carbonCreditMarketInstance.companyProjects(
      companyAddress,
      0
    ); // here 0 means accessing the projectId from the list of projects listed by the company
    assert(project.toNumber() === 0, "Project not found"); // here 0 is the project id
  });

  it("Buying CCT from a project should update cctSold and emit BuyCredit event", async () => {
    // Each CCT costs 1 ETH and the buyer wants to buy 2 CCTs
    const cctToBuy = 1;
    const buyer = accounts[3]; // Another account (buyer) from the provided accounts
    const projectId = 0; // The project ID created in the previous test

    // Perform the buy operation
    let buy1 = await carbonCreditMarketInstance.buy(
      cctToBuy,
      companyAddress,
      projectId,
      {
        from: buyer,
        value: oneEth * cctToBuy, // 1 ETH per CCT
      }
    ); // Buy 1 CCTs from the project

    // Check if the cctSold has been updated correctly
    const projectData = await companyInstance.projects(0); // Get the project data

    assert.equal(
      projectData.cctSold.toNumber(),
      cctToBuy,
      "cctSold should reflect the CCTs bought"
    );

    truffleAssert.eventEmitted(buy1, "BuyCredit"); //check if buy event is emitted
  });
});
