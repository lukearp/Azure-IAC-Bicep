param vnetName string
param dnsServers array = []

resource dns 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: vnetName
}

var dnsUpdate =  union(dns.properties, {
  dhcpOptions: {
    dnsServers: dnsServers
  }
})

module updateDns 'setVnet.bicep' = {
  name: 'Update-DNS'
  params: {
    location: dns.location
    name: dns.name
    properties: dnsUpdate
    tags: dns.tags    
  } 
}
