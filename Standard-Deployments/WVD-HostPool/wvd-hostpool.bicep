param splitTenant bool = false
param wvdTenantId string
param keyVaultSecretId string
param hostPoolName string
param hostPoolResourceGroupName string
param hostPoolSubscription string
param virtualNetworkId string
param subnetName string
param location string = resourceGroup().location
param adminUsername string
@secure()
param adminPassword string
param vmSize string = 'Standard_D4_v4'
param artifcatLocation string = 'https://location.com'

resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: split(keyVaultSecretId,'/')[8]
  scope: resourceGroup(split(keyVaultSecretId,'/')[4]) 
}
