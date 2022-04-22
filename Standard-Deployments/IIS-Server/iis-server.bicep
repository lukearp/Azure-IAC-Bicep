param servername string
param location string
param vmsize string
param vnetRg string
param vnetName string
param subnetName string
@allowed([
  '2019-datacenter-gensecond'
  '2016-datacenter-gensecond'
])
param osversion string = '2019-datacenter-gensecond'
param localadmin string
@secure()
param localadminpassword string
param domainJoinUser string
@secure()
param domainJoinPassword string
param ouPath string = ''
param domainFqdn string
param tags object = {}
param zones array = []
@allowed([
  'StandardSSD_LRS'
  'Standard_LRS'
  'Premium_LRS'
])
param storageAccountType string = 'StandardSSD_LRS'

var subnet = '${subscription().id}/resourceGroups/${vnetRg}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${subnetName}'
resource iisvmnic 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: '${servername}-nic'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: subnet
          } 
        }  
      } 
    ] 
  }   
}

resource iisvm 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  location: location
  name: servername
  tags: tags
  zones: zones
  properties: {
    hardwareProfile: {
      vmSize: vmsize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: storageAccountType
        }
      } 
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: osversion
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          properties: {
            primary: true
          }
          id: iisvmnic.id
        }
      ]
    }
    osProfile: {
      adminPassword: localadminpassword
      adminUsername: localadmin
      computerName: servername
    }
    licenseType: 'Windows_Server'
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true 
      } 
    } 
  }
  identity: {
    type: 'SystemAssigned'
  } 
}

resource joinDomain 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = {
  parent: iisvm
  location: location
  name: 'joindomain'
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      name: domainFqdn
      ouPath: ouPath
      user: domainJoinUser
      restart: 'true'
      options: 3
    }
    protectedSettings: {
      password: domainJoinPassword
    }
  }
}
