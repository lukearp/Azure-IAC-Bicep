# What does this module do?
Creats a VM Scale set to a target virtual network.  Configures each host with a custom DSC Exension that inclused the FSLogix setup.  If the WVD Workspace and Host Pool objects are within a separate AAD Tenant, the Deployment Script supports getting the Registration Key if supplied with SPN Credentials of that tenant.     

# What does this module require?

If using SplitTenant = true: 
1. A User Assigned Managed Identity that has rights to get secrets from the key vault that has the WVD-Tenant AppID Secret.
2. The App registration needs rights to create Registration tokens on the target host pool.  

Key Vault with a secret for Admin Password.  The Users deploying the template will need an Access Policy to Get Secrets.

# Parameters
param | type | notes
------|------|------
vmNamePrefix | string | a '-Number' will be appended.  Ex: prefix-1 
location | string | location for VM deployment.  Default is the Location of the Target Resource Group
vmSize | string | VM instance Size
hostCount | int | number of VMs to deploy
splitTenant | bool | Is the WVD Objects within a different AAD Tenant than the Virtual Machine Subscription.
keyVaultName | string | Name of the Azure Key Vault that has the Client ID Secret to login to remote AAD Tenant.
keyVaultSecretName | string | Name of the Secret within the keyVault
wvdAppId | string | If splitTenant = true, the Application ID in the WVD Tenant that has Contributor rights to the Host Pool Object.
wvdTenantId | string | If splitTenant = true, the Tenant ID that has the Host Pool object.
hostPoolName | string | Name of existing WVD Host Pool object
hostPoolResourceGroupName | string | Resource Group Name that has Host Pool Object
hostPoolSubscription | string | Subscritpion ID that has Host Pool Object
imagePublisher | string | Source Image Publisher
imageOffer | string | Source Image offer.
imageSku | string | Source Image Sku
vnetId | string | Resource ID of target VNET
subnetName | string | Subnet Name that the VMs will be deployed in.
adminUsername | string | Username of the Default Local Admin Account
adminUsername | string | Password for Default Local Admin Account
domainFqdn | string | FQDN of the Domain you are wanting to Join or Create
domainJoinUsername | string | UPN of Domain Admin.  Example: localadmin@test.com
domainJoinPassword | string | Password for Domain Admin
ouPath | string | OU DN that Computer Objects will be added.
profileContainerPath | string | UNC Path to profiles share for FSLogix target. Must double '\\' because it is an escape string. Example: '\\\\\\\\fileserver.lukeprojects.com\\\\profiles' 
artifcatLocation | string | Location of the DSC Script in a .zip format.  Default: 'https://github.com/lukearp/Azure-IAC-Bicep/releases/download/DSC/WVD-DSC.zip'
userManagedIdentityId | string | Resource ID of Managed Identity that has rights to restart the Azure VM.  Restart-AzVM is the command this account will be used for.


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
