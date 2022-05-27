param name string
param location string
param tags object = {}

resource queryPack 'Microsoft.OperationalInsights/queryPacks@2019-09-01' = {
   name: name
   location: location
   properties: {
        
   } 
   tags: tags 
}
