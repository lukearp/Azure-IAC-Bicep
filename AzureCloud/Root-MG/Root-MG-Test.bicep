targetScope = 'tenant'
module mg '../../Modules/Microsoft.Management/managementGroups/managementGroups.bicep' = {
  name: 'Enterprise CloudTN'
  params: {
    displayName: 'Enterprise CloudTN'
    id: 'Enterprise_Management_Group'
    subscriptions: []    
  }  
}
