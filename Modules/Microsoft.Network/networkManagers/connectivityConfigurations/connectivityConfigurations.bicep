param networkManagerName string
param connectivityConfigName string
param networkGroupId string
param hubVnetId string
param description string

resource networkManager 'Microsoft.Network/networkManagers@2022-02-01-preview' existing = {
  name: networkManagerName 
}

resource symbolicname 'Microsoft.Network/networkManagers/connectivityConfigurations@2022-02-01-preview' = {
  name: connectivityConfigName
  parent: networkManager
  properties: {
    appliesToGroups: [
      {
        groupConnectivity: 'None'
        isGlobal: 'False'
        networkGroupId: networkGroupId
        useHubGateway: 'True'
      }
    ]
    connectivityTopology: 'HubAndSpoke'
    deleteExistingPeering: 'True'
    description: description
    hubs: [
      {
        resourceType: 'Microsoft.Network/virtualNetworks'
        resourceId: hubVnetId
      }
    ]
    isGlobal: 'False'
  }
}
