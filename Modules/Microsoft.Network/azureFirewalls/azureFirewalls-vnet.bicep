param name string
param location string = resourceGroup().location
param policyId string
param pipId string
param subnetId string 
@allowed([
//  'Basic'
  'Standard'
  'Premium'
])
param tier string
param useZones bool = true
param zones array = []
param tags object = {}

var azRegions = [
  'eastus'
  'eastus2'
  'centralus'
  'southcentralus'
  'usgovvirginia'
  'westus2'
  'westus3'
]

var zoneArray = useZones == true && contains(azRegions, location) ? zones == [] ? [
  '1'
  '2'
  '3'
] : zones : []

resource firewall 'Microsoft.Network/azureFirewalls@2021-02-01' = {
  name: name
  location: location
  zones: zoneArray 
  tags: tags
  properties: {
    firewallPolicy: {
      id: policyId 
    }
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          publicIPAddress: {
            id: pipId 
          }
          subnet: {
            id: subnetId 
          }  
        } 
      } 
    ]
    sku: {
      name: 'AZFW_VNet'
      tier: tier  
    }    
  }     
}
