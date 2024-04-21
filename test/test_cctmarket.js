const CarbonCreditMarket = artifacts.require("CarbonCreditMarket");
const Company = artifacts.require("Company");
const ValidatorRegistry = artifacts.require("ValidatorRegistry");
const CarbonCreditToken = artifacts.require("CarbonCreditToken");  // Make sure this line is here
const truffleAssert = require('truffle-assertions'); // Make sure this line is here
const oneEth = web3.utils.toWei("1", "ether"); // 1 ETH

contract("CarbonCreditMarket", function (accounts) {
  let companyInstance;
  let validatorRegistryInstance;
  let carbonCreditMarketInstance;
  let carbonCreditTokenInstance;  // Declare the token instance variable
  const owner = accounts[0]; // Contract owner
  const companyAddress = accounts[1]; // Company address
  const validatorAddress = accounts[2]; // Validator address
  const buyerAddress = accounts[3]; // Buyer address

  before(async () => {
    validatorRegistryInstance = await ValidatorRegistry.deployed();
    companyInstance = await Company.deployed();
    carbonCreditMarketInstance = await CarbonCreditMarket.deployed();
    carbonCreditTokenInstance = await CarbonCreditToken.deployed(); // Deploy the token instance

    // Set up initial state
    await validatorRegistryInstance.addValidator(validatorAddress, { from: owner });
    await companyInstance.addCompany(companyAddress, "Test Company", { from: owner });
    await companyInstance.addProject("Test Project", "Test Description", 1000, 3, { from: companyAddress });
  });

  it("Should add a company", async () => {
    const companyInstanceData = await companyInstance.getCompanyName(companyAddress);
    assert.strictEqual(companyInstanceData, "Test Company", "Company should be added with the correct name");
  });

  it("Should not add a company if not owner", async () => {
    try {
      await companyInstance.addCompany(companyAddress, "Test Company", { from: companyAddress });
      assert.fail("Should have thrown an error not being the owner");
    } catch (error) {
      assert.include(error.message, "Only contract owner can execute this function", "Error message should contain correct restriction message");
    }
  });

  it("Should add a project", async () => {
    const projectData = await companyInstance.projects(0);
    assert.strictEqual(projectData.projectName, "Test Project", "Project name should be correctly recorded");
    assert.strictEqual(projectData.cctAmount.toNumber(), 3, "CCT amount should be set correctly");
  });

  it("Selling CCT from Project", async () => {
    await carbonCreditMarketInstance.sell(3, 0, { from: companyAddress, value: oneEth * 3.9 });

    const projectData = await companyInstance.projects(0);
    assert.strictEqual(projectData.cctListed.toNumber(), 3, "CCT should be listed for sale correctly");
  });

  it("Buying CCT from a project should update cctSold and emit BuyCredit event", async () => {
    const cctToBuy = 1;
    const projectId = 0;
    let buy1 = await carbonCreditMarketInstance.buy(cctToBuy, companyAddress, projectId, { from: buyerAddress, value: oneEth * cctToBuy });

    const projectData = await companyInstance.projects(0);
    assert.strictEqual(projectData.cctSold.toNumber(), cctToBuy, "cctSold should reflect the CCTs bought");

    truffleAssert.eventEmitted(buy1, "BuyCredit", (ev) => {
      return ev.buyer === buyerAddress && ev.amount.toNumber() === cctToBuy;
    }, "BuyCredit event should be emitted with correct parameters");
  });



  it("Should handle valid project validation by a registered validator (no penalties)", async () => {
    const projectId = 0; // Existing project ID
    const actualCCT = 3; // Actual CCT matches predicted

    // Fetch the list of buyers for the project
    const buyersAddresses = await carbonCreditMarketInstance.getProjectBuyers(projectId);

    // Fetch initial CCT balances for all buyers
    const buyersInitialCCT = await Promise.all(
        buyersAddresses.map(async (buyer) => {
            return {
                buyer,
                initialCCT: await carbonCreditTokenInstance.balanceOf(buyer)
            };
        })
    );

    // Validate the project successfully
    let validate = await carbonCreditMarketInstance.validateProject(companyAddress, projectId, true, actualCCT, { from: validatorAddress });

    let projectData = await companyInstance.projects(projectId);
    assert.strictEqual(projectData.state.toString(), "1", "Project state should be marked as completed");

    // Check that the event was emitted correctly
    truffleAssert.eventEmitted(validate, 'ProjectValidated', (ev) => {
        return ev.isValid === true && ev.projectId.toNumber() === projectId && ev.companyAddress === companyAddress;
    }, "Project should be validated as true");

    // Check that each buyer's CCT has increased correctly
    for (let { buyer, initialCCT } of buyersInitialCCT) {
        const newCCT = await carbonCreditTokenInstance.balanceOf(buyer);
        assert(newCCT.gt(initialCCT), `CCT for buyer ${buyer} should have increased`);
    }
  });


  it("Should handle penalties on invalid project validation", async () => {
    const projectId = 1; // Assume this is a new project ID for invalid case
    const actualCCT = 1; // Less than predicted leading to invalidation
    await companyInstance.addProject("Invalid Project", "Invalid Description", 1000, 2, { from: companyAddress });

    let validate = await carbonCreditMarketInstance.validateProject(companyAddress, projectId, false, actualCCT, { from: validatorAddress });

    truffleAssert.eventEmitted(validate, 'Penalty', (ev) => {
      return ev.projectId.toNumber() === projectId && ev.companyAddress === companyAddress;
    }, "Penalty should be emitted for invalid project");
});

it("Should revert when attempting to validate a project that is already completed", async () => {
  const projectId = 2; // An example project ID; 
  const actualCCT = 5; // Example actual CCT that would be used for validation.

  // First, add a new project if necessary or ensure it's set to an ongoing state before validating
  await companyInstance.addProject("New Project", "A project for testing", 1000, actualCCT, { from: companyAddress });

  // Validate the project initially to set it as completed
  await carbonCreditMarketInstance.validateProject(companyAddress, projectId, true, actualCCT, { from: validatorAddress });

  // Now, try to validate again and expect it to fail since the project should be marked as completed
  try {
      await carbonCreditMarketInstance.validateProject(companyAddress, projectId, true, actualCCT, { from: validatorAddress });
      assert.fail("The transaction should have reverted.");
  } catch (error) {
      assert.include(error.message, "Project completed, cannot be validated again", "Error message should indicate that the project cannot be re-validated");
  }
});

it("Should correctly handle excess CCT upon successful project validation", async () => {
  const projectIndex = await companyInstance.numProjects(); // Get the current number of projects
  const listedCCT = 10;
  const soldCCT = 5;
  const actualCCT = 15; // Actual CCT is greater than what was sold

  // Add a project
  await companyInstance.addProject("Excess CCT Project", "Handling excess CCT", 500, listedCCT, { from: companyAddress });
  
  const newProjectIndex = await companyInstance.numProjects(); // New project index after adding the project
  assert(newProjectIndex.sub(projectIndex).eq(web3.utils.toBN(1)), "One new project should be added");

  const projectId = newProjectIndex.toNumber() - 1; // Assuming projects are 0-indexed

  // List and simulate selling some CCT
  await carbonCreditMarketInstance.sell(listedCCT, projectId, { from: companyAddress, value: web3.utils.toWei("13", "ether") });
  await carbonCreditMarketInstance.buy(soldCCT, companyAddress, projectId, { from: buyerAddress, value: web3.utils.toWei("5", "ether") });

  // Validate the project with actual CCT greater than sold CCT
  let validate = await carbonCreditMarketInstance.validateProject(companyAddress, projectId, true, actualCCT, { from: validatorAddress });

  // Check the remaining CCT in the project should be actualCCT - soldCCT
  const remainingCCT = await companyInstance.getProjectcctAmount(projectId);
  assert.strictEqual(remainingCCT.toNumber(), actualCCT - soldCCT, "Remaining CCT should be set to actual CCT minus sold CCT");

  // Check event for proper validation
  truffleAssert.eventEmitted(validate, 'ProjectValidated', (ev) => {
    return ev.isValid === true && ev.projectId.toNumber() === projectId && ev.companyAddress.toLowerCase() === companyAddress.toLowerCase();
  }, "Project should be validated as true");
});






});
