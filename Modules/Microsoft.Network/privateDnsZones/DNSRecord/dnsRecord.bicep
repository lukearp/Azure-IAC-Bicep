param hostName string
@allowed([
  'A'
])
param recordType string
param recordTarget string
param dnsZoneName string
param recordTtl int = 300

resource privateDns 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: dnsZoneName
}

resource records 'Microsoft.Network/privateDnsZones/A@2020-06-01' = if(recordType == 'A') {
  name: hostName
  parent: privateDns
  properties: {
    aRecords: [
      {
        ipv4Address: recordTarget 
      }  
    ]
    ttl: recordTtl  
  }   
}
