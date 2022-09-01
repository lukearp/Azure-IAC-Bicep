# What does this module do?
Creates a ML Workspace will all private resources.  Resources Created:

Resource Group with the following resources:
    1. ML Workspace
    2. Storage Account
    3. Key Vault
    4. Azure Container Registry
    5. PrivateLink Endpoints for all supported services

# What does this module require?

User with contributor rights to an Azure Subscription.

# Parameters
param | type | notes
------|------|------
resourceGroupName | string | Name of Resource Group that will be created for resource deployments.
mlWorkspaceName | string | Name of ML Workspace to be deployed
location | string | Azure Region to deploy resources to.
enableDiagnostics | bool | Enable diagnostic profiles for supported resources.  Currently only Log Analytics supported.
logAnalyticsResourceId | string | Resource ID of target workspace.
azureGovernment | bool | Is the ML Workspace being deployed to Azure Government
tags | object | Tags for resources

# Sample Module

```Bicep
targetScope = 'subscription'
module ml '../Standard-Deployments/Zero-Trust-ML-Workspace/zeror-trust-ml-workspace.bicep' = {
  name: 'LukeTest-ML'
  params: {
    location: 'eastus'
    mlWorkspaceName: 'LukeTestML-Deploy'
    resourceGroupName: 'pipeline-ml-deploy'
    tags: {
      Environment: 'Test'
    } 
    enableDiagnostics: true
    azureGovernment: false  
    logAnalyticsResourceId: '/subscriptions/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX/resourcegroups/azure-monitor/providers/microsoft.operationalinsights/workspaces/workspacename'   
  }  
}
```
