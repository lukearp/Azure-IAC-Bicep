param name string
param location string
param allowBranchToBranchTraffic bool = true
@allowed([
  'Basic'
  'Standard'
])
param type string = 'Standard'
param tags object = {}

resource vwan 'Microsoft.Network/virtualWans@2022-05-01' = {
  name: name
  location: location
  properties: {
    allowBranchToBranchTraffic: allowBranchToBranchTraffic
    type: type 
  }
  tags: tags  
}

output vwanId string = vwan.id
