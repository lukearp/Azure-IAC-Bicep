targetScope = 'subscription'
@secure()
param domainAdminPassword string
var domainName = 'lukeprojects.com'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  location: 'eastus'
  name: 'domain-controllers'
  tags: {
    Environment: 'Prod' 
  }   
}

module managedIdentity '../../../../../Modules/Microsoft.ManagedIdentity/userAssignedIdentities.bicep' = {
  name: '${domainName}-Deploy-Managed-Identity'
  scope: resourceGroup(rg.name)
  params: {
    location: 'eastus'
    name: '${replace(domainName,'.','-')}-mi'
    tags: {
      Environment: 'Prod'
    }   
  }  
}

module rbacAssignment '../../../../../Modules/Microsoft.Authorization/roleAssignments/roleAssignments-rg.bicep' = {
  name: '${domainName}-Deploy-Managed-Identity-RBAC'
  scope: resourceGroup(rg.name)
  params: {
    name: '${domainName}-${managedIdentity.outputs.principalId}'
    objectId: managedIdentity.outputs.principalId
    roleDefinitionId: 'b24988ac-6180-42a0-ab88-20f7382dd24c'   
  }  
}

module subnetAdd '../../../../../Modules/Microsoft.Network/virtualNetworks/subnets/subnets.bicep' = {
  name: '${domainName}-Deploy-Subnet'
  scope: resourceGroup('core-workloads-networking-eastus-rg')
  params: {
    addressPrefix: '10.0.16.0/28'
    subnetName: 'DomainControllers'
    vnetname: 'core-workloads-eastus-vnet'
    nsgName: 'core-workloads-eastus-vnet-eastus-nsg'
    routeTableName: 'core-workloads-eastus-vnet-eastus-rt'    
  }  
}

module dc '../../../../../Standard-Deployments/DomainController/DomainController.bicep' = {
  name: '${domainName}-DomainController-Deployment'
  scope: resourceGroup(rg.name)
  params: {
     domainAdminUsername: 'localadmin@lukeprojects.com'
     domainAdminPassword: domainAdminPassword 
     domainFqdn: domainName
     localAdminUsername: 'localadmin'
     localAdminPassword: domainAdminPassword
     newForest: false
     ntdsSizeGB: 20
     subnetName: split(subnetAdd.outputs.subnetId,'/')[10]
     sysVolSizeGB: 20
     ahub: true
     count: 2
     location: 'eastus' 
     managedIdentityId: managedIdentity.outputs.resourceId
     vmNamePrefix: 'DC'
     vnetId: resourceId('32eb88b4-4029-4094-85e3-ec8b7ce1fc00','core-workloads-networking-eastus-rg','Microsoft.Network/virtualNetworks','core-workloads-eastus-vnet')            
  }  
}
