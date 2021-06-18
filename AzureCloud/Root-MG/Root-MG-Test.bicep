targetScope = 'managementGroup'
var managementGroupId = 'Enterprise_Management_Group'
module mg '../../Modules/Microsoft.Management/managementGroups/managementGroups.bicep' = {
  name: 'EnterpriseCloudTN'
  scope: tenant()
  params: {
    displayName: 'Enterprise CloudTN'
    id: managementGroupId
    subscriptions: []    
  }  
}

module role 'RoleAssignments/rbacAssginments.bicep' = {
  name: '${mg.name}-RoleAssignments'
  scope: managementGroup(managementGroupId)
  dependsOn: [
    mg 
  ]
}
