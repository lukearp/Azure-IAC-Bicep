targetScope = 'subscription'
param vnetName string
param resourceGroupName string
param projectTagValue string
param existingVnet bool
@minValue(0)
@maxValue(255)
param addressspaceOctet3int int
@allowed([
  '25'
  '24'
  '23'
  '22'
])
param CIDR string
@metadata({
  description: 'Example: ["10.20.10.10","10.20.11.10"]'
})
param dnsServers array
@metadata({
  description: 'Additional Subnets True False'
})
param additionalSubnet bool
param subnets array
param hubVnetId string
param hubAddressSpace string
@allowed([
 'centralus'
 'eastus'
 'eastus2'
 'westus'
 'northcentralus'
 'southcentralus'
 'westcentralus'
 'westus2'
 'westus3'
])
param location string = 'eastus2'
param nvaIp string
param additionalAddressSpace array
param updateAddressSpace bool
param userManagedIdentityId string
param gatewayRtId string

var addressspaceOctet3 = string(addressspaceOctet3int)

var tags = {
  Project: projectTagValue
}

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  location: location
  name: resourceGroupName
  tags: tags  
  properties: {
    
  } 
}

module getExisting 'existingVnet.bicep' = if(existingVnet == true) {
  scope: resourceGroup(rg.name)
  name: 'Existing'
  params: {
    vnetName: vnetName 
  } 
}

module addiontalAddressSpace 'removepeers.bicep' = if(updateAddressSpace == true){
  name: 'Remove-Peers'
  scope: resourceGroup(rg.name)
  params: {
   hubVnet: hubVnetId
   spokeVnet: '${rg.id}/providers/Microsoft.Network/virtualNetworks/${vnetName}'
   location: location
   userAssignedIdentity: userManagedIdentityId       
  }   
}
//Set first two Octets
var addressSpace = '192.168.${addressspaceOctet3}.0/${CIDR}'
var existingSubnets = existingVnet == true ? getExisting.outputs.vnet.subnets : []
var aditionalSubnets = additionalSubnet == true ? subnets : []

module newVnet 'vnet.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'New-VNET'
  dependsOn: [
    getExisting
  ]
  params: {
    addressSpace: concat(array(addressSpace),additionalAddressSpace) 
    dnsServers: dnsServers
    location: location
    subnets: concat(existingSubnets,aditionalSubnets)
    vnetName: vnetName 
    hubVnetId: hubVnetId 
    hubAddressSpace: hubAddressSpace
    nvaIp: nvaIp
    gatewayRtId: gatewayRtId      
  }   
}

