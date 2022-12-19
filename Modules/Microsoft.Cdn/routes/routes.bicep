param fdName string
param endpointName string
param name string

resource frontdoor 'Microsoft.Cdn/profiles@2021-06-01' existing = {
   name: fdName
}

resource endpoint 'Microsoft.Cdn/profiles/afdEndpoints@2022-05-01-preview' existing = {
  name: endpointName
  parent: frontdoor 
}

resource routes 'Microsoft.Cdn/profiles/afdEndpoints/routes@2022-05-01-preview' = {
  name: name
  parent: endpoint
  properties: {
      
  }  
}
