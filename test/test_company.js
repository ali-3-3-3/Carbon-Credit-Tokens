const Company = artifacts.require("Company");
const truffleAssert = require("truffle-assertions"); // npm truffle-assertions
var assert = require("assert");

contract("Company", function (_accounts) {

    console.log("Testing Company contract");

    it("Contract owner registers a company", async () => {
        let companyInstance = await Company.deployed();
        // Ensure only the contract owner can register a company
        await truffleAssert.reverts(
            companyInstance.addCompany("0x1234567890123456789012345678901234567890", { from: _accounts[1] }),
            "Only the contract owner can register a company"
        );

        // Register a new company
        await companyInstance.addCompany("0x1234567890123456789012345678901234567890", { from: owner });

        // Check if the company is in the list
        let companyCount = await companyInstance.getCompanyCount();
        let registeredCompany = await companyInstance.companies(companyCount - 1);
        assert.equal(registeredCompany.name, companyName, "Company was not registered successfully");
    });

    it("Company adds a project", async () => {
        let companyInstance = await Company.deployed();
        // Ensure company is registered
        let isRegistered = await companyInstance.companyAdded();
        assert.ok(isRegistered, "Company is not registered");
    
        // Add a project
        let projectName = "Project A";
        await companyInstance.addProject(projectName, "desc", 100);
    
        // Check if the project is added to the company
        let projectCount = await companyInstance.getProjectCount();
        let addedProject = await companyInstance.projects(projectCount - 1);
        assert.equal(addedProject.name, projectName, "Project was not added successfully");
    
        // Check if the project is credited with the appropriate CCT
        assert.equal(addedProject.day, cct, "Project was not credited with the appropriate CCT");
    });

});
