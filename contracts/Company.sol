pragma solidity ^0.5.0;

contract Company {

    enum ProjectState { ongoing, completed } //add a modifier that updates state depending on time in carbon market 

    struct company {
        address company_address;
        string companyName;
        uint256[] projectList; // dk if this is still needed
        uint256 projectCount;
    }
    
    struct Project {
        address companyAddress;
        string projectName;
        string desc;
        uint256 cctAmount; //cct amount for project, after sell/buy
        uint256 cctSold;   //cct sold so far, updated after buyer buys
        uint256 cctListed; //cct listed for sale
        ProjectState state; 
        uint256 daystillCompletion;
        mapping(address => uint256) stakedCredits; // Mapping of staked credits for each company
    }

    event companyAdded(address companyAddress);
    event projectAdded(address companyAddress, uint256 projectId);

    address _owner = msg.sender;
    uint256 public numProjects = 0; // number of projects
    uint256 public numCompanies = 0; // number of companies
    mapping(address => company) companies; // mapping of company address to company
    mapping(uint256 => company) companiesId; // mapping of company id to company
    mapping(uint256 => Project) projects; // mapping of project id to project
    mapping(address => uint256[]) companyProjects; // mapping of company address to list of projects

    modifier contractOwnerOnly() {
        require(_owner == msg.sender);
        _;
    }

    function projectCompanyOwner(uint256 projectId, address companyAddress) public view returns (bool) {
        uint256[] memory projectsByCompany = companyProjects[companyAddress];
        for (uint256 i = 0; i < projectsByCompany.length; i++) {
            if (projectsByCompany[i] == projectId) { // project done by company
                return true; // project done by company
            }
        }
        return false; // project not done by company
    }

    function addCompany(address companyAddress, string memory companyName) public contractOwnerOnly() returns(uint256) { // only contract owner can add companies in the carbon market
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

    function addProject(string memory pName, string memory desc, uint256 daystillCompletion) public payable { // companies themselves add project
        require(msg.value >= 0.01 ether, "at least 0.01 ETH is needed to add a company");
        //if company has not been listed, cant add company as only owner can add company
        company storage thisCompany = companies[msg.sender];
        /*if (thisCompany.company_address == address(0)) {
            addCompany(msg.sender, companyName);
        }*/

        //create project
        Project memory newProject;
        uint256 thisProjectId = numProjects++;
        newProject.projectName = pName;
        newProject.companyAddress = msg.sender;
        newProject.desc = desc;
        newProject.state = ProjectState.ongoing;
        newProject.daystillCompletion = daystillCompletion;
        newProject.cctListed = 0;
        newProject.cctSold = 0;
        projects[thisProjectId] = newProject;

        //edit company
        thisCompany.projectList.push(thisProjectId);
        thisCompany.projectCount++;
        companyProjects[msg.sender].push(thisProjectId);
        emit projectAdded(msg.sender, thisProjectId);
    }

       // Function to check the ETH balance of the company
    function getCompanyEthBalance(address companyAddress) public view returns (uint256) {
        require(companies[companyAddress].company_address != address(0), "Company does not exist");
        return companyAddress.balance; // get eth balance of the company (msg.sender)
    }

    // Function to stake credits for a project
    function stakeCredits(address companyAddress, uint256 projectId, uint256 credits) public {
        require(projects[projectId].companyAddress == companyAddress, "Only project owner can stake credits");
        require(credits > 0, "Must stake a positive amount of credits");
        projects[projectId].stakedCredits[companyAddress] += credits;
    }

    //function to view the staked credits for a project
    function getStakedCredits(address companyAddress, uint256 projectId) public view returns (uint256) {
        require(projectCompanyOwner(projectId, companyAddress), "Project not owned by company");
        return projects[projectId].stakedCredits[companyAddress];
    }

    function returnStakedCredits(address companyAddress, uint256 projectId) public view {
        require(projectCompanyOwner(projectId, companyAddress), "Project not owned by company");
        projects[projectId].stakedCredits[companyAddress];
    }

    function checkSufficientCCT(address companyAddress, uint256 projectId, uint256 cctAmt) public view returns (bool) {
        require(projectCompanyOwner(projectId, companyAddress), "Project not done by provided company");
        if (projects[projectId].cctSold + cctAmt > projects[projectId].cctAmount) { //when buy, cctSold increases
            return false;
        }
        return true;
    }

    function sellCCT(address companyAddress, uint256 projectId, uint256 cctAmt) public {
        require(projectCompanyOwner(projectId, companyAddress), "Project not done by provided company");
        projects[projectId].cctSold += cctAmt;
        projects[projectId].cctAmount -= cctAmt; //the cct amount for the project decreases when sold
    }

    function checkCCTListed(address companyAddress, uint256 projectId, uint256 cctAmt) public view returns (bool) {
        require(projectCompanyOwner(projectId, companyAddress), "Project not done by provided company");
        if (projects[projectId].cctListed + cctAmt > projects[projectId].cctAmount) { //when sell, cctListed increases
            return false;
        } 
        return true;
    }

    function listCCT(address companyAddress, uint256 projectId, uint256 cctAmt) public {
        require(projectCompanyOwner(projectId, companyAddress), "Project not done by provided company");
        projects[projectId].cctListed += cctAmt;  
        projects[projectId].cctAmount += cctAmt; //cctAmount equals cctListed when listed   
    }
}