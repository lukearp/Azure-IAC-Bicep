param name string
param netappFilesName string
param location string
@minValue(4398046511104)
param size int = 4398046511104
@allowed([
  'Premium'
  'Standard'
  'StandardZRS'
  'Ultra'
])
param serviceLevel string
param tags object = {}

resource netappFiles 'Microsoft.NetApp/netAppAccounts@2022-03-01' existing = {
  name: netappFilesName  
}

resource capacityPool 'Microsoft.NetApp/netAppAccounts/capacityPools@2022-03-01' = {
  location: location
  name: name
  parent: netappFiles
  tags: tags
  properties: {
   serviceLevel: serviceLevel
   size: size 
  }    
}
