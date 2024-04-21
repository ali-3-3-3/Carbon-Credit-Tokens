const _deploy_contracts = require("../migrations/5_deploy_contracts");

var CarbonCreditMarket = artifacts.require("CarbonCreditMarket");
var Company = artifacts.require("Company");
var ValidatorRegistry = artifacts.require("ValidatorRegistry");
var CarbonCreditToken = artifacts.require("CarbonCreditToken");

const oneEth = 1000000000000000000; // 1 eth

contract("CarbonCreditMarket for Completed Projects", function (accounts) {
  let companyInstance = null;
  const owner = accounts[0]; // contract owner
  const companyAddress = accounts[1]; // company address

  before(async () => {
    validatorRegistryInstance = await ValidatorRegistry.deployed();
    companyInstance = await Company.deployed();
    carbonCreditMarketInstance = await CarbonCreditMarket.deployed();
    carbonCreditTokenInstance = await CarbonCreditToken.deployed();
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

  it("Selling CCT from Completed Project", async () => {
    await companyInstance.setProjectStateComplete(0); // set project to be completed
    await carbonCreditTokenInstance.getCCT(companyAddress, 3); // give 3 CCT to the company (since its a completed project)
    let initialSellerCCT = await carbonCreditTokenInstance.checkCCT(
      companyAddress
    );
    assert(initialSellerCCT.toNumber() === 3, "CCT not added to company");

    await carbonCreditMarketInstance.sell(3, 0, {
      from: companyAddress,
    });

    const projectData = await companyInstance.projects(0);
    assert(projectData.cctListed.toNumber() === 3, "CCT not listed");

    let afterSellerCCT = await carbonCreditTokenInstance.checkCCT(
      companyAddress
    );
    assert(afterSellerCCT.toNumber() === 0, "CCT not deducted from company");
  });
});
