targetScope = 'managementGroup'
module mg '../../../Modules/Microsoft.Management/managementGroups/managementGroups.bicep' = {
  name: 'Enterprise CloudTN'
  scope: tenant()
  params: {
    displayName: 'Enterprise CloudTN'
    id: 'Enterprise_Management_Group'
    subscriptions: []    
  }  
}

module role 'RoleAssignments/rbacAssginments.bicep' = {
  name: '${mg.name}-Roles'
}
