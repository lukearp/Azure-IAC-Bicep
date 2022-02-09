targetScope = 'tenant'
param rootMgName string
param platformMgName string
param platformChildMgs array
param landingZoneMgName string
param landingZoneChildMgs array
param existingSubscriptions array = []
param rbacAssignments array = []

/*
existingSubscriptions Object = 
{
  mg: 'mgName'
  id: 'subid'
}

rbacAssignments Object =
{
  mg: 'mgName'
  roleId: 'roleId'
  objectId: 'AAD ObjectID'
  name: 'Name for Assignment'
}
*/

resource RootMg 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: rootMgName
  properties: {
    displayName: rootMgName  
  }  
}

resource PlatformMg 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: platformMgName 
  properties: {
    details: {
      parent: {
        id: RootMg.id
      } 
    }
    displayName: platformMgName  
  } 
}

resource childPlatformMg 'Microsoft.Management/managementGroups@2021-04-01' = [for child in platformChildMgs : {
 name: child
 properties: {
   details: {
    parent: {
      id: PlatformMg.id
    } 
  }
  displayName: child 
 }  
}]

resource LandingZoneMg 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: landingZoneMgName 
  properties: {
    details: {
      parent: {
        id: RootMg.id
      } 
    }
    displayName: landingZoneMgName  
  } 
}

resource childLandingZoneMg 'Microsoft.Management/managementGroups@2021-04-01' = [for child in landingZoneChildMgs : {
  name: child
  properties: {
    details: {
      parent: {
        id: LandingZoneMg.id
      }
    }
    displayName: child
  }  
 }]

resource subscriptions 'Microsoft.Management/managementGroups/subscriptions@2021-04-01' = [for sub in existingSubscriptions: {
  name: '${sub.mg}/${sub.id}'
  dependsOn: [
    childLandingZoneMg
    childPlatformMg
  ] 
}]

module rbac '../../Modules/Microsoft.Authorization/roleAssignments/roleAssignments-mg.bicep' = [for assignment in rbacAssignments: {
  name: 'RBAC-${assignment.mg}'
  scope: managementGroup(assignment.mg) 
  params: {
    managementGroupName: assignment.mg
    objectId: assignment.objectId  
    name: assignment.name
    roleDefinitionId: assignment.roleId
  }
  dependsOn: [
    childLandingZoneMg
    childPlatformMg
  ]  
}]
