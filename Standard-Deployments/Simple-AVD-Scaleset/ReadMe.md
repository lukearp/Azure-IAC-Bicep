# What does this module do?
Creats a VM Scale set to a target virtual network.   

# What does this module require?

If using SplitTenant = true: 
1. A User Assigned Managed Identity that has rights to get secrets from the key vault that has the WVD-Tenant AppID Secret.
2. The App registration needs rights to create Registration tokens on the target host pool.  

Key Vault with a secret for Admin Password.  The Users deploying the template will need an Access Policy to Get Secrets.

# Parameters
param | type | notes
------|------|------
scaleSetName | string | VM Scale Set Name
vmPrefix | string | Computer Name Prefix
newScaleSet | bool | Is this a new VMSS Deployment, True = New VMSS, False = Delete existing VMSS
scaleExisting | bool | Scale existing VMSS, True = scale without deleting VMSS
vmCount | int | number of VMs to deploy
vmSize | string | VM instance Size
customImage | bool | Use a custom of Gallery image.  True = Custom False = Gallery
customImageResourceId | string | Resource ID of custom image in Compute Gallery
imageOffer | string | Gallery Image Offer, customImage must equal false
imagePublisher | string | Gallery Image Publisher, customImage must equal false
imageSku | string | Gallery Image Sku, customImage must equal false
localadminUsername | string | local administrator user
localadminPassword | secret | local administrator password
domainJoinUsername | string | UPN of Domain Admin.  Example: localadmin@test.com
domainJoinPassword | secret | Password for Domain Join account
domainFqdn | string | FQDN of the Domain you are wanting to Join or Create
ouPath | string | Distinguished Name of Target OU
location | string | Target Azure Region
hostpoolResourceId | string | Resource ID of target Azure Virtual Desktop Host Pool
managedIdentityId | string | User Managed Identity Resource ID
virtualNetworkId | string | Resource ID of Target Virtual Network
subnetName | string | Name of Target Subnet
useAvailabilityZones | bool | Span hosts accross Availabiltiy Zones
tags | object | Resource Tags


# Sample Module

```Bicep
resource keyvault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: 'avd-keyvault-luke'  
}

module avd '../Standard-Deployments/Simple-AVD-Scaleset/avd-scaleset.bicep' = {
  name: 'AVD-Deployment'
  scope: resourceGroup('avd-vmss')
  params: {
    newScaleSet: false
    scaleExisting: true
    managedIdentityId: '/subscriptions/00000000-0000-0000-00000000/resourcegroups/avd-vmss/providers/Microsoft.ManagedIdentity/userAssignedIdentities/keyvault-access'
    location: 'eastus'
    localadminUsername: 'localadmin'
    localadminPassword: keyvault.getSecret('vm-password') 
    domainFqdn: 'lukeprojects.com'
    domainJoinUsername: 'localadmin@lukeprojects.com'  
    domainJoinPassword: keyvault.getSecret('vm-password')
    vmCount: 1
    scaleSetName: 'avdvmss'
    hostpoolResourceId: '/subscriptions/00000000-0000-0000-00000000/resourceGroups/avd-vmss/providers/Microsoft.DesktopVirtualization/hostpools/avd-vmss' 
//    customImage: true
//    customImageResourceId: '/subscriptions/00000000-0000-0000-00000000/resourceGroups/avd-vmss/providers/Microsoft.Compute/galleries/avdgallery/images/Windows11/versions/2022.10.5'  
    imageOffer: 'office-365'
    imagePublisher: 'microsoftwindowsdesktop'
    imageSku: '21h1-evd-o365pp'
    ouPath: 'OU=New-WVD,DC=lukeprojects,DC=com' 
    subnetName: 'VDI'
    virtualNetworkId: '/subscriptions/00000000-0000-0000-00000000/resourceGroups/core-workloads-networking-eastus-rg/providers/Microsoft.Network/virtualNetworks/core-workloads-eastus-vnet'
    vmPrefix: 'avd5vm'  
    tags: {
      AutoStop: 'True'
    } 
    useAvailabilityZones: true
    vmSize: 'Standard_D4_v4'              
  }   
}

```
