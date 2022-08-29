param zoneName string
param createARecord bool = false
param vnetAssociations array = []
param aRecordName string
param aRecordIp string

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
