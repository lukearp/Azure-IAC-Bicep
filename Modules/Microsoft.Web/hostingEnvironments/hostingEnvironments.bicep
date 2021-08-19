param name string
@allowed([
  'ASEV2'
  'ASEV3'
])
param kind string = 'ASEV2'
param zoneRedundant bool = false
param dedicatedHostCount int = 0
param location string
param tags object = {}
param virtualNetworkName string
param virtualNetworkRg string
param aseSubnetName string
@allowed([
  'None' // External ASE
  'Web' // ILB With 80/443 only
  'Publishing' // ILB with FTP Only
  'Web, Publishing' // ISB with 80/443 and FTP
])
param internalLoadBalancingMode string = 'Web, Publishing'
param ipsslAddressCount int = 0

var subnetId = resourceId(virtualNetworkRg, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, aseSubnetName)

var properties = kind == 'ASEV2' ? {
  virtualNetwork: {
    id: subnetId
  }
  internalLoadBalancingMode: internalLoadBalancingMode
  ipsslAddressCount: ipsslAddressCount  
} : {
  dedicatedHostCount: dedicatedHostCount
  zoneRedundant: zoneRedundant
  InternalLoadBalancingMode: internalLoadBalancingMode
  virtualNetwork: {
      id: subnetId
  }
}

resource ase 'Microsoft.Web/hostingEnvironments@2020-12-01' = {
  name: name
  kind: kind
  location: location
  tags: tags 
  properties: properties
}

output aseId string = ase.id
