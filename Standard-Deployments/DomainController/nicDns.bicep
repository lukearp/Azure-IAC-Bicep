param nics array
param dnsServers array
param count int
param location string

var dnsIps = [for i in range(0,count): nics[i].ipConfigurations[0].properties.privateIPAddress ]

resource nicsDns 'Microsoft.Network/networkInterfaces@2020-11-01' = [for i in range(0,count): {
  name: nics[i].name
  location: location 
  properties: {
    dnsSettings: {
      dnsServers: concat(dnsIps, dnsServers) 
    }
    ipConfigurations: nics[i].ipConfigurations 
  }  
}]

output nicIds array = [for i in range(0,count): {
  id: nicsDns[i].id
}]
