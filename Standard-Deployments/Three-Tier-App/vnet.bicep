param name string
param location string

resource nsgWeb 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: 'NSG_WEB'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Internet-to-Web' 
        properties: {
          priority: 200
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '10.0.0.0/27'
          destinationPortRange: '80' 
          sourcePortRange: '*'     
        } 
      }
      {
        name: 'Deny-All-Inbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          sourcePortRange: '*'
        }
      }
    ] 
  }  
}

resource nsgApp 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: 'NSG_APP'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Web-to-App' 
        properties: {
          priority: 200
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '10.0.0.0/27'
          destinationAddressPrefix: '10.0.0.32/27'
          destinationPortRange: '8080' 
          sourcePortRange: '*'       
        } 
      }
      {
        name: 'Deny-All-Inbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          sourcePortRange: '*'
        }
      }
    ] 
  }  
}

resource nsgDB 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: 'NSG_DB'
  location: location
  properties: {
    securityRules: [
      {
        name: 'App-to-DB' 
        properties: {
          priority: 200
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '10.0.0.32/27'
          destinationAddressPrefix: '10.0.0.64/27'
          destinationPortRange: '1433'  
          sourcePortRange: '*'      
        } 
      }
      {
        name: 'Deny-All-Inbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          sourcePortRange: '*'
        }
      }
    ] 
  }  
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
 name: name
 location: location
 properties: {
   addressSpace: {
     addressPrefixes: [
       '10.0.0.0/24'
     ] 
   } 
   dhcpOptions: {
     dnsServers: [
       '168.63.129.16'
     ]
   } 
   subnets: [
     {
       name: 'Web'
       properties: {
         addressPrefix: '10.0.0.0/27'
         networkSecurityGroup: {
           id: nsgWeb.id
         }  
       }  
     }
     {
      name: 'App'
      properties: {
        addressPrefix: '10.0.0.32/27'
        networkSecurityGroup: {
          id: nsgApp.id
        }  
      }  
    }
    {
      name: 'DB'
      properties: {
        addressPrefix: '10.0.0.64/27'
        networkSecurityGroup: {
          id: nsgDB.id
        }  
      }  
    }
   ] 
 } 
}

output webSubnet string = '${vnet.id}/subnets/Web'
output appSubnet string = '${vnet.id}/subnets/App'
output dbSubnet string = '${vnet.id}/subnets/DB'
