param vnetName string
param location string
param deploymentPrefix string
param keyVaultName string
param storageKeyName string
param rootCertName string
param externalCertName string
param internalCertName string
param serverVirtualMachineName string
param portalVirtualMachineName string
param dataStoreVirtualMachineName string
param appGatewayName string
param externalDnsHostName string
param timeZoneId string
param imageOffer string
param imageSku string
param imagePublisher string
param osDiskType string
param virtualMachineSize string
param adminUsername string
param adminPassword string
param serviceUserName string
param servicePassword string
param storageSuffix string
param artifactsLocation string
param artifactSas string
param dscArchiveFile string
param serverLicenseFileName string
param portalLicenseFileName string
param portalLicenseUserTypeId string
param cloudEnvironment string
param tags object = {}

resource keyvault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: '${vnetName}-VM-nsg'
  location: location
  properties: {
     
  }   
}

resource appGwNsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: '${vnetName}-appGw-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'GatewayManager'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 100
          protocol: 'Tcp' 
          sourceAddressPrefix: 'GatewayManager' 
          destinationAddressPrefix: '*'
          sourcePortRange: '*'  
          destinationPortRange: '65200-65535'  
        }  
      }
      {
        name: 'HTTP'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 105
          protocol: 'Tcp' 
          sourceAddressPrefix: 'Internet' 
          destinationAddressPrefix: '*'
          sourcePortRange: '*'  
          destinationPortRanges: [
            '80'
            '443'
          ]  
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.255.254.0/24'
      ] 
    }
    subnets: [
      {
        name: 'VM'
        properties: {
          addressPrefix: '10.255.254.0/26' 
          networkSecurityGroup: {
            id: nsg.id 
          } 
        }  
      }
      {
        name: 'appGw'
        properties: {
          addressPrefix: '10.255.254.192/26' 
          networkSecurityGroup: {
            id: appGwNsg.id
          }
        }
      }
    ]  
  }   
}

resource vmSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  name: 'VM'
  parent: virtualNetwork
  properties: {
    addressPrefix: '10.255.254.0/26' 
    networkSecurityGroup: {
      id: nsg.id 
    }  
  }  
}

resource appGwSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  name: 'appGw'
  parent: virtualNetwork
  properties: {
    addressPrefix: '10.255.254.192/26' 
    networkSecurityGroup: {
      id: appGwNsg.id
    } 
  }  
}

var storageAccountName = substring('${deploymentPrefix}${replace(guid(subscription().id, resourceGroup().name, location), '-', '')}', 0, 23)

module storageAccount '../../Modules/Microsoft.Storage/storageAccounts/storageAccounts.bicep' = {
  name: '${deploymentPrefix}-StorageAccount'
  params: {
    kind: 'StorageV2'
    location: location
    name: storageAccountName
    sku: 'Standard_LRS'
    storeKeysInKeyVault: true
    keyVaultName: keyvault.name
    keyVaultRg: resourceGroup().name
    secretName: storageKeyName
    generateSas: true
    tags: tags
  }
}

module share '../../Modules/Microsoft.Storage/storageAccounts/share/share.bicep' = {
  name: '${deploymentPrefix}-Share'
  params: {
    shareName: 'esri'
    storageAccountName: storageAccountName
  }
  dependsOn: [
    storageAccount
  ]
}

module appGateway 'esri-appgw.bicep' = {
  name: 'AppGatewayDeployment'
  params: {
    rootCert: keyvault.getSecret(rootCertName)
    portalNicId: portal.outputs.networkInterfaceId
    serverNicId: server.outputs.networkInterfaceId
    serverVirtualMachineName: serverVirtualMachineName
    portalVirtualMachineName: portalVirtualMachineName
    location: location
    autoScaleMax: 10
    skuName: 'Standard_v2'
    enableHttp2: false
    name: appGatewayName
    subnetName: appGwSubnet.name
    virtualnetwork: virtualNetwork.name
    virtualnetworkRg: resourceGroup().name
    autoScaleMin: 0
    publicCertString: keyvault.getSecret(externalCertName)  
    externalDnsHostName: externalDnsHostName
  }
  dependsOn: [
    serverDsc
    portal
  ]
}

var azRegions = [
  'eastus'
  'eastus2'
  'centralus'
  'southcentralus'
  'usgovvirginia'
  'westus2'
  'westus3'
]

var zones = []

var zoneArray = contains(azRegions, location) ? zones == [] ? [
  '1'
  '2'
  '3'
] : zones : []

module appGatewayPip '../../Modules/Microsoft.Network/publicIpAddresses/publicIpAddresses.bicep' = {
  name: 'AppGateway-PublicIP'
  params: {
    name: 'Esri-${appGatewayName}-PIP'
    location: location
    publicIpAllocationMethod: 'Static'
    sku: 'Standard'
    publicIpAddressVersion: 'IPv4'
    tier: 'Regional'
    tags: tags
    zones: zoneArray 
  }
}

module DNSZone 'dnsZone.bicep' = {
  name: 'ExternalZone'
  params: {
    zoneName: externalDnsHostName
    aRecordIp: appGatewayPip.outputs.ipAddress
    aRecordName: '@'
    createARecord: true
    tags: tags
    vnetAssociation: virtualNetwork.id   
  } 
}

module server '../../Modules/Microsoft.Compute/virtualMachines/virtualMachines.bicep' = {
  name: 'Server-Deploy'
  dependsOn: [
    DNSZone
  ]
  params: {
    adminPassword: keyvault.getSecret(adminPassword)
    adminUsername: adminUsername
    imageOffer: imageOffer
    imageSku: imageSku
    imagePublisher: imagePublisher
    location: location
    name: serverVirtualMachineName
    serverVirtualMachineOSDiskType: osDiskType
    vmSize: virtualMachineSize
    subnetName: vmSubnet.name
    vnetName: virtualNetwork.name
    vnetRg: resourceGroup().name
    timeZoneId: timeZoneId
    //dnsServers: [
    //  '168.63.129.16'
    //] 
    tags: tags 
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(subscription().id,resourceGroup().name,serverVirtualMachineName)
  scope: keyvault
  properties: { 
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/00482a5a-887f-4fb3-b363-3b7fe8e74483'
    principalId: server.outputs.servicePrincipalId 
  }
}

module serverDsc 'serverdsc.bicep' = {
  name: 'Server-DSC-Setup'
  dependsOn: [    
    roleAssignment
    share
  ]
  params: {
    artifactsLocation: artifactsLocation
    artifactSas: artifactSas
    dscArchiveFile: dscArchiveFile
    externalDnsHostName: externalDnsHostName
    location: location
    serverLicenseFile: serverLicenseFileName
    storageAccountName: storageAccountName
    storageKey: keyvault.getSecret(storageKeyName)
    vmName: serverVirtualMachineName
    serviceUserName: serviceUserName
    servicePassword: keyvault.getSecret(servicePassword) 
    storageSuffix: storageSuffix 
    networkInterfaceId: server.outputs.networkInterfaceId
    keyVaultName: keyvault.name 
    cloudEnvironment: cloudEnvironment
    //certName: certName         
  }
}

module portal '../../Modules/Microsoft.Compute/virtualMachines/virtualMachines.bicep' = {
  name: 'Portal-Deploy'
  dependsOn: [
    DNSZone
  ]
  params: {
    adminPassword: keyvault.getSecret(adminPassword)
    adminUsername: adminUsername
    imageOffer: imageOffer
    imageSku: imageSku
    imagePublisher: imagePublisher
    location: location
    name: portalVirtualMachineName
    serverVirtualMachineOSDiskType: osDiskType
    vmSize: virtualMachineSize
    subnetName: vmSubnet.name
    vnetName: virtualNetwork.name
    vnetRg: resourceGroup().name
    timeZoneId: timeZoneId
    tags: tags
    //dnsServers: [
    //  '168.63.129.16'
    //] 
  }
}

module portalDsc 'portaldsc.bicep' = {
  name: 'Portal-DSC-Deploy'
  dependsOn: [
    serverDsc
    dataDsc
    portal
    appGateway
  ]
  params: {
    artifactSas: artifactSas
    artifactsLocation: artifactsLocation
    dscArchiveFile: dscArchiveFile
    externalDnsHostName: externalDnsHostName
    location: location
    portalLicenseFile: portalLicenseFileName
    portalLicenseType: portalLicenseUserTypeId
    selfsignedCertData: keyvault.getSecret(internalCertName)
    serverName: serverVirtualMachineName
    vmName: portalVirtualMachineName
    servicePassword: keyvault.getSecret(servicePassword)
    serviceUserName: serviceUserName
    storageAccountName: storageAccountName
    storageKey: keyvault.getSecret(storageKeyName)
    storageSuffix: storageSuffix 
    ssroot: keyvault.getSecret(rootCertName) 
    //certName: certName
    //serverNicId: server.outputs.networkInterfaceId
    //rootCertData: keyvault.getSecret(rootCert)        
  }
}

module data '../../Modules/Microsoft.Compute/virtualMachines/virtualMachines.bicep' = {
  name: 'Data-Deploy'
  dependsOn: [
    DNSZone
  ]
  params: {
    adminPassword: keyvault.getSecret(adminPassword)
    adminUsername: adminUsername
    imageOffer: imageOffer
    imageSku: imageSku
    imagePublisher: imagePublisher
    location: location
    name: dataStoreVirtualMachineName
    serverVirtualMachineOSDiskType: osDiskType
    vmSize: virtualMachineSize
    subnetName: vmSubnet.name
    vnetName: virtualNetwork.name
    vnetRg: resourceGroup().name
    timeZoneId: timeZoneId
    //dnsServers: [
     // '168.63.129.16'
    //]
    tags: tags
  }
}

module dataDsc 'datadsc.bicep' = {
  name: 'Data-DSC-Setup'
  dependsOn: [
    serverDsc
    data
  ]
  params: {
    artifactSas: artifactSas
    artifactsLocation: artifactsLocation
    deploymentPrefix: deploymentPrefix
    dscArchiveFile: dscArchiveFile
    storageAccountName: storageAccountName
    externalDnsHostName: externalDnsHostName
    location: location
    serverName: serverVirtualMachineName 
    servicePassword: keyvault.getSecret(servicePassword)
    serviceUserName: serviceUserName
    storageKey: keyvault.getSecret(storageKeyName)
    vmName: dataStoreVirtualMachineName 
    storageSuffix: storageSuffix        
  }
}
