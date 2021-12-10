targetScope = 'subscription'
param offerName string
param description string
param managedByTenantId string
param authorizations array
param eligibleAuthorizations array = []

/*
authorization example
[
  { 
    principalId: '00000000-0000-0000-0000-000000000000'
    roleDefinitionId: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
    principalIdDisplayName: 'Readers'
  }
]

eligibleAuthorizations example
[
  {
    justInTimeAccessPolicy: {
      multiFactorAuthProvider: 'Azure'
      maximumActivationDuration: 'PT8H'
      managedByTenantApprovers: [
        {
          principalId: '00000000-0000-0000-0000-000000000000'
          principalIdDisplayName: 'PIM-Approver'
        }
      ]
    } 
    principalId: '00000000-0000-0000-0000-000000000000'
    roleDefinitionId: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
    principalIdDisplayName: 'Tier 2 Support'
  }
]
*/

var mspRegistrationName = guid(offerName)

resource lightHouse 'Microsoft.ManagedServices/registrationDefinitions@2020-02-01-preview' = {
  name: mspRegistrationName
  properties: {
    registrationDefinitionName: offerName
    description: description
    managedByTenantId: managedByTenantId
    authorizations: authorizations
    eligibleAuthorizations: eligibleAuthorizations
  }
}
