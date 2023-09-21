param zoneName string
param createARecord bool = false
param vnetAssociation string
param aRecordName string = ''
param aRecordIp string = ''
param tags object = {}

/*
vnetAssociations Object
{
  id: 'VNET Resource ID'
  registrationEnabled: true or false
}
*/

resource privateDns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: zoneName
  location: 'global' 
  properties: {           
  }  
}

module records '../../Modules/Microsoft.Network/privateDnsZones/DNSRecord/dnsRecord.bicep' = if(createARecord) {
  name: 'A-${aRecordIp}-record'
  dependsOn: [
    privateDns
  ]
  params: {
    dnsZoneName: zoneName
    hostName: aRecordName
    recordTarget: aRecordIp
    recordType: 'A'
    recordTtl: 300     
  }    
}

resource virtualNetwork 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: split(vnetAssociation,'/')[8]
  parent: privateDns
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetAssociation 
    }  
  }
  tags: tags     
}

output zoneId string = privateDns.id
