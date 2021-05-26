# What is this for?
Help customers manage their Azure deployments using Infrastructure as Code methodologies.  This will help customers with:

1. Organizing deployment standards into Azure Bicep Modules
2. Maintain a hierarchial view of deployed Azure Resources, RBAC Assignments, and Polcies
3. Handle all deployments/modifications of the Azure environment through Workflows

# What is needed for setup?
You will need an Azure App Registration with a ClientID, DirectoryID, and Secret that has access to the scope you will be managing.  If you will be deploying Azure Managment Groups, the App Registration will need MG Contributor at the Tenant Root level.  