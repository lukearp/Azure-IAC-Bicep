targetScope = 'managementGroup'
param name string
@allowed([
  'All'
  'Indexed'
])
param mode string
param dispalyName string
param policyRule object
param parameters object
resource policy 'Microsoft.Authorization/policyDefinitions@2020-09-01' = {    
  name: name
  properties: {
    displayName: dispalyName
    mode: mode
    policyRule: policyRule
    policyType: 'Custom'
    parameters: parameters   
 }
}
