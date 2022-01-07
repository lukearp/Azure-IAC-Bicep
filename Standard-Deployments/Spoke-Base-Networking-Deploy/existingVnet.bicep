param vnetName string

resource existingVnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: vnetName 
}

output vnet object = existingVnet.properties
