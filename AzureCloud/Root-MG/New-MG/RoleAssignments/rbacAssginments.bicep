targetScope = 'managementGroup'

var roleAssignments = [
 {
   name: 'myReaders'
   objectId: '2b35339c-8a54-465b-8a17-9e6ed27a70a4' //ruarp
   roleDefinitionId: 'acdd72a7-3385-48ef-bd42-f606fba81ae7' //Reader
   managementGroupName: 'LukeInternal'
 }
 {
  name: 'myVMContributors'
  objectId: '2b35339c-8a54-465b-8a17-9e6ed27a70a4' //ruarp
  roleDefinitionId: '9980e02c-c2be-4d73-94e8-173b1dc7cf3c' //Virtual Machine Contributor
  managementGroupName: 'LukeInternal'
}
]

module assignments '../../../../Modules/Microsoft.Authorization/roleAssignments/roleAssignments-mg.bicep' = [for role in roleAssignments: {
  name: concat(role.name, '-deploy') 
  params: {
   name: role.name
   managementGroupName: role.managementGroupName
   objectId: role.objectId
   roleDefinitionId: role.roleDefinitionId  
  }
}]

