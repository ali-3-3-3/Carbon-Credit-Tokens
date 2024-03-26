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
        uint256 cctAmount;
        uint256 cctSold;
        uint256 cctListed;
        ProjectState state; 
        uint256 daystillCompletion;
    }

    event companyAdded(address companyAddress);
    event projectAdded(address companyAddress, uint256 projectId);

    address _owner;
    uint256 public numProjects = 0; // number of projects
    uint256 public numCompanies = 0; // number of companies
    mapping(address => company) companies; // mapping of company address to company
    mapping(uint256 => company) companiesId; // mapping of company id to company
    mapping(uint256 => Project) projects;
    mapping(address => uint256[]) companyProjects;

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

    function addCompany(address companyAddress, string memory companyName) public returns(uint256) contractOwnerOnly() { // only contract owner can add companies in the carbon market
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

    function addProject(string memory pName, string memory companyName, string memory desc, uint256 daystillCompletion) public payable { // companies themselves add project
        require(msg.value >= 0.01 ether, "at least 0.01 ETH is needed to add a company");
        //if company has not been listed then add company first before adding project 
        company storage thisCompany = companies[msg.sender];
        if (thisCompany.company_address == address(0)) {
            addCompany(msg.sender, companyName);
        }
        //create project
        Project memory newProject;
        uint256 thisProjectId = numProjects++;
        newProject.projectName = pName;
        newProject.companyAddress = msg.sender;
        newProject.desc = desc;
        newProject.state = projectState.ongoing;
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

    function checkSufficientCCT(address companyAddress, uint256 projectId, uint256 cctAmt) public view returns (bool) {
        require(projectCompanyOwner(projectId, companyAddress), "Project not done by provided company");
        if (projects[projectId].cctSold + cctAmt > projects[projectId].cctAmount) {
            return false;
        }
        return true;
    }

    function sellCCT(address companyAddress, uint256 projectId, uint256 cctAmt) public view {
        require(projectCompanyOwner(projectId, companyAddress), "Project not done by provided company");
        projects[projectId].cctSold += cctAmt;
    }

    function checkCCTListed(address companyAddress, uint256 projectId, uint256 cctAmt) public view returns (bool) {
        require(projectCompanyOwner(projectId, companyAddress), "Project not done by provided company");
        if (projects[projectId].cctListed + cctAmt > projects[projectId].cctAmount) {
            return false;
        } 
        return true;
    }

    function listCCT(address companyAddress, uint256 projectId, uint256 cctAmt) public view {
        require(projectCompanyOwner(projectId, companyAddress), "Project not done by provided company");
        projects[projectId].cctListed += cctAmt;
    }
}