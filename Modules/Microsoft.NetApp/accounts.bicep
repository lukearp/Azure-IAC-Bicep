param name string
param location string
param tags object = {}
param activeDirectories array = []

resource netapp 'Microsoft.NetApp/netAppAccounts@2022-03-01' = {
  name: name
  location: location
  tags: tags
  properties: {
     activeDirectories: activeDirectories
  }   
}
