param zoneName string

resource privateDns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: zoneName
  location: 'global' 
  properties: {
         
  }  
}

output zoneId string = privateDns.id
