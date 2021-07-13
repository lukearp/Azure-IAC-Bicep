param name string
param location string = resourceGroup().location
param tags object = {}

resource avSet 'Microsoft.Compute/availabilitySets@2020-12-01' = {
  name: name 
  location: location
  sku: {
   name: 'Aligned' 
  }
  properties: {     
  } 
  tags: tags  
}

output id string = avSet.id
