param vnetName string = 'test'
param vnetAddressSpaces array = [
  '10.0.0.0/24'
]
param vnetDnsServers array = [
  '192.168.1.1'
  '192.168.1.2'
]
param vnetSubnets array = [
  {
    name: 'mysub'
    addressPrefix: '10.0.0.0/27'
  }
  {
    name: 'mysub2'
    addressPrefix: '10.0.0.32/27'
  }
]

var nsgArray = [for subnet in vnetSubnets: {
  name: 'NSG_${subnet.name}'
}]

module nsg '../../../../Modules/Microsoft.Network/networkSecurityGroups/networkSecurityGroups.bicep' = {
   name: 'NSG_Deploy'
   params:{
     nsgs: nsgArray
   } 
}

module vnet '../../../../Modules/Microsoft.Network/virtualNetworks/virtualNetworks.bicep' = {
  name: 'VNET_Deploy'
  params:{
    vnetName: vnetName
    vnetAddressSpaces: vnetAddressSpaces
    vnetDnsServers: vnetDnsServers
    vnetSubnets: vnetSubnets  
    networkSecurityGroups: nsg.outputs.nsgIds
  } 
}
