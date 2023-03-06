param subnetId string

resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: split(subnetId,'/')[8] 
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  name: split(subnetId,'/')[10]
  parent: vnet  
}

module subnetSetup 'subnetSetup.bicep' = {
  name: '${split(subnetId,'/')[10]}-Subnet-Setup'
  params: {
    subnetId: subnet.id
    properties: subnet.properties
  }   
}

output properties object = subnet.properties
