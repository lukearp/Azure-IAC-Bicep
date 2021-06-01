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
param dnsServers array = []
param dscConfigScript string = 'https://github.com/lukearp/Azure-IAC-Bicep/releases/download/DSC/DomainControllerConfig.zip'
param timeZoneId string = 'Eastern Standard Time' 

resource nics 'Microsoft.Network/networkInterfaces@2020-11-01' = [for i in range(0,count): {
  name: concat(vmNamePrefix,'-',i + 1,'-nic') 
  location: location
  properties: {
    dnsSettings: {
      dnsServers: dnsServers 
    } 
    ipConfigurations: [
      {
        name: 'dc'
        properties: {
          primary: true
          subnet: {
            id: concat(vnetId,'/subnets/',subnetName) 
          }   
        }  
      } 
    ] 
  }  
}]
var azRegions = [
  'eastus'
  'eastus2'
  'centralus'
  'southcentralus'
  'usgovvirginia'
  'westus2'
  'westus3' 
]

var zones = [for i in range(0,count): contains(azRegions,location) ? [
  string(i == 0 || i == 3 || i == 6 ? 1 : i == 1 || i == 4 || i == 7 ? 2 : 3)
] : []]

resource avSet 'Microsoft.Compute/availabilitySets@2020-12-01' = if (zones == []){
 name: concat(vmNamePrefix,'-avset')
 location: location 
 sku: {
   name: 'Aligned' 
 }
 properties: {
    
 }   
}

module vmProperties 'vmPropertiesBuilder.bicep' = {
 name: 'Properties-Builder'
 params: {
   ahub: ahub
   avsetId: avSet.id
   count: count
   localAdminPassword: localAdminPassword
   localAdminUsername: localAdminUsername
   nics: [for i in range(0,count): {
    id: nics[i].id
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
  name: concat(vmNamePrefix,'-1') 
  location: location
  zones: zones[0] 
  properties: vmProperties.outputs.vmProperties[0]  
}

resource dc1Extension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  name: concat(vmNamePrefix,'-1/DC-Creation')
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
         username: domainAdminUsername
         password: domainAdminPassword
         domain: domainFqdn
         site: site
         newForest: newForest 
       }        
     }  
  }  
}

resource otherDcs 'Microsoft.Compute/virtualMachines@2020-12-01' = [for i in range(1,count - 1): {
  dependsOn: [
    dc1Extension
  ]
  location: location
  name: concat(vmNamePrefix,'-', i + 1)
  zones: zones[i] 
  properties: vmProperties.outputs.vmProperties[i]      
}]

resource otherDcsExtension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = [for i in range(1,count - 1):{
  name: concat(vmNamePrefix,'-',i + 1,'/DC-Creation')
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
         username: domainAdminUsername
         password: domainAdminPassword
         domain: domainFqdn
         site: site
         newForest: false 
       }        
     }  
  }  
}]
