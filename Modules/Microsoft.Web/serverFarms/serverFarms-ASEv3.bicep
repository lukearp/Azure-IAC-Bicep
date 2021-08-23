param name string
param location string
param aseRg string
param aseName string
@allowed([
  'I1V2'
  'I2V2'
  'I3V2'
])
param size string

resource plan 'Microsoft.Web/serverfarms@2021-01-15' = {
  name: name
  location: location
  sku: {
    family: 'IsolatedV2'
    size: size
    name: size   
  }
  properties: {
    hostingEnvironmentProfile: {
      id: resourceId(aseRg,'Microsoft.Web/hostingEnvironments',aseName)
    }  
  }    
}
