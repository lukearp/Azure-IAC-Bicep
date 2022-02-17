param zoneName string
param createARecord bool = false
param aRecordName string
param aRecordIp string

resource privateDns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: zoneName
  location: 'global' 
  properties: {         
  }  
}

resource records 'Microsoft.Network/privateDnsZones/A@2020-06-01' = if(createARecord) {
  name: aRecordName
  parent: privateDns
  properties: {
    aRecords: [
      {
        ipv4Address: aRecordIp 
      }  
    ]
    ttl: 300  
  }   
}

output zoneId string = privateDns.id
