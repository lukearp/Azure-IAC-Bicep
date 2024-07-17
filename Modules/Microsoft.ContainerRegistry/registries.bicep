param name string
param location string
@allowed([
  'Basic'
  'Premium'
  'Classic'
  'Standard'
])
param sku string = 'Basic'
param adminUserEnabled bool = false
param anonymousPullEnabled bool = false
@allowed([
  'Enabled'
  'Disabled'
])
param zoneRedundancy string = 'Disabled'
param ipRules array = []
@allowed([
  'Allow'
  'Deny'
])
param networkDefaultAction string = 'Allow'
param tags object = {}

resource acr 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' = {
  name: name
  location: location
  sku: {
    name: sku 
  } 
  identity: {
    type: 'SystemAssigned' 
  } 
  properties: {
    adminUserEnabled: adminUserEnabled
    anonymousPullEnabled: anonymousPullEnabled 
    zoneRedundancy: zoneRedundancy 
    networkRuleSet: {
      defaultAction: networkDefaultAction
      ipRules: ipRules 
    }      
  } 
  tags: tags 
}

output acrId string = acr.id
