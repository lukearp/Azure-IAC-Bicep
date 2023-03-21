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
  'I1V2'
  'I2V2'
  'I3V2'
])
param skuName string
param aseId string = ''
param tags object = {}

var properties = aseId == '' ? {} : { hostingEnvironmentProfile: {
  id: aseId 
} }

resource appPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  location: location
  name: name
  sku: {
    tier: skuTier
    name: skuName
  }
  properties: properties
  tags: tags
}

output planId string = appPlan.id
