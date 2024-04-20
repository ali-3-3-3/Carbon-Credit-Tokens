pragma solidity ^0.5.0;

/**
 * @title Company
 * @dev This contract represents a company and its projects in a carbon market.
 */
contract Company {

    // Enums and structs
    enum ProjectState { ongoing, completed } //add a modifier that updates state depending on time in carbon market 

    struct company {
        address company_address;
        string companyName;
        uint256 projectCount;
    }
    
    struct Project {
        address companyAddress;
        string projectName;
        string desc;
        uint256 cctAmount; //cct amount predicted / given for project
        uint256 cctSold;   //cct sold so far, updated after buyer buys
        uint256 cctListed; //cct listed for sale
        ProjectState state; 
        uint256 daystillCompletion;
        mapping(address => uint256) stakedCredits; // Mapping of staked credits for each company
    }


    // Events 
    event companyAdded(address companyAddress);
    event projectAdded(address companyAddress, uint256 projectId);


    // State variables
    address _owner = msg.sender;
    uint256 public numProjects = 0; // number of projects
    uint256 public numCompanies = 0; // number of companies
    mapping(address => company) companies; // mapping of company address to company
    mapping(uint256 => company) companiesId; // mapping of company id to company
    mapping(uint256 => Project) public projects; // mapping of project id to project
    mapping(address => uint256[]) public companyProjects; // mapping of company address to list of projects


    /**
     * @dev Modifier that allows only the contract owner to execute the function.
     */
    modifier contractOwnerOnly() {
        require(_owner == msg.sender, "Only contract owner can execute this function");
        _;
    }

    /**
     * @dev Checks if a project is owned by a specific company.
     * @param projectId The ID of the project.
     * @param companyAddress The address of the company.
     * @return A boolean indicating whether the project is owned by the company.
     */
    function projectCompanyOwner(uint256 projectId, address companyAddress) public view returns (bool) {
        uint256[] memory projectsByCompany = companyProjects[companyAddress];
        for (uint256 i = 0; i < projectsByCompany.length; i++) {
            if (projectsByCompany[i] == projectId) { // project done by company
                return true; // project done by company
            }
        }
        return false; // project not done by company
    }


    /**
     * @dev Adds a new company to the carbon market.
     * @param companyAddress The address of the company.
     * @param companyName The name of the company.
     * @return The ID of the newly added company.
     */
    function addCompany(address companyAddress, string memory companyName) public contractOwnerOnly returns(uint256) {
        require(companies[msg.sender].company_address == address(0), "Company already added");
        company memory newCompany; 
        newCompany.companyName = companyName;
        newCompany.company_address = companyAddress;
        newCompany.projectCount = 0;
        companies[companyAddress] = newCompany; // add company to list of companies, company address is the key, company is the value
        emit companyAdded(companyAddress); 
        /*Not sure if we need these eventually in situations where dk company address*/
        uint256 newCompanyId = numCompanies++;
        companiesId[newCompanyId] = newCompany; //company id is the key, company is the value
        return newCompanyId;   //return new companyId
    }


    /**
     * @dev Adds a new project to the carbon market.
     * @param pName The name of the project.
     * @param desc The description of the project.
     * @param daystillCompletion The number of days until project completion.
     */
    function addProject(string memory pName, string memory desc, uint256 daystillCompletion, uint256 carbonDioxideSaved) public payable {
        require(carbonDioxideSaved >= 1, "Project must be predicted to at least save 1 ton of CO2");
        // if company has not been listed, cant add company as only owner can add company
        company storage thisCompany = companies[msg.sender];

        uint256 intTonCO2Saved = carbonDioxideSaved / 1; // int amt of cct

        //create project
        Project memory newProject;
        uint256 thisProjectId = numProjects++;
        newProject.projectName = pName;
        newProject.companyAddress = msg.sender;
        newProject.desc = desc;
        newProject.state = ProjectState.ongoing;
        newProject.daystillCompletion = daystillCompletion;
        newProject.cctListed = 0; 
        newProject.cctAmount = intTonCO2Saved; // industry standard, 1 ton of co2 = 1 cct.
        newProject.cctSold = 0;
        projects[thisProjectId] = newProject;

        //edit company
        thisCompany.projectCount++;
        companyProjects[msg.sender].push(thisProjectId);
        emit projectAdded(msg.sender, thisProjectId);
    }


    /**
     * @dev Returns the ETH balance of a company.
     * @param companyAddress The address of the company.
     * @return The ETH balance of the company.
     */
    function getCompanyEthBalance(address companyAddress) public view returns (uint256) {
        require(companies[companyAddress].company_address != address(0), "Company does not exist");
        return companyAddress.balance; // get eth balance of the company (msg.sender)
    }


    /**
     * @dev Stakes credits for a project.
     * @param companyAddress The address of the company.
     * @param projectId The ID of the project.
     * @param credits The amount of credits to stake.
     */
    function stakeCredits(address companyAddress, uint256 projectId, uint256 credits) public {
        require(projects[projectId].companyAddress == companyAddress, "Only project owner can stake credits");
        require(credits > 0, "Must stake a positive amount of credits");
        projects[projectId].stakedCredits[companyAddress] += credits;
    }


    /**
     * @dev Returns the staked credits for a project.
     * @param companyAddress The address of the company.
     * @param projectId The ID of the project.
     * @return The amount of staked credits for the project.
     */
    function getStakedCredits(address companyAddress, uint256 projectId) public view returns (uint256) {
        require(projectCompanyOwner(projectId, companyAddress), "Project not owned by company");
        return projects[projectId].stakedCredits[companyAddress];
    }


    /**
     * @dev Checks if there are sufficient CCT (Carbon Credit Tokens) for a project.
     * @param companyAddress The address of the company.
     * @param projectId The ID of the project.
     * @param cctAmt The amount of CCT to check.
     * @return A boolean indicating whether there are sufficient CCT for the project.
     */
    function checkSufficientCCT(address companyAddress, uint256 projectId, uint256 cctAmt) public view returns (bool) {
        require(projectCompanyOwner(projectId, companyAddress), "Project not done by provided company");
        if (projects[projectId].cctSold + cctAmt > projects[projectId].cctAmount) { //when buy, cctSold increases
            return false;
        }
        return true;
    }


    // /**
    //  * @dev Sells CCT (Carbon Credit Tokens) for a project.
    //  * @param companyAddress The address of the company.
    //  * @param projectId The ID of the project.
    //  * @param cctAmt The amount of CCT to sell.
    //  */
    // function sellCCT(address companyAddress, uint256 projectId, uint256 cctAmt) public {
    //     require(projectCompanyOwner(projectId, companyAddress), "Project not done by provided company");
    //     projects[projectId].cctSold += cctAmt; 
    //     // projects[projectId].cctAmount -= cctAmt; //the cct amount for the project decreases when buyer buys
    // }


    /**
     * @dev Checks if there are sufficient CCT (Carbon Credit Tokens) listed for sale for a project.
     * @param companyAddress The address of the company.
     * @param projectId The ID of the project.
     * @param cctAmt The amount of CCT to check.
     * @return A boolean indicating whether there are sufficient CCT listed for sale for the project.
     */
    function checkCCTListed(address companyAddress, uint256 projectId, uint256 cctAmt) public view returns (bool) {
        require(projectCompanyOwner(projectId, companyAddress), "Project not done by provided company");
        if (projects[projectId].cctListed + cctAmt > projects[projectId].cctAmount) { //when sell, cctListed increases
            return false;
        } 
        return true;
    }


    /**
     * @dev Lists CCT (Carbon Credit Tokens) for sale for a project.
     * @param companyAddress The address of the company.
     * @param projectId The ID of the project.
     * @param cctAmt The amount of CCT to list for sale.
     */
    function listCCT(address companyAddress, uint256 projectId, uint256 cctAmt) public {
        require(projectCompanyOwner(projectId, companyAddress), "Project not done by provided company");
        projects[projectId].cctListed += cctAmt;  //cctListed increases when listed
        // projects[projectId].cctAmount += cctAmt; //cctAmount equals cctListed when listed   
    }


    /**
     * @dev Returns the details of a specific project.
     * @param projectId The ID of the project.
     * @return The details of the project.
     */
    function getProjectcctAmount(uint256 projectId) public view returns (uint256) {
        require(projectId < numProjects, "Invalid project ID");
        Project memory project = projects[projectId];
        return project.cctAmount;
    }

    
    /**
     * @dev Sets the amount of CCT for a project.
     * @param projectId The ID of the project.
     * @param cctAmt The amount of CCT to set.
     */
    function setProjectcctAmount(uint256 projectId, uint256 cctAmt) public {
        require(projectId < numProjects, "Invalid project ID");
        projects[projectId].cctAmount = cctAmt;
    }

    /**
     * @dev Returns the amount of CCT sold for a project.
     * @param projectId The ID of the project.
     * @return The amount of CCT sold for the project.
     */
    function getCCTSold(uint256 projectId) public view returns (uint256) {
        require(projectId < numProjects, "Invalid project ID");
        return projects[projectId].cctSold;
    }

    /**
     * @dev Returns the state of a specific project.
     * @param projectId The ID of the project.
     * @return The state of the project.
     */
    function getProjectState(uint256 projectId) public view returns (ProjectState) {
        require(projectId < numProjects, "Invalid project ID");
        return projects[projectId].state;
    }

    /**
    * @dev Sets a project state to complete.
    * @param projectId The ID of the project.
    */
    function setProjectStateComplete(uint256 projectId) public {
        require(projectId < numProjects, "Invalid project ID");
        projects[projectId].state = ProjectState.completed;
    }


    /**
     * @dev Returns the name of a specific company.
     * @param companyAddress The address of the company.
     * @return The name of the company.
     */
    function getCompanyName(address companyAddress) public view returns (string memory) {
        require(companies[companyAddress].company_address != address(0), "Company does not exist");
        return companies[companyAddress].companyName;
    }
}
