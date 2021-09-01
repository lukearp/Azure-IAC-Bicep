param location string = resourceGroup().location
param name string
param skuCapacity int
@allowed([
  'Basic'
  'Consumption'
  'Developer'
  'Isolated'
  'Premium'
  'Standard'
])
param skuName string
param tags object = {}
@allowed([
 'External'
 'Internal'
 'None'
])
param virtualNetworkType string
param additionalLocations array
param certificates array
param emailAddress string
param publisherName string
param subnetId string

var properties = virtualNetworkType != 'None' ? {
  virtualNetworkType: virtualNetworkType
  additionalLocations: additionalLocations
  certificates: certificates
  publisherEmail: emailAddress
  publisherName: publisherName
  virtualNetworkConfiguration: {
    subnetResourceId: subnetId 
  }         
} : {
  virtualNetworkType: virtualNetworkType
  additionalLocations: additionalLocations
  certificates: certificates
  publisherEmail: emailAddress
  publisherName: publisherName
}

resource apiManagement 'Microsoft.ApiManagement/service@2020-06-01-preview' = {
  location: location
  name: name
  sku: {
   capacity: skuCapacity
   name: skuName    
  } 
  properties: properties
  tags: tags 
}
