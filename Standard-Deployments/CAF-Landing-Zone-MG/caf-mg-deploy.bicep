targetScope = 'tenant'
param rootMgName string
param platformMgName string
param platformChildMgs array
param landingZoneMgName string
param landingZoneChildMgs array
param existingSubscriptions array = []

/*
Subscription Object = 
{
  mg: 'mgName'
  id: 'subid'
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
