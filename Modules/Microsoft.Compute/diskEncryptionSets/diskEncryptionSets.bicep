param name string
param keyUrl string
param location string
@allowed([
  'User'
  'System'
])
param identityType string = 'System'
param userAssignedIdentityResourceId string = ''

var identity = identityType == 'System' ? {
    type: 'SystemAssigned' 
  } : {
  type: 'UserAssigned' 
  userAssignedIdentities: {
    '${userAssignedIdentityResourceId}': {
      
    }
  } 
} 

resource diskEncryptionSet 'Microsoft.Compute/diskEncryptionSets@2023-10-02' = {
  location: location
  name: name
  identity: identity
  properties: {
    rotationToLatestKeyVersionEnabled: true
    encryptionType: 'EncryptionAtRestWithCustomerKey'
    activeKey: {
      keyUrl: keyUrl
    }   
  }   
}
