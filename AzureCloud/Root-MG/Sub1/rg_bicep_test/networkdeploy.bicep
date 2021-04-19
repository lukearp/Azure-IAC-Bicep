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
    networkSecurityGroup: 'NSG_mysub_${resourceGroup().location}'
    routeTable: 'testRT'
  }
]

module nsg '../../../../Modules/Microsoft.Network/networkSecurityGroups/networkSecurityGroups.bicep' = [for subnet in vnetSubnets: {
   name: 'NSG_Deploy'
   params:{
     nsgName: 'NSG_${subnet.name}_${resourceGroup().location}' 
   } 
}]

module vnet '../../../../Modules/Microsoft.Network/virtualNetworks/virtualNetworks.bicep' = {
  name: 'VNET_Deploy'
  dependsOn: [
    nsg
  ] 
  params:{
    vnetName: vnetName
    vnetAddressSpaces: vnetAddressSpaces
    vnetDnsServers: vnetDnsServers
    vnetSubnets: vnetSubnets  
  } 
}
