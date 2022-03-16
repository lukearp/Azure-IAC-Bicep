param location string
param name string
param tags object

resource pip 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: name
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'  
  }   
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: '${toLower(name)}vmss' 
    }  
  }
  tags:tags 
}

output id string = pip.id
