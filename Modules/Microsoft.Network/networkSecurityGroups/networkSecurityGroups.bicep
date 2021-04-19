param nsgName string
param location string = resourceGroup().location

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules:[
      
    ] 
  } 
}

output nsgId string = nsg.id
