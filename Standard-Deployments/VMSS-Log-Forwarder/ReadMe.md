# What does this module do?
Deploys an Rsyslog Forwarder VM Scale Set for Syslog and CEF injestion to Log Analytics.  Has autoscaling enabled to dynamically scale appliance based on CPU utilization. 

[Based on Template found here](https://github.com/ScottMetzel/Azure-Sentinel/blob/create-cef-vmss-no-net-template-variants/DataConnectors/CEF-VMSS-No-VNET/CEF-VMSS-RH-NoNet-NoSW-Template.json).

# What does this module Require?
A virtual network and Log Analytics workspace to connect the VM Instances to.  

# Parameters
param | type | notes
------|------|------
targetResourceGroup | string | Resource Group that the VMSS will be deployed to.
location | string | Azure Region
baseName | string | Name of VMSS
autoscaleMin | int | Minimum number of collectors
autoscaleMax | int | Maximum number of collectors
instanceSize | string | VM Instance size, Example: Standard_F4s_v2
diskSize | int | Size of OS Disk
osImage | string | What linux image to deploy.  Currently only Ubuntu is supported.
adminUserName | string | Username for local admin account on VM.
adminPassword | securestring | Password for local admin account.
stroageAccountName | string | Name of diagnostic storage account.
deployNewStorageAccount | bool | If storage account already exists, set to false.
workspaceId | string | ID Of Log Analytics Workspace
workspaceKey | string | Workspace Primary Key
vNetResourceID | string | Target VNET Resource ID where VMSS will be deployed.
lbSubnetName | string | Subnet that Load Balancer will be deployed in.
vmssSubnetName | string | Subnet VMSS will be deployed in.
loadBalancerAccessibility | string | Internal or External on Load Balancer 
loadBalancerFrontendIPIsStatic | bool | Should Private IP be static or dynamic
loadBalancerFrontendPrivateStaticIPAddress | string | If loadBalancerFrontendIPIsStatic is set to true, define the IP of the LB.
tags | object | Tags

# Sample Module

```bicep
targetScope = 'subscription'
resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: 'KEYVAULTNAME'
  scope: resourceGroup('KEYVAULTRG')   
}

module syslog 'cef-vmss-forwarder.bicep' = {
  name: 'CEF-Deploy'
  params: {
    targetResourceGroup: 'MyRg'
    location: 'eastus'
    BaseName: 'syslog'
    AutoscaleMin: 1
    AutoscaleMax: 5
    InstanceSize: 'Standard_F4s_v2'
    DiskSize: 64
    OSImage: 'UbuntuServer-20.04-LTS'
    AdminUserName: 'localadmin' 
    AdminPassword: keyVault.getSecret('password')
    StroageAccountName: 'lukestoragesyslogeastus'
    DeployNewStorageAccount: false
    WorkspaceId: '11111-1111-111-111'
    WorkspaceKey: keyVault.getSecret('workspacekey')
    VNetResourceID: '/subscriptions/xxxxx/resourceGroups/rg_sysloglab/providers/Microsoft.Network/virtualNetworks/syslog-vnet' 
    LBSubnetName: 'lb'
    VMSSSubnetName: 'vm'
    LoadBalancerAccessibility: 'Internal'
    LoadBalancerFrontendIPIsStatic: false
    tags: {
      My: 'Tag'
    }        
  }
}
```