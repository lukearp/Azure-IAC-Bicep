param vmNamePrefix string
param count int
param zones array
param ahub bool
param nics array
param localAdminUsername string
@secure()
param localAdminPassword string
param timeZoneId string
param ntdsSizeGB int
param sysVolSizeGB int
param avsetId string
param vmSize string

output vmProperties array = [for i in range(0,count): ahub == true && zones != [] ? {
  licenseType: 'Windows_Server'
  networkProfile: {
    networkInterfaces: [
      nics[i] 
    ] 
  }
  diagnosticsProfile: {
    bootDiagnostics: {
      enabled: true 
    } 
  } 
  osProfile: {
    adminPassword: localAdminPassword
    adminUsername: localAdminUsername
    computerName: concat(vmNamePrefix,'-',i + 1)
    windowsConfiguration: {
      timeZone: timeZoneId
      enableAutomaticUpdates: true     
    }
    allowExtensionOperations: true        
  }
  storageProfile: {
    imageReference: {
      offer: 'WindowsServer'
      publisher: 'MicrosoftWindowsServer'
      sku: '2019-Datacenter'
      version: 'latest'    
    }
    osDisk: {
      createOption: 'FromImage'  
    }
    dataDisks: [
      {
        caching: 'None'
        createOption: 'Empty'
        diskSizeGB: ntdsSizeGB
        lun: 0
        name: concat(vmNamePrefix,'-',i + 1,'-ntds-disk')         
      }
      {
       caching: 'None'
       createOption: 'Empty'
       diskSizeGB: sysVolSizeGB
       lun: 1
       name: concat(vmNamePrefix,'-',i + 1,'-sysVol-disk')         
     }
    ]   
  }
  hardwareProfile: {
    vmSize: vmSize 
  }        
 } : ahub == true && zones == [] ? {
  licenseType: 'Windows_Server'   
  availabilitySet: {
    id: avsetId 
  }    
  networkProfile: {
    networkInterfaces: [
      nics[i] 
    ] 
  }
  diagnosticsProfile: {
    bootDiagnostics: {
      enabled: true 
    } 
  } 
  osProfile: {
    adminPassword: localAdminPassword
    adminUsername: localAdminUsername
    computerName: concat(vmNamePrefix,'-',i + 1)
    windowsConfiguration: {
      timeZone: timeZoneId
      enableAutomaticUpdates: true     
    }
    allowExtensionOperations: true        
  }
  storageProfile: {
    imageReference: {
      offer: 'WindowsServer'
      publisher: 'MicrosoftWindowsServer'
      sku: '2019-Datacenter'
      version: 'latest'    
    }
    osDisk: {
      createOption: 'FromImage'  
    }
    dataDisks: [
      {
        caching: 'None'
        createOption: 'Empty'
        diskSizeGB: ntdsSizeGB
        lun: 0
        name: concat(vmNamePrefix,'-',i + 1,'-ntds-disk')         
      }
      {
       caching: 'None'
       createOption: 'Empty'
       diskSizeGB: sysVolSizeGB
       lun: 1
       name: concat(vmNamePrefix,'-',i + 1,'-sysVol-disk')         
     }
    ]   
  }
  hardwareProfile: {
    vmSize: vmSize 
  }        
 } : ahub == false && zones == [] ? {  
  availabilitySet: {
    id: avsetId
  }    
  networkProfile: {
    networkInterfaces: [
      nics[i] 
    ] 
  }
  diagnosticsProfile: {
    bootDiagnostics: {
      enabled: true 
    } 
  } 
  osProfile: {
    adminPassword: localAdminPassword
    adminUsername: localAdminUsername
    computerName: concat(vmNamePrefix,'-',i + 1)
    windowsConfiguration: {
      timeZone: timeZoneId
      enableAutomaticUpdates: true     
    }
    allowExtensionOperations: true        
  }
  storageProfile: {
    imageReference: {
      offer: 'WindowsServer'
      publisher: 'MicrosoftWindowsServer'
      sku: '2019-Datacenter'
      version: 'latest'    
    }
    osDisk: {
      createOption: 'FromImage'  
    }
    dataDisks: [
      {
        caching: 'None'
        createOption: 'Empty'
        diskSizeGB: ntdsSizeGB
        lun: 0
        name: concat(vmNamePrefix,'-',i + 1,'-ntds-disk')         
      }
      {
       caching: 'None'
       createOption: 'Empty'
       diskSizeGB: sysVolSizeGB
       lun: 1
       name: concat(vmNamePrefix,'-',i + 1,'-sysVol-disk')         
     }
    ]   
  }
  hardwareProfile: {
    vmSize: vmSize 
  }        
 } : {    
  networkProfile: {
    networkInterfaces: [
      nics[i] 
    ] 
  }
  diagnosticsProfile: {
    bootDiagnostics: {
      enabled: true 
    } 
  } 
  osProfile: {
    adminPassword: localAdminPassword
    adminUsername: localAdminUsername
    computerName: concat(vmNamePrefix,'-',i + 1)
    windowsConfiguration: {
      timeZone: timeZoneId
      enableAutomaticUpdates: true     
    }
    allowExtensionOperations: true        
  }
  storageProfile: {
    imageReference: {
      offer: 'WindowsServer'
      publisher: 'MicrosoftWindowsServer'
      sku: '2019-Datacenter'
      version: 'latest'    
    }
    osDisk: {
      createOption: 'FromImage'  
    }
    dataDisks: [
      {
        caching: 'None'
        createOption: 'Empty'
        diskSizeGB: ntdsSizeGB
        lun: 0
        name: concat(vmNamePrefix,'-',i + 1,'-ntds-disk')         
      }
      {
       caching: 'None'
       createOption: 'Empty'
       diskSizeGB: sysVolSizeGB
       lun: 1
       name: concat(vmNamePrefix,'-',i + 1,'-sysVol-disk')         
     }
    ]   
  }
  hardwareProfile: {
    vmSize: vmSize 
  }        
 }]

