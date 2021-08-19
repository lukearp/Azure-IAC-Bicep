targetScope = 'subscription'
param location string
param name string 
param tags object = {}

resource resourceGroupDef 'Microsoft.Resources/resourceGroups@2021-04-01' = {
   location: location
   name: name 
   tags: tags  
}

output resourceGroupId string = resourceGroupDef.id
