param name string
param location string
param imagePublisher string
param imageOffer string
param imageSku string
param vmSize string
param adminUsername string
@secure()
param adminPassword string
param timeZoneId string
@allowed([
  'Premium_LRS'
  'Standard_LRS'
  'StandardSSD_LRS'
])
param serverVirtualMachineOSDiskType string
param vnetRg string
param vnetName string
param subnetName string
param dnsServers array = []
param tags object

resource networkInterface 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: '${name}-nic'
  location: location  
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
             id: resourceId(vnetRg, 'Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
          }
          primary: true    
        }  
      }
    ]  
    dnsSettings: {
      dnsServers: dnsServers 
    } 
  }
}

resource serverVm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: name
  location: location
  plan: {
    publisher: imagePublisher
    product: imageOffer
    name: imageSku 
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: name
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        timeZone: timeZoneId
      } 
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        sku: imageSku
        offer: imageOffer
        version: 'latest' 
      }
      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadWrite'
        name: '${name}-OSDisk'
        managedDisk: {
          storageAccountType: serverVirtualMachineOSDiskType 
        } 
      }
    }
    networkProfile: {    
      networkInterfaces: [
        {
          id: networkInterface.id
          properties: {
            primary: true 
          }  
        } 
      ] 
    } 
  }
  tags: tags    
}

output networkInterfaceId string = networkInterface.id
