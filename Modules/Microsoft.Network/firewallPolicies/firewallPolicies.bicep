@allowed([
  'Basic'
  'Premium'
  'Standard'
])
param firewallTier string = 'Standard'
param privateRanges array = [
  '10.0.0.0/8'
  '192.168.0.0/16'
  '172.16.0.0/12'
  '100.64.0.0/10'
]
param tags object = {
  
}
param location string
param name string
param basePolicy string = ''

var policyProperties = basePolicy == '' ? {
  sku: {
    tier: firewallTier 
  }
  snat: {
    privateRanges: privateRanges
    autoLearnPrivateRanges: 'Disabled'  
  }  
} : {
  basePolicy: {
    id: basePolicy 
  } 
  sku: {
    tier: firewallTier 
  }
  snat: {
    privateRanges: privateRanges
    autoLearnPrivateRanges: 'Disabled'  
  }  
}

resource policy 'Microsoft.Network/firewallPolicies@2022-05-01' = {
  name: name 
  location: location
  tags: tags
  properties: policyProperties    
}

output resourceId string = policy.id
