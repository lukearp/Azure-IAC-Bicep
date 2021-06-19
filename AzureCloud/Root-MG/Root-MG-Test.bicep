targetScope = 'managementGroup'
var managementGroupId = 'Enterprise_Management_Group'
module mg '../../Modules/Microsoft.Management/managementGroups/managementGroups.bicep' = {
  name: 'Luke-Root-MG-Deploy'
  scope: tenant()
  params: {
    displayName: 'Luke-Root-MG'
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

module policyDefinitions 'PolicyDefinitions/policyDefintions.bicep' = {
  name: '${mg.name}-PolicyDefinitions'
  scope: managementGroup(managementGroupId) 
  dependsOn: [
    mg
  ] 
}

module policySetDefinitions 'PolicySetDefinitions/policySetDefinitions.bicep' = {
  name: '${mg.name}-PolicySetDefinitions'
  scope: managementGroup(managementGroupId) 
  dependsOn: [
    mg
  ] 
}

module policyAssignments 'PolicyAssignments/policyAssignments.bicep' = {
  name: '${mg.name}-PolicyAssignments'
  scope: managementGroup(managementGroupId)
  dependsOn: [
    policyDefinitions
    policySetDefinitions
  ] 
}


