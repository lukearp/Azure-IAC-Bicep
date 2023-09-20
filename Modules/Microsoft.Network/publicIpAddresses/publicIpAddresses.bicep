param name string
@allowed([
  'Basic'
  'Standard'
])
param sku string
@allowed([
  'Regional'
  'Global'
])
param tier string
@allowed([
  'IPv4'
  'IPv6'
])
param publicIpAddressVersion string
@allowed([
  'Static'
  'Dynamic'
])
param publicIpAllocationMethod string
param zones array = []
param location string = resourceGroup().location
param tags object = {}

resource pip 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: name
  location: location
  zones: zones 
  sku: {
    name: sku
    tier: tier  
  }
  properties:{
    publicIPAddressVersion: publicIpAddressVersion
    publicIPAllocationMethod: publicIpAllocationMethod        
  }  
  tags: tags 
}

output pipid string = pip.id
output ipAddress string = pip.properties.ipAddress
