# What does this module do?
Creates Azure VMs and then configures them as Domain Controllers.  If the Azure Region supports Availability Zones, it deploys the DCs in separate AZs.  If the region doesn't have AZ support, it deploys and Availability Set.  

The Domain Controller setup can be reviewed in [Scripts/DomainController-DSC](https://github.com/lukearp/Azure-IAC-Bicep/blob/master/Scripts/DomainController-DSC/DomainControllerConfig.ps1)

Template Deploys:

1. Azure VMs based on the Count Parameter
2. Network Interface for Each VM
3. Two Data Disks per VM for NTDS and SYSVOL directories
4. A DSC Extension that handles configuring the VM as Domain Controllers

# What does this module Require?
An Existing Virtual Network to deploy the VMs. 

If you are deploying to an existing AD DS Forest, you will need Domain Adming Credentials to add the new VMs as DCs.  If you are creating a New AD DS Forest, the Local Admin user will be the default Domain Admin.

Your target subnet will need either a NVA or Azure NAT Gateway to route traffic to the internet of Availability Zone Deployments.

# Parameters
param | type | notes
------|------|------
vmNamePrefix | string | a '-Number' will be appended.  Ex: prefix-1 
location | string | location for VM deployment.  Default is the Location of the Target Resource Group
vmSize | string | VM instance Size, default is 'Standard_B2ms'
ahub | bool | If you have Windows Licensing to use the AHUB benefit.  Default is false
count | int | number of VMs to deploy
vnetId | string | Resource ID of target VNET
subnetName | string | Subnet Name that the VMs will be deployed in.
ntdsSizeGB | int | Size of the NTDS Disk
sysVolSizeGB | int | Size of the SYSVOL Disk
localAdminUsername | string | Username of the Default Local Admin Account
localAdminPassword | string | Password for Default Local Admin Account
domainFqdn | string | FQDN of the Domain you are wanting to Join or Create
newForest | bool | Create a new Forest of Join and Existing.
domainAdminUsername | string | UPN of Domain Admin.  Example: localadmin@test.com
domainAdminPassword | string | Password for Domain Admin
site | string | Name of Site in Sites and Services, default is 'Default-First-Site-Name'
dnsServers | arrary | = Original DNS Server. DNS Servers to be configured on the DC VMs.  Default is '["168.63.129.16"]'.
dscConfigScript | string | Location of the DSC Script in a .zip format.  Default: 'https://github.com/lukearp/Azure-IAC-Bicep/releases/download/DSC/DomainControllerConfig.zip'
timeZoneId | string | Timezone property in Windows Config.  Default: 'Eastern Standard Time' 
managedIdentityId | string | Resource ID of Managed Identity that has rights to restart the Azure VM.  Restart-AzVM is the command this account will be used for.

# Sample Module

```Bicep
resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: 'VAULTNAME'
  scope: resourceGroup('RESOURCEGROUPNAME')   
}

module dc '../Standard-Deployments/DomainController/DomainController.bicep' = {
  name: 'DC-Deploy'
  scope: resourceGroup('bicep_dc')
  params: {
    ahub: true
    count: 2
    dnsServers: [
      '8.8.8.8'
    ]
    domainAdminPassword: keyVault.getSecret('KEYVAULTSECRET_NAME')
    domainAdminUsername: 'localadmin@test.com'
    domainFqdn: 'test.com'
    localAdminPassword: keyVault.getSecret('KEYVAULTSECRET_NAME')
    localAdminUsername: 'localadmin'
    vnetId: '/subscriptions/SUBID/resourceGroups/bicep_palo/providers/Microsoft.Network/virtualNetworks/palo-bicep'
    subnetName: 'DomainControllers'
    ntdsSizeGB: 16
    sysVolSizeGB: 16
    vmNamePrefix: 'lukedc'
    newForest: true             
  }
}
```