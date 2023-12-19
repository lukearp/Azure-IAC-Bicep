param name string
param location string
@allowed([
  'S1'
  'S2'
  'S3'
])
param sku string

resource plan 'Microsoft.Web/serverfarms@2023-01-01' = {
  location: location
  name: name
  sku: {
     name: sku
     tier: sku 
  } 
  properties: {
     
  }  
}

output id string = plan.id
