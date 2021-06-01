param name string
param location string = resourceGroup().location

resource avSet 'Microsoft.Compute/availabilitySets@2020-12-01' = {
  name: name 
  location: location
  sku: {
   name: 'Aligned' 
  }
  properties: {     
  }  
}

output id string = avSet.id
