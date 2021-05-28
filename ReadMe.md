# What is the goal?
Develop a standard of organizing and maintaining Infrastructure as Code using GitHub and Bicep.

1. Organizing deployment standards into Azure Bicep Modules
2. Maintain a hierarchial view of deployed Azure Resources, RBAC Assignments, and Polcies
3. Handle all deployments/modifications of the Azure environment through Workflows

# How it works

## Cloud Folders
A folder for each Cloud that will be managed within the repository.  Example:

    AzureCloud = Azure Commercial
    AzureUSGovernment = Azure Government

Children of the Cloud Folder will be Deployment Target Folders. These folders will be referenced in a format that will easily read to what the target is. Example:

    Root-MG = ManagementGroup Target
    Sub-MySub = Subscription
    rg_mydeployment = ResourceGroup

Within a Deployment Target, folders to house Custom RBAC Roles/Assignments, PolicyDefinitions/Assignments, PolicySetDefinitions/Assignments, and BluePrint Definitions/Assignments.  Those folders will be named after the Azure ARM Namespace they belong to.  Example:

    PolicyDefinitions = Microsoft.Authorization/policyDefinitions

A Deployment Target Folder can also house a '.bicep' file that will manage the resource deployment within the deployment scope.  Example:

    AzureCloud/Root-MG/Sub-MySub/rg_mydeployment/deployment.bicep

In the above example, deployment.bicep will be deploying resources within the 'rg_mydeployment' resource group.

Pipelines will be created and maintained in the .github/workflows folder.  These pipelines will be referencing .bicep files within the Cloud folder hierarchy and manage the deployment for those resources.  

## Modules Folder
Modules folder houses the standard resource deployments to be consumed by the '.bicep' files within the Cloud Folders.  The child fodlers within Modules will follow the naming standards of the Azure ARM Namespace.  Example:

    Modules/Microsoft.Network/networkSecurityGroups/networkSecurityGroups.bicep

That standard resource deployment would be referenced within a '.bicep' file within the cloud folder to handle Network Security Group Deployments.  You can manage multiple version of these within the same folder for different deployment scenarios.  Example:

    Modules/Microsoft.Network/networkSecurityGroups/networkSecurityGroups.bicep = Standard NSG Deploy
    Modules/Microsoft.Network/networkSecurityGroups/networkSecurityGroups-array.bicep = Standard NSG Deploy with an Array Parameter
    Modules/Microsoft.Network/networkSecurityGroups/networkSecurityGroups-sqlMi.bicep = Standard NSG Deploy to support a SQL Managed Instance Deployment

## Standard-Deployments Folder
This is a place for multi-resource deployments.  An Example would be a standard NVA Deployment.  These standard deployments would then be consumed as modules in the Cloud Folders '.bicep' files.  

## Test-Functions
This is a folder for testing bicep files and modules.  This folder is ignored when it comes to version control.

# How are deployments managed?
This can be handled multiple ways.  In my environment, since I am the only contributor, I am tying my Pipelines to specific Branches.  Once I have my Pipeline configured with all the .bicep files I want it to deploy, I commit and push to my Branch that triggers my workflow.  When the workflow completes successfully, I do a merge request to get the changed added to the master branch.  

If I was in a more distributed environment, where multiple people are working on multiple things, I would encourage teams to Fork the repository.  This would allow them to test their deployments in their own environments with a Service Principal they manage.  Once they get the result they are looking for, request to merge to the primary repository.  

I am still figuring out ways to be handle this, so any feed back is appreciated.  