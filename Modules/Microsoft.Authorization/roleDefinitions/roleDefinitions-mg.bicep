targetScope = 'managementGroup'
param roleName string
param assignableScopes array
param actions array
param description string

resource role 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' = {
  name: guid(roleName)
  properties: {
    assignableScopes: assignableScopes
    permissions: [
      {
        actions: actions
      }
    ]
    roleName: roleName
    description: description
    //type: 'Custom'     
  }  
}

output id string = role.id
