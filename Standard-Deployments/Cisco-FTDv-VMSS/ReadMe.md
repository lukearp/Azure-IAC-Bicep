# What does this module do?
Deploys Cisco FTDv appliances to a VM Scale Set to an exsiting VNET

# What does this module require?

An existing Virtual Network with 4 subnets:
1. Management
2. Diagnostic
3. Outside
4. Inside

Key Vault with a secret for Admin Password.  The Users deploying the template will need an Access Policy to Get Secrets.

# Parameters
param | type | notes
------|------|------
namePrefix | string | Name prefix for azure resources
vnetName | string | Name of existing VNET
vnetRg | string | Existing VNET Resource Group Name
adminUsername | string | Admin username
adminPassword | securestring | Admin Password
imageSku | string | Image SKU byol or pay as you go
imageVersion | string | Version of Fire Power appliance
vmSize | string | VM Size, default Standard_D3_v2
zones | array | Availabilty Zones for VMSS
count | int | number of VMs
mgmtSubnet | string | Name of existing management subnet
diagSubnet | string | Name of existing diag subnet
insideSubnet | string | Name of existing inside subnet
outsideSubnet | string | Name of existing outside subnet
location | string | Azure region to deploy VMSS

# Sample Module

```Bicep
resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: 'VAULTNAME'
  scope: resourceGroup('RESOURCEGROUPNAME')   
}

module palo '../Standard-Deployments/Cisco-FTDv-VMSS/ftdv-vmss.bicep' = {
  name: 'cisco-ftd'
  scope: resourceGroup('bicep_cisco')
  params: {
    namePrefix: 'ftdv'
    vnetName: 'cisco-vnet'
    vnetRg: 'vnet-rg'
    adminUsername: 'cisco'
    adminPassword: keyVault.getkey('myPassword')
    imageSku: 'ftdv-azure-byol'
    imageVersion: '67065.0.0'
    vmSize: 'Standard_D3_v2'
    zones: []
    count: 1
    mgmtSubnet: 'mgmt'
    diagSubnet: 'diag'
    insideSubnet: 'inside'   
    outsideSubnet: 'outside'
    location: 'westus'       
  }   
}
```
