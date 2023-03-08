param name string
param location string
@allowed([
  'WorkflowStandard' 
])
param skuTier string
@allowed([
  'WS1'
  'WS2'
  'WS3'
])
param skuName string
param tags object = {}

resource appPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  location: location
  name: name
  sku: {
     tier: skuTier
     name: skuName
  }
  properties: {  
  } 
  tags: tags    
}

output planId string = appPlan.id
