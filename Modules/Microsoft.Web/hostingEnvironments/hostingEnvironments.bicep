param name string
@allowed([
  'ASEV2'
])
param kind string = 'ASEV2'
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

resource ase 'Microsoft.Web/hostingEnvironments@2020-12-01' = {
  name: name
  kind: kind
  location: location
  tags: tags 
  properties: {
    virtualNetwork: {
      id: subnetId
    }
    internalLoadBalancingMode: internalLoadBalancingMode
    ipsslAddressCount: ipsslAddressCount  
  }
}

output aseId string = ase.id
