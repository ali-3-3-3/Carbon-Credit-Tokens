pragma solidity ^0.5.0;

contract CompanyContract {

    address _owner;
    enum projectState { ongoing, completed } //add a modifier that updates state depending on time in carbon market 
    mapping(address => Company) companies; 
    mapping(uint256 => Project) projects;
    mapping(address => uint256[]) companyProjects;

    struct Company {
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
        project_state state; 
        uint256 daystillCompletion;
    }

    uint256 numProjects = 0;
    event companyAdded(address companyAddress);
    event projectAdded(address companyAddress, uint256 projectId);

    modifier contractOwnerOnly() {
        require(_owner == msg.sender);
        _;
    }

    function projectCompanyOwner(uint256 projectId, address companyAddress) public (bool) {
        uint256[] projectsByCompany = companyProjects[companyAddress];
        bool project = false;
        for (int i = 0; i < projectsByCompany.length; i++) {
            if (projectsByCompany[i] == projectId) {
                project = true;
            }
        }

        return project;
    }

    function addCompany(address companyAddress, string memory companyName) public contractOwnerOnly() { // only contract owner can add companies in
        require(!companies.contains(msg.sender), "Company already added");
        //are we making addCompany payable?
        Company memory newCompany;
        newCompany.companyName = companyName;
        newCompany.company_address = companyAddress;
        newCompany.projectCount = 0;
        companies[companyAddress] = newCompany;
        emit companyAdded(companyAddress);
    }

    function addProject(string pName, string memory companyName, string memory desc, uint256 daystillCompletion) public payable { // companies themselves add project
        require(msg.value > 0.01 ether, "at least 0.01 ETH is needed to add a company");
        //if company has not been listed then add company first before adding project 
        Company storage company = companies[msg.sender];
        if (company.company_address == address(0)) {
            addCompany(msg.sender, companyName);
        }

        //create project
        Project memory newProject;
        uint256 thisProjectId = numProjects++;
        newProject.projectName = pName;
        newProject.companyAddress = msg.sender;
        newProject.desc = desc;
        newProject.state = project_state.ongoing;
        newProject.daystillCompletion = daystillCompletion;
        newProject.cctListed = 0;
        newProjects.cctSold = 0;
        projects[thisProjectId] = newProject;

        //edit company
        company.projectList.push(thisProjectId);
        company.projectCount++;
        companyProjects[msg.sender].push(thisProjectId);

        emit projectAdded(msg.sender, thisProjectId);
    }

    function checkSufficientCCT(address companyAddress, uint256 projectId, uint256 cctAmt) public (bool) {
        require(projectCompanyOwner(projectId, companyAddress), "Project not done by provided company");
        if (projects[projectId].cctSold + cctAmt > projects[projectId].cctAmount) {
            return false;
        }
        return true;
    }

    function sellCCT(address companyAddress, uint256 projectId, uint256 cctAmt) public {
        require(projectCompanyOwner(projectId, companyAddress), "Project not done by provided company");

        projects[projectId].cctSold += cctAmt;
    }

    function checkCCTListed(address companyAddress, uint256 projectId, uint256 cctAmt) public (bool) {
        require(projectCompanyOwner(projectId, companyAddress), "Project not done by provided company");
        if (projects[projectId].cctListed + cctAmt > projects[projectId].cctAmount) {
            return false;
        } 
        return true;
    }

    function listCCT(address companyAddress, uint256 projectId, uint256 cctAmt) public {
        require(projectCompanyOwner(projectId, companyAddress), "Project not done by provided company");

        projects[projectId].cctListed += cctAmt;
    }
}

