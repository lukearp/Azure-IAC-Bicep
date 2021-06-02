@maxLength(13)
param vmNamePrefix string
param location string = resourceGroup().location
param vmSize string = 'Standard_B2ms'
param ahub bool = false
@maxValue(2)
param count int = 2
param vnetId string
param subnetName string
param ntdsSizeGB int
param sysVolSizeGB int
param localAdminUsername string
@secure()
param localAdminPassword string
param domainFqdn string
param newForest bool
param domainAdminUsername string
@secure()
param domainAdminPassword string
param site string = 'Default-First-Site-Name'
param dnsServers array = [
  '168.63.129.16'
]
param dscConfigScript string = 'https://github.com/lukearp/Azure-IAC-Bicep/releases/download/DSC/DomainControllerConfig.zip'
param timeZoneId string = 'Eastern Standard Time'
param managedIdentityId string
param psScriptLocation string = 'https://raw.githubusercontent.com/lukearp/Azure-IAC-Bicep/master/Scripts/Restart-Vms/restart-vms.ps1'

var domainUserName = newForest == true ? '${split(domainFqdn,'.')[0]}\\${localAdminUsername}' : domainAdminUsername
var domainPassword = newForest == true ? localAdminPassword : domainAdminPassword
resource nics 'Microsoft.Network/networkInterfaces@2020-11-01' = [for i in range(0, count): {
  name: '${vmNamePrefix}-${i + 1}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'dc'
        properties: {
          primary: true
          subnet: {
            id: '${vnetId}/subnets/${subnetName}'
          }
        }
      }
    ]
  }
}]

module nicsDns 'nicDns.bicep' = {
  name: 'DNS-Set'
  params: {
    dnsServers: dnsServers
    nics: [for i in range(0, count): {
      name: nics[i].name
      ipConfigurations: nics[i].properties.ipConfigurations      
    }]
    count: count
    location: location
  }
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

var zones = [for i in range(0, count): contains(azRegions, location) ? [
  string(i == 0 || i == 3 || i == 6 ? 1 : i == 1 || i == 4 || i == 7 ? 2 : 3)
] : []]

resource avSet 'Microsoft.Compute/availabilitySets@2020-12-01' = if (zones == []) {
  name: '${vmNamePrefix}-avset'
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {}
}

module vmProperties 'vmPropertiesBuilder.bicep' = {
  name: 'Properties-Builder'
  params: {
    ahub: ahub
    avsetId: avSet.id
    count: count
    localAdminPassword: localAdminPassword
    localAdminUsername: localAdminUsername
    nics: [for i in range(0, count): {
      id: nicsDns.outputs.nicIds[i].id
    }]
    ntdsSizeGB: ntdsSizeGB
    sysVolSizeGB: sysVolSizeGB
    timeZoneId: timeZoneId
    vmNamePrefix: vmNamePrefix
    vmSize: vmSize
    zones: zones[0]
  }
}

resource dc1 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: '${vmNamePrefix}-1'
  location: location
  zones: zones[0]
  properties: vmProperties.outputs.vmProperties[0]
}

resource dc1Extension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  name: '${vmNamePrefix}-1/DC-Creation'
  location: location
  dependsOn: [
    dc1
  ]
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.73'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: dscConfigScript
      configurationFunction: 'DomainControllerConfig.ps1\\DomainControllerConfig'
      properties: {
        username: domainUserName
        password: domainPassword
        domain: domainFqdn
        site: site
        newForest: newForest
      }
    }
  }
} 

resource rebootDc1 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  kind: 'AzurePowerShell'
  location: location
  name: 'rebootDc'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}':{}
    }  
  } 
  properties: {
    arguments: '${array(dc1.name)} ${resourceGroup().name} ${subscription().subscriptionId}'
    primaryScriptUri: psScriptLocation 
    azPowerShellVersion: '5.9'
    retentionInterval: 'P1D'    
  } 
  dependsOn: [
    dc1Extension 
  ]    
}


resource otherDcs 'Microsoft.Compute/virtualMachines@2020-12-01' = [for i in range(1, count - 1): {
  dependsOn: [
    rebootDc1
  ]
  location: location
  name: '${vmNamePrefix}-${i + 1}'
  zones: zones[i]
  properties: vmProperties.outputs.vmProperties[i]
}]

resource otherDcsExtension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = [for i in range(1, count - 1): {
  name: '${vmNamePrefix}-${i + 1}/DC-Creation'
  location: location
  dependsOn: [
    otherDcs
  ]
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.73'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: dscConfigScript
      configurationFunction: 'DomainControllerConfig.ps1\\DomainControllerConfig'
      properties: {
        username: domainUserName
        password: domainPassword
        domain: domainFqdn
        site: site
        newForest: false
      }
    }
  }
}]

var vmNames = [for i in range(1,count-1): otherDcs[i].name]

resource rebootOtherVms 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  kind: 'AzurePowerShell'
  location: location
  name: 'rebootOtherVms'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}':{}
    }  
  } 
  properties: {
    arguments: '${vmNames} ${resourceGroup().name} ${subscription().subscriptionId}'
    primaryScriptUri: psScriptLocation 
    azPowerShellVersion: '5.9'
    retentionInterval: 'P1D'    
  } 
  dependsOn: [
    dc1Extension 
  ]    
}
