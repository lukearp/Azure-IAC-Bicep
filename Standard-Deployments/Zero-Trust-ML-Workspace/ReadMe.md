# What does this module do?
Creates a ML Workspace will all private resources.  Resources Created:

Resource Group with the following resources:
>    1. ML Workspace
>    2. Storage Account
>    3. Key Vault
>    4. Azure Container Registry
>    5. PrivateLink Endpoints for all supported services
>    6. All required private DNS Zones
>    7. AVD Workspace, Host Pool, and Application Group

# Difference between Sandbox and Integrated
Sandbox deploy doesn't require any existing resources.  It deploys all infra with default names.

Integrated has you specifiy names of all the resources.  It also allows you to deploy the DNS zones and records in a separate subscription.

# What does this module require?

User with contributor rights to an Azure Subscription.

# Sandbox Parameters
param | type | notes
------|------|------
resourceGroupName | string | Name of Resource Group that will be created for resource deployments.
mlWorkspaceName | string | Name of ML Workspace to be deployed
location | string | Azure Region to deploy resources to.
deployAVD | bool | Deploy AVD Host Pool, default is False
enableDiagnostics | bool | Enable diagnostic profiles for supported resources.  Currently only Log Analytics supported.
logAnalyticsResourceId | string | Resource ID of target workspace.
azureGovernment | bool | Is the ML Workspace being deployed to Azure Government
tags | object | Tags for resources

# Integrated Parameters
param | type | notes
------|------|------
resourceGroupName | string | Name of Resource Group that will be created for resource deployments.
mlWorkspaceName | string | Name of ML Workspace to be deployed
location | string | Azure Region to deploy resources to.
deployAVD | bool | Deploy AVD Host Pool, default is False
dnsZoneRgName | string | Azure Resource Group that the Private DNS Zones will deploy to.
dnsZoneSubscriptionId | string | Azure Subscription that your dnsZoneRgName is in
dnsVnetId | string | Resource ID of the Virtual Network that the private DNS zones will be associated to
storageAccountName | string | Name of your default Blob Storage account for ML Workspace
appInsightsName | string | App Insights name for you ML Workspace
keyVaultName | string | Name of the Azure Keyvault for your ML Workspace
Azure
acrName | string | Name of Azure Container Registery for ML Workspace
privateLinkSubnetId | string | Resource ID of the subnet that the private link endpoints will be deployed.
azureGovernment | bool | Set to true if deploying to Azure Government.  Default is False
mlworkspacePrivateLinkName | string | (Optional) Name of the Private Link Endpoint for ML Workspace.  Default will be '${mlWorkspaceName}-mlWorkspacePL'
storagePrivateLinkBlobName | string | (Optional) Name of the Private Link Endpoint for Blob Stroage.  Default will be '${mlWorkspaceName}-StorageBlobPL'
storagePrivateLinkFileName | string | (Optional) Name of the Private Link Endpoint for File Stroage.  Default will be '${mlWorkspaceName}-StorageFilePL'
storagePrivateLinkDfsName | string | (Optional) Name of the Private Link Endpoint for Dfs Stroage.  Default will be '${mlWorkspaceName}-StorageDfsPL'
keyvaultPrivateLinkName | string | (Optional) Name of the Private Link Endpoint for Key Vault.  Default will be '${mlWorkspaceName}-KeyVaultPL'
acrPrivateLinkName | string | (Optional) Name of the Private Link Endpoint for Azure Container Registry.  Default will be '${mlWorkspaceName}-AcrPL'
# Sample Module

```Bicep
// Sandbox
targetScope = 'subscription'
module ml '../Standard-Deployments/Zero-Trust-ML-Workspace/zeror-trust-ml-workspace-sandbox.bicep' = {
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
```Bicep
// Integrated
targetScope = 'subscription'
module ml '../Standard-Deployments/Zero-Trust-ML-Workspace/zeror-trust-ml-workspace-integrated.bicep' = {
  name: 'ML-Integrated'
  params: {
    resourceGroupName: 'integrated-rg'
    mlWorkspaceName: 'integrated-ml'
    location: 'eastus'
    dnsZoneRgName: 'dns-zones'
    dnsZoneSubscriptionId: 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'
    dnsVnetId: '/subscriptions/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX/resourcegroups/vnet-rg/providers/microsoft.network/virtualNetworks/myVNET'
    storageAccountName: 'lukemlstorage1234'
    appInsightsName: 'lukemlappinsights'
    privateLinkSubnetId: '/subscriptions/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX/resourcegroups/vnet-spoke-rg/providers/microsoft.network/virtualNetworks/mlVNET/subnets/privateLink'
    keyVaultName: 'lukemlkeyvault'
    acrName: 'lukemlacr'
    azureGovernment: false
    tags: {}
  } 
}
```
