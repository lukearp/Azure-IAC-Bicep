param name string
param appServicePlanId string
@allowed([
  'Enabled'
  'Disabled'
])
param publicAccess string = 'Enabled'
param location string

resource webApp 'Microsoft.Web/sites@2023-01-01' = {
   location: location
   name: name
   properties: {
     serverFarmId: appServicePlanId
     publicNetworkAccess: publicAccess 
   }    
}
