param networkManagerName string
param networkGroupName string
param tagName string
param description string

resource networkManager 'Microsoft.Network/networkManagers@2022-02-01-preview' existing = {
  name: networkManagerName 
}

resource networkGroup 'Microsoft.Network/networkManagers/networkGroups@2022-02-01-preview' = {
  name: networkGroupName
  parent: networkManager 
  properties: {
    description: description
    memberType: 'string' 
    conditionalMembership: '{\n   "allOf": [\n      {\n         "field": "tags[\'${tagName}\']",\n         "exists": true\n      }\n   ]\n}'
  }
}

output groupId string = networkGroup.id
