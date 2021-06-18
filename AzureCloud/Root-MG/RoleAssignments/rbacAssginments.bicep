targetScope = 'managementGroup'

var roleAssignments = [
 {
   name: 'myReaders'
   objectId: '1af6b404-5c92-4e91-b45f-19e2ae3ea75d' //ruarp
   roleDefinitionId: 'acdd72a7-3385-48ef-bd42-f606fba81ae7' //Reader
   managementGroupName: 'Enterprise_Management_Group'
 }
 {
  name: 'myVMContributors'
  objectId: '1af6b404-5c92-4e91-b45f-19e2ae3ea75d' //ruarp
  roleDefinitionId: '9980e02c-c2be-4d73-94e8-173b1dc7cf3c' //Virtual Machine Contributor
  managementGroupName: 'Enterprise_Management_Group'
}
]

module assignments '../../../Modules/Microsoft.Authorization/roleAssignments/roleAssignments-mg.bicep' = [for role in roleAssignments: {
  name: concat(role.name, '-deploy') 
  params: {
   name: role.name
   managementGroupName: role.managementGroupName
   objectId: role.objectId
   roleDefinitionId: role.roleDefinitionId  
  }
}]

