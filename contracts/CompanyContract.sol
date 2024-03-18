pragma solidity ^0.5.0;

contract CompanyContract {

    enum projectState { ongoing, completed } //add a modifier that updates state depending on time in carbon market 
    mapping(uint256 => Company) companies; 
    mapping(uint256 => Project) projects;

    struct Company {
        uint256 companyId; 
        string companyName;
        address company_address;
        uint256[] projectList; 
    }
    
    struct Project {
        uint256 projectId;
        uint256 companyId;
        string desc;
        uint256[] tokenIds;
        uint256 cctamount;
        project_state state; 
        uint256 daystillCompletion;
    }

    event companyAdded(uint256 companyId);
    event projectAdded(uint256 companyId, uint256 projectId);


    function addCompany(uint256 companyId, string memory companyName) public {
        require(!companies.contains(companyId), "Company already exists");
        //are we making addCompany payable?
        Company memory newCompany;
        newCompany.companyId = companyId;
        newCompany.companyName = companyName;
        newCompany.company_address = msg.sender;
        newCompany.projectCount = 0;
        companies[companyId] = newCompany;
        emit companyAdded(companyId);
    }


    function addProject(uint256 companyId, string memory companyName, uint256 projectId, string memory desc, uint256 daystillCompletion) public payable {
        require(msg.value > 0.01 ether, "at least 0.01 ETH is needed to add a company");
        //if company has not been listed then add comapny first before adding project 
        Company storage company = companies[companyId];
        if (company.companyId == 0) {
            addCompany(companyId, companyName);
        }
        require(!company.projectList.contains(projectId), "Project already exists");
        //create project
        Project memory newProject;
        newProject.projectId = projectId;
        newProject.companyId = companyId;
        newProject.desc = desc;
        newProject.state = project_state.ongoing;
        newProject.daystillCompletion = daystillCompletion;
        projects[projectId] = newProject;

        //edit company
        company.projectList.push(projectId);

        emit projectAdded(companyId, projectId);
    }
}
