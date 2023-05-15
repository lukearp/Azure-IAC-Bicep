targetScope = 'subscription'
param location string = 'eastus'
param rgName string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
}

module vnet 'vnet.bicep' = {
  name: 'VNET-DEPLOY'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    name: '${rgName}-VNET' 
  } 
}

module webServer 'vm.bicep' = {
 name: 'WebServer'
 scope: resourceGroup(rg.name)
 params: {
   name: 'WebServer'
   location: location
   subnetId: '${vnet.outputs.webSubnet}'  
 }
}

module appServer 'vm.bicep' = {
  name: 'AppServer'
  scope: resourceGroup(rg.name)
  params: {
    name: 'AppServer'
    location: location
    subnetId: '${vnet.outputs.appSubnet}'  
  }
 }

 module dbServer 'vm.bicep' = {
  name: 'DBServer'
  scope: resourceGroup(rg.name)
  params: {
    name: 'DBServer'
    location: location
    subnetId: '${vnet.outputs.dbSubnet}'  
  }
 }
