const Company = artifacts.require("Company");

contract("Company", (accounts) => {
  console.log("Testing Company contract");

  let company = null;
  const owner = accounts[0];
  const companyAddress = accounts[1];

  before(async () => {
    company = await Company.deployed();
  });

  it("Should add a company", async () => {
    await company.addCompany(companyAddress, "Test Company", { from: owner });
    const companyData = await company.getCompanyName(companyAddress);
    assert(companyData === "Test Company");
  });

  it("Should not add a company if not owner", async () => {
    try {
      await company.addCompany(companyAddress, "Test Company", {
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
    await company.addProject("Test Project", "Test Description", 1000, 3, {
      from: companyAddress,
    });
    const projectData = await company.projects(0);
    assert(projectData.projectName === "Test Project");
  });
});
