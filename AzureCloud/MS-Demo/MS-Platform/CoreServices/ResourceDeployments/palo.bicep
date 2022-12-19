targetScope = 'subscription'
@secure()
param adminPassword string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  location: 'eastus'
  name: 'core-transit-palo-eastus'  
}

module managedIdentity '../../../../../Modules/Microsoft.ManagedIdentity/userAssignedIdentities.bicep' = {
  name: 'Palo-ManagedIdentity'
  scope: resourceGroup(rg.name)
  params: {
    location: 'eastus'
    name: 'palo-mi'
    tags: {
      Environment: 'Prod'
    }   
  }   
}

module rbacAssignment '../../../../../Modules/Microsoft.Authorization/roleAssignments/roleAssignments-rg.bicep' = {
  name: 'Palo-ManagedIdentity-Assignment'
  scope: resourceGroup(rg.name)
  params: {
    name: 'palo-mi-assignment'
    objectId: managedIdentity.outputs.principalId
    roleDefinitionId: 'b24988ac-6180-42a0-ab88-20f7382dd24c'   
  }   
}

module palo '../../../../../Standard-Deployments/PaloAlto-HA-Active_Active/paloAlto-ha-vmss.bicep' = {
  name: 'Palo-Deploy'
  scope: resourceGroup(rg.name)
  params: {
    adminUserName: 'localadmin'
    adminPasswordSecret: adminPassword
    count: 1
    managedIdentityId: managedIdentity.outputs.resourceId
    managementSubnetName: 'Mgmt'
    paloNamePrefix: 'transit'
    planName: 'byol'
    planOffer: 'vmseries-flex' 
    trustSubnetName: 'Trust'
    untrustSubnetName: 'Untrust'
    vmSize: 'Standard_DS3_v2'
    vnetId: resourceId('32eb88b4-4029-4094-85e3-ec8b7ce1fc00','core-transit-networking-eastus-rg','Microsoft.Network/virtualNetworks','core-transit-eastus-vnet') 
    imageVersion: 'latest'
    location: 'eastus'        
  }    
}
