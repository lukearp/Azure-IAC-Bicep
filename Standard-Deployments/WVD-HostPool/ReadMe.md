# What does this module do?
Creats a VM Scale set to a target virtual network.  Configures each host with a custom DSC Exension that inclused the FSLogix setup.  If the WVD Workspace and Host Pool objects are within a separate AAD Tenant, the Deployment Script supports getting the Registration Key if supplied with SPN Credentials of that tenant.     

# What does this module require?

If using SplitTenant = true: 
1. A User Assigned Managed Identity that has rights to get secrets from the key vault that has the WVD-Tenant AppID Secret.
2. The App registration needs rights to create Registration tokens on the target host pool.  

Key Vault with a secret for Admin Password.  The Users deploying the template will need an Access Policy to Get Secrets.

# Parameters
Comming soon

# Sample Module

```Bicep
resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: 'KEYVAULTNAME'
  scope: resourceGroup('KEYVAULTRG')   
}

module hosts '../Standard-Deployments/WVD-HostPool/wvd-hostpool-vmss.bicep' = {
  name: 'GitHub'
  scope: resourceGroup('bicep_wvd')
  params: {
     adminPassword: keyVault.getSecret('secret')
     adminUsername: 'localadmin'
     domainFqdn: 'lukeprojects.com'
     domainJoinPassword: keyVault.getSecret('secret')
     domainJoinUsername: 'localadmin@lukeprojects.com'
     hostCount: 2
     hostPoolName: 'GitHub-Pipeline'
     hostPoolResourceGroupName: 'rg_wvd_spring'
     hostPoolSubscription: '2ab6855d-b9f8-4762-bba5-efe49f339629'
     imageOffer: 'office-365'
     imagePublisher: 'microsoftwindowsdesktop'
     imageSku: '20h2-evd-o365pp'
     keyVaultName: 'VAULT-WITH-WVDWORKSPACETENANT-SECRET'
     keyVaultSecretName: 'WVD-WORKSPACETENANT-SECRET'
     ouPath: 'OU=New-WVD,DC=lukeprojects,DC=com'
     splitTenant: true
     vmNamePrefix: 'github'
     profileContainerPath: '\\\\fileserver.lukeprojects.com\\profiles'
     subnetName: 'VDI'
     virtualNetworkId: '/subscriptions/SUBID/resourceGroups/rg_wvd_eastus/providers/Microsoft.Network/virtualNetworks/wvd_eastus-vnet'
     userManagedIdentityId: '/subscriptions/SUBID/resourceGroups/user-identities/providers/Microsoft.ManagedIdentity/userAssignedIdentities/template-spec'
     vmSize: 'Standard_B4ms'
     wvdAppId: 'WVD-WORKSPACE-APPID'
     wvdTenantId: 'WVD-WORKSPACE-TENANTID'             
  }  
}
```
