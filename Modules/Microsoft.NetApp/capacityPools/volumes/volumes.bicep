param name string
param location string
param subnetId string
param shareName string = name
param protocolTypes array = [
  'NFSv4.1'
]
@allowed([
  'Basic'
  'Standard'
])
param networkFeatures string = 'Basic'
@minValue(100)
@maxValue(1000)
param sizeThreshold int = 100
param zones array = []
param netappFilesName string
param netappCapacityPoolName string
param tags object = {}

resource netappFiles 'Microsoft.NetApp/netAppAccounts@2022-03-01' existing = {
  name: netappFilesName  
}

resource netappFilesCapacityPool 'Microsoft.NetApp/netAppAccounts/capacityPools@2022-03-01' existing = {
  name: netappCapacityPoolName
  parent: netappFiles 
}

resource volume 'Microsoft.NetApp/netAppAccounts/capacityPools/volumes@2022-03-01' = {
  location: location
  name: name
  parent: netappFilesCapacityPool
  tags: tags
  zones: zones
  properties: {
    subnetId: subnetId
    protocolTypes: protocolTypes
    creationToken: shareName
    usageThreshold: sizeThreshold  
    networkFeatures: networkFeatures
  }     
}
