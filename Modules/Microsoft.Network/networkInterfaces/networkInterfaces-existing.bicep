param name string

resource nic 'Microsoft.Network/networkInterfaces@2022-01-01' existing = {
  name: name 
}

output ip string = nic.properties.ipConfigurations[0].properties.privateIPAddress
