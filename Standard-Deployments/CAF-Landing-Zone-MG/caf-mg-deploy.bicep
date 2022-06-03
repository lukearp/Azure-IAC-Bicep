targetScope = 'tenant'
param rootMgName string
param platformMgName string
param platformChildMgs array
param landingZoneMgName string
param landingZoneChildMgs array
param existingSubscriptions array = []
param rbacAssignments array = []
param policyAssignments array = []
param virtualNetworks array = []
param defaultLocation string = 'eastus'

/*
existingSubscriptions Object = 
{
  mg: 'mgName'
  id: 'subid'
}

rbacAssignments Object =
{
  mg: 'mgName'
  roleId: 'roleId'
  objectId: 'AAD ObjectID'
  name: 'Name for Assignment'
}

virtualNetworks Object = 
{
  name: 'vnetName'
  subId: 'subid'
  vnetAddressSpace: '10.0.0.0/22'
  dnsServers: []
  type: 'Hub or Spoke'
  location: 'azure Region'
  resourceGroupName: 'rgName'
  nsgRules: []
  routes: []
  gateways: [
    {
      name: 'Core-VPN'
      size: 'VpnGw1'
      type: 'Vpn'
      activeActive: true
    }
  ]
  disableBgpRoutePropagation: 'bool'
  subnets: [
    {
      name: 'subname'
      addressPrefix: '10.0.0.0/24'
      nsg: 'bool'
      routeTable: 'bool'
    }
  ]
  tags: {}
}

policyAssignments Object =
{
  name: 'Name of Assignment'
  policyId: 'PolicyId'
  parameters: {
    param: {
      value: 'param'
    }
  }
  notScopes: [
    'resourceIds'
  ]
  mg: 'MG Id'
}
*/

resource RootMg 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: rootMgName
  properties: {
    displayName: rootMgName  
  }  
}

resource PlatformMg 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: platformMgName 
  properties: {
    details: {
      parent: {
        id: RootMg.id
      } 
    }
    displayName: platformMgName  
  } 
}

resource childPlatformMg 'Microsoft.Management/managementGroups@2021-04-01' = [for child in platformChildMgs : {
 name: child
 properties: {
   details: {
    parent: {
      id: PlatformMg.id
    } 
  }
  displayName: child 
 }  
}]

resource LandingZoneMg 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: landingZoneMgName 
  properties: {
    details: {
      parent: {
        id: RootMg.id
      } 
    }
    displayName: landingZoneMgName  
  } 
}

resource childLandingZoneMg 'Microsoft.Management/managementGroups@2021-04-01' = [for child in landingZoneChildMgs : {
  name: child
  properties: {
    details: {
      parent: {
        id: LandingZoneMg.id
      }
    }
    displayName: child
  }  
 }]

resource subscriptions 'Microsoft.Management/managementGroups/subscriptions@2021-04-01' = [for sub in existingSubscriptions: {
  name: '${sub.mg}/${sub.id}'
  dependsOn: [
    childLandingZoneMg
    childPlatformMg
  ] 
}]

module rbac '../../Modules/Microsoft.Authorization/roleAssignments/roleAssignments-mg.bicep' = [for assignment in rbacAssignments: {
  name: 'RBAC-${assignment.name}'
  scope: managementGroup(assignment.mg) 
  params: {
    managementGroupName: assignment.mg
    objectId: assignment.objectId  
    name: assignment.name
    roleDefinitionId: assignment.roleId
  }
  dependsOn: [
    childLandingZoneMg
    childPlatformMg
  ]  
}]

module policy '../../Modules/Microsoft.Authorization/policyAssignments/policyAssignments-mg.bicep' = [for assignment in policyAssignments: {
  name: 'Policy-${assignment.name}'
  scope: managementGroup(assignment.mg)
  params: {
    location: defaultLocation
    name: assignment.name
    notScopes: assignment.notScopes
    parameters: assignment.parameters
    policyId: assignment.policyId  
  } 
}]

module rgVnet '../../Modules/Microsoft.Resources/resourceGroups/resourceGroups.bicep' = [for rg in virtualNetworks: {
  name: '${rg.resourceGroupName}-Deploy'
  scope: subscription(rg.subId)
  params: {
    location: rg.location
    name: rg.resourceGroupName
    tags: rg.tags   
  }
}] 

module vnetSpokes 'spokeNetworking.bicep' = [for (vnet,i) in virtualNetworks: if(toLower(vnet.type) == 'spoke') {
  scope: resourceGroup(vnet.subId,vnet.resourceGroupName)
  name: 'VNET-Deploy-${vnet.name}-${vnet.location}'
  params: {
    name: vnet.name
    vnetAddressSpace: vnet.vnetAddressSpace
    dnsServers: vnet.dnsServers
    location: vnet.location
    nsgRules: vnet.nsgRules
    routes: vnet.routes
    subnets: vnet.subnets
    disableBgpRoutePropagation: vnet.disableBgpRoutePropagation
    tags: vnet.tags
  }
  dependsOn: [
    rgVnet
  ] 
}]

module vnetHubs 'hubNetworking.bicep' = [for(vnet,i) in virtualNetworks: if(toLower(vnet.type) == 'hub'){
  name: 'VNET-Deploy-${vnet.name}'
  scope: resourceGroup(vnet.subId,vnet.resourceGroupName)
  params: {
    name: vnet.name
    vnetAddressSpace: vnet.vnetAddressSpace
    dnsServers: vnet.dnsServers
    location: vnet.location
    nsgRules: vnet.nsgRules
    routes: vnet.routes
    subnets: vnet.subnets
    disableBgpRoutePropagation: vnet.disableBgpRoutePropagation
    gateways: vnet.gateways
    tags: vnet.tags 
  }
  dependsOn: [
    rgVnet
  ]  
}]
