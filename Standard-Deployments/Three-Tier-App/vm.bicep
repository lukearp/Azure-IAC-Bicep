param name string
param location string
param subnetId string

resource nic 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: '${name}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: subnetId
          } 
        }  
      }
    ] 
  }  
}

resource vm 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: name
  location: location
  properties: {
    storageProfile: {
      imageReference: {
        publisher: 'canonical'
        offer: '0001-com-ubuntu-server-focal' 
        sku: '20_04-lts-gen2' 
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadWrite'
        osType: 'Linux'   
      }  
    }
    osProfile: {
      linuxConfiguration: {
         
      }
      adminPassword: 'Windows2P@ss'
      adminUsername: 'localadmin'
      computerName: name     
    }
    hardwareProfile: {
      vmSize: 'Standard_B1s' 
    }  
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id 
        }
      ]
    }
  } 
}
