param zoneName string
param createARecord bool = false
param vnetAssociations array = []
param aRecordName string = ''
param aRecordIp string = ''

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

module records 'DNSRecord/dnsRecord.bicep' = if(createARecord) {
  name: '${aRecordName}-${aRecordIp}-record'
  params: {
    dnsZoneName: zoneName
    hostName: aRecordName
    recordTarget: aRecordIp
    recordType: 'A'
    recordTtl: 300     
  }    
}

resource virtualNetwork 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for vnetAssociation in vnetAssociations : {
  name: split(vnetAssociation.id,'/')[8]
  parent: privateDns
  location: 'global'
  properties: {
    registrationEnabled: vnetAssociation.registrationEnabled
    virtualNetwork: {
      id: vnetAssociation.id 
    }  
  }    
}]

output zoneId string = privateDns.id
