param name string
param location string
@allowed([
  'PerGB2018'
  'CapacityReservation'
])
param sku string = 'PerGB2018'
param capacityReservationLevel int = 0
param retentionInDays int = 30
param dailyQuotaGB int = 0
param tags object = {}

var skuObject = sku == 'CapacityReservation' ? {
  name: sku
  capacityReservationLevel: capacityReservationLevel   
} : {
  name: sku   
}

var capping = dailyQuotaGB == 0 ? {
  sku: skuObject
  retentionInDays: retentionInDays   
} : {
  sku: skuObject
  retentionInDays: retentionInDays
  workspaceCapping: {
    dailyQuotaGb: dailyQuotaGB 
  }    
} 

resource workspaces 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: name
  location: location
  properties: {
    sku: skuObject
    retentionInDays: retentionInDays
    workspaceCapping: {
      dailyQuotaGb: dailyQuotaGB 
    }    
  } 
  tags: tags 
}
