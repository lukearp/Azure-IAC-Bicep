targetScope = 'subscription'

param resourceGroupName string
param mlWorkspaceName string
param location string
param dnsZoneRgName string
param dnsZoneSubscriptionId string
param dnsVnetId string
param storageAccountName string
param appInsightsName string
param privateLinkSubnetId string
param keyVaultName string
param acrName string
param azureGovernment bool = false
param tags object = {}
param mlworkspacePrivateLinkName string = ''
param storagePrivateLinkBlobName string = ''
param storagePrivateLinkFileName string = ''
param storagePrivateLinkDfsName string = ''
param keyvaultPrivateLinkName string = ''
param acrPrivateLinkName string = ''

var storageSuffix = azureGovernment == false ? 'core.windows.net' : 'core.usgovcloudapi.net'
var acrPrivateDns = azureGovernment == false ? 'privatelink.azurecr.io' : 'privatelink.azurecr.us'
var keyvaultDns = azureGovernment == false ? 'privatelink.vaultcore.azure.net' : 'privatelink.vault.usgovcloudapi.net'
var mlApiDns = azureGovernment == false ? 'privatelink.api.azureml.ms' : 'privatelink.api.ml.azure.us'
var mlNotbookDns = azureGovernment == false ? 'privatelink.notebooks.azure.net' : 'privatelink.notebooks.usgovcloudapi.net'
var mlPlName = mlworkspacePrivateLinkName == '' ? '${mlWorkspaceName}-mlWorkspacePL' : mlworkspacePrivateLinkName
var storBlobPlName = storagePrivateLinkBlobName == '' ? '${mlWorkspaceName}-StorageBlobPL' : storagePrivateLinkBlobName
var stroFilePlName = storagePrivateLinkFileName == '' ? '${mlWorkspaceName}-StorageFilePL' : storagePrivateLinkFileName
var storDfsPlName = storagePrivateLinkDfsName == '' ? '${mlWorkspaceName}-StorageDfsPL' : storagePrivateLinkDfsName
var kvPlName = keyvaultPrivateLinkName == '' ? '${mlWorkspaceName}-KeyVaultPL' : keyvaultPrivateLinkName
var acrPlName = acrPrivateLinkName == '' ? '${mlWorkspaceName}-AcrPL' : acrPrivateLinkName

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module storage '../../Modules/Microsoft.Storage/storageAccounts/storageAccounts.bicep' = {
   name: '${mlWorkspaceName}-StorageDeployment'
   scope: resourceGroup(rg.name)
   params: {
    kind: 'StorageV2'
    location: location
    accessTier: 'Hot'
    sku: 'Standard_LRS'
    name: storageAccountName 
    enableHierarchicalNamespace: false 
    disablePubliAccess: true
    supportsHttpsTrafficOnly: true   
    tags: tags    
   } 
}

module keyvault '../../Modules/Microsoft.KeyVaults/vaults.bicep' = {
  name: '${mlWorkspaceName}-KeyVault'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    name: keyVaultName
    tags: tags  
    enableSoftDelete: true     
  }  
}

module acr '../../Modules/Microsoft.ContainerRegistry/registries.bicep' = {
  name: '${mlWorkspaceName}-ContainerRegistry'
  scope: resourceGroup(rg.name) 
  params: {
    name: acrName
    location: location
    sku: 'Premium' 
    tags: tags    
  } 
}

module appInsights '../../Modules/Microsoft.Insights/components.bicep' = {
  name: '${mlWorkspaceName}-AppInsights' 
  scope: resourceGroup(rg.name)
  params: {
    name: appInsightsName
    location: location
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    tags: tags     
  }
}

module mlworkspace '../../Modules/Microsoft.MachineLearningServices/workspaces.bicep' = {
  name: '${mlWorkspaceName}-Deployment'
  scope: resourceGroup(rg.name)
  params: {
    containerRegisteryId: acr.outputs.acrId
    identity: 'SystemAssigned'
    keyVaultId: keyvault.outputs.keyVaultId
    location: location
    name: mlWorkspaceName
    storageAccountId: storage.outputs.storageAccountId
    publicNetworkAccess: 'Enabled'
    tags: tags
    tier: 'Basic'
    v1LegacyMode: false
    applicationInsightsId: appInsights.outputs.appInsightId             
  }  
}

module mlworkspacePrivateLink '../../Modules/Microsoft.Network/privateEndpoints/privateEndpoints.bicep' = {
  name: '${mlWorkspaceName}-mlWorkspacePL'
  scope: resourceGroup(rg.name) 
  params: {
    location: location
    name: mlPlName
    remoteServiceResourceId: mlworkspace.outputs.mlWorkspaceId
    subnetResourceId: privateLinkSubnetId
    targetSubResource: [
      'amlworkspace'
    ] 
    manual: false
    requestMessage: 'AutoDeploy'      
  } 
}

module storagePrivateLinkBlob '../../Modules/Microsoft.Network/privateEndpoints/privateEndpoints.bicep' = {
  name: '${mlWorkspaceName}-StorageBlobPL'
  scope: resourceGroup(rg.name) 
  params: {
    location: location
    name: storBlobPlName
    remoteServiceResourceId: storage.outputs.storageAccountId
    subnetResourceId: privateLinkSubnetId
    targetSubResource: [
      'blob'
    ] 
    manual: false
    requestMessage: 'AutoDeploy'      
  } 
}

module storagePrivateLinkFile '../../Modules/Microsoft.Network/privateEndpoints/privateEndpoints.bicep' = {
  name: '${mlWorkspaceName}-StorageFilePL'
  scope: resourceGroup(rg.name) 
  params: {
    location: location
    name: stroFilePlName
    remoteServiceResourceId: storage.outputs.storageAccountId
    subnetResourceId: privateLinkSubnetId
    targetSubResource: [
      'file'
    ] 
    manual: false
    requestMessage: 'AutoDeploy'      
  } 
}

module storagePrivateLinkDfs '../../Modules/Microsoft.Network/privateEndpoints/privateEndpoints.bicep' = {
  name: '${mlWorkspaceName}-StorageDfsPL'
  scope: resourceGroup(rg.name) 
  params: {
    location: location
    name: storDfsPlName
    remoteServiceResourceId: storage.outputs.storageAccountId
    subnetResourceId: privateLinkSubnetId
    targetSubResource: [
      'dfs'
    ] 
    manual: false
    requestMessage: 'AutoDeploy'      
  } 
}

module keyvaultPrivateLink '../../Modules/Microsoft.Network/privateEndpoints/privateEndpoints.bicep' = {
  name: '${mlWorkspaceName}-KeyVaultPL'
  scope: resourceGroup(rg.name) 
  params: {
    location: location
    name: kvPlName
    remoteServiceResourceId: keyvault.outputs.keyVaultId
    subnetResourceId: privateLinkSubnetId
    targetSubResource: [
      'vault'
    ] 
    manual: false
    requestMessage: 'AutoDeploy'       
  } 
}

module acrPrivateLink '../../Modules/Microsoft.Network/privateEndpoints/privateEndpoints.bicep' = {
  name: '${mlWorkspaceName}-AcrPL'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    name: acrPlName
    remoteServiceResourceId: acr.outputs.acrId
    subnetResourceId: privateLinkSubnetId
    manual: false
    requestMessage: 'AutoDeploy'
    targetSubResource: [
      'registry'
    ]       
  }    
}

module blobDNSZone '../../Modules/Microsoft.Network/privateDnsZones/privateDnsZones.bicep' = {
  name: '${mlWorkspaceName}-BlobDNSZone' 
  scope: resourceGroup(dnsZoneSubscriptionId,dnsZoneRgName)
  params: {
    zoneName: 'privatelink.blob.${storageSuffix}' 
    createARecord: true
    aRecordName: split(storage.outputs.storageAccountId,'/')[8]  
    aRecordIp: storagePrivateLinkBlob.outputs.customerDnsConfigs[0].ipAddresses[0] 
    vnetAssociations: [
      {
        id: dnsVnetId
        registrationEnabled: false
      }
    ]
  }
}

module fileDNSZone '../../Modules/Microsoft.Network/privateDnsZones/privateDnsZones.bicep' = {
  name: '${mlWorkspaceName}-FileDNSZone' 
  scope: resourceGroup(dnsZoneSubscriptionId,dnsZoneRgName)
  params: {
    zoneName: 'privatelink.file.${storageSuffix}' 
    createARecord: true
    aRecordName: split(storage.outputs.storageAccountId,'/')[8]  
    aRecordIp: storagePrivateLinkFile.outputs.customerDnsConfigs[0].ipAddresses[0]
    vnetAssociations: [
      {
        id: dnsVnetId
        registrationEnabled: false
      }
    ]
  }
}

module dfsDNSZone '../../Modules/Microsoft.Network/privateDnsZones/privateDnsZones.bicep' = {
  name: '${mlWorkspaceName}-DfsDNSZone' 
  scope: resourceGroup(dnsZoneSubscriptionId,dnsZoneRgName)
  params: {
    zoneName: 'privatelink.dfs.${storageSuffix}' 
    createARecord: true
    aRecordName: split(storage.outputs.storageAccountId,'/')[8]  
    aRecordIp: storagePrivateLinkDfs.outputs.customerDnsConfigs[0].ipAddresses[0]
    vnetAssociations: [
      {
        id: dnsVnetId
        registrationEnabled: false
      }
    ]
  }
}

module keyvaultDNSZone '../../Modules/Microsoft.Network/privateDnsZones/privateDnsZones.bicep' = {
  name: '${mlWorkspaceName}-KeyVaultDNSZone' 
  scope: resourceGroup(dnsZoneSubscriptionId,dnsZoneRgName)
  params: {
    zoneName: keyvaultDns 
    createARecord: true
    aRecordName: split(keyvault.outputs.keyVaultId,'/')[8]  
    aRecordIp: keyvaultPrivateLink.outputs.customerDnsConfigs[0].ipAddresses[0]
    vnetAssociations: [
      {
        id: dnsVnetId
        registrationEnabled: false
      }
    ]
  }
}

module acrDNSZone '../../Modules/Microsoft.Network/privateDnsZones/privateDnsZones.bicep' = {
  name: '${mlWorkspaceName}-AcrDNSZone' 
  scope: resourceGroup(dnsZoneSubscriptionId,dnsZoneRgName)
  params: {
    zoneName: acrPrivateDns 
    createARecord: true
    aRecordName: split(acr.outputs.acrId,'/')[8]  
    aRecordIp: acrPrivateLink.outputs.customerDnsConfigs[0].ipAddresses[0]
    vnetAssociations: [
      {
        id: dnsVnetId
        registrationEnabled: false
      }
    ]
  }
}

module mlApiDnsZone '../../Modules/Microsoft.Network/privateDnsZones/privateDnsZones.bicep' = {
  name: '${mlWorkspaceName}-mlApiDnsZone' 
  scope: resourceGroup(dnsZoneSubscriptionId,dnsZoneRgName)
  params: {
    zoneName: mlApiDns 
    createARecord: false
    vnetAssociations: [
      {
        id: dnsVnetId
        registrationEnabled: false
      }
    ]
  }
}

module mlNotebookDnsZone '../../Modules/Microsoft.Network/privateDnsZones/privateDnsZones.bicep' = {
  name: '${mlWorkspaceName}-mlNotebookDnsZone' 
  scope: resourceGroup(dnsZoneSubscriptionId,dnsZoneRgName)
  params: {
    zoneName: mlNotbookDns 
    createARecord: false
    vnetAssociations: [
      {
        id: dnsVnetId
        registrationEnabled: false
      }
    ]
  }
}

module mlRecords 'dnsrecordLoop.bicep' = {
  name: 'Create-ML-DNS-Records'
  scope: resourceGroup(dnsZoneSubscriptionId,dnsZoneRgName)
  dependsOn: [
    mlApiDnsZone
    mlNotebookDnsZone
  ]
  params: {
    records: mlworkspacePrivateLink.outputs.customerDnsConfigs
    azureGovernment: azureGovernment
  }
}
/*
module hostPool '../../Modules/Microsoft.DesktopVirtualization/hostpools.bicep' = {
  name: '${mlWorkspaceName}-AVD-Hostpool'
  scope: resourceGroup(rg.name) 
  params: {
    loadBalancerType: 'BreadthFirst'
    location: location
    name: '${mlWorkspaceName}-AVD-Hostpool'
    hostPoolType: 'Pooled'
    preferredAppGroupType: 'Desktop'     
  }  
}

module appGroup '../../Modules/Microsoft.DesktopVirtualization/applicationgroups.bicep' = {
  name: '${mlWorkspaceName}-AVD-AppGroup'
  scope: resourceGroup(rg.name)
  params: {
    applicationGroupType: 'Desktop'
    hostpoolResourceId: hostPool.outputs.id
    description: 'Desktop App Group'
    location: location
    name: '${mlWorkspaceName}-AVD-AppGroup'    
  }  
}

module avdWorkspace '../../Modules/Microsoft.DesktopVirtualization/workspaces.bicep' = {
  name: '${mlWorkspaceName}-AVD-Workspace'
  scope: resourceGroup(rg.name)
  params: {
    description: 'Access to private ML Workspace'
    location: location
    name: '${mlWorkspaceName}-AVD-Workspace'
    applicationGroupReferences: [
      appGroup.outputs.id
    ]     
  }   
}*/
