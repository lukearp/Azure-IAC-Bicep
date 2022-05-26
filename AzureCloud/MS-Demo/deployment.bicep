targetScope = 'tenant'
module baseInfra '../../Standard-Deployments/CAF-Landing-Zone-MG/caf-mg-deploy.bicep' = {
  name: 'Environment'
  params: {
    rootMgName: 'MS-Demo'
    platformMgName: 'MS-Platform'
    landingZoneMgName: 'MS-LZ'
    landingZoneChildMgs: [
      'MSDN'
    ]
    platformChildMgs: [
      'CoreServices'
    ]
    defaultLocation: 'eastus'
    existingSubscriptions: [
      {
        mg: 'MSDN'
        id: '2ab6855d-b9f8-4762-bba5-efe49f339629'
      }
      {
        mg: 'CoreServices'
        id: '32eb88b4-4029-4094-85e3-ec8b7ce1fc00'
      }
    ]
    rbacAssignments: [
      {
        mg: 'MS-Demo'
        roleId: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
        objectId: 'eb5799c9-a9ac-4b43-8c73-9267724123d0'
        name: 'MS-Demo-Owners'
      }
      {
        mg: 'MS-Platform'
        roleId: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
        objectId: '23ffd2ff-1913-4c2f-a8ec-cc5de51ebec6'
        name: 'MS-Platform-Owners'
      }
      {
        mg: 'MS-LZ'
        roleId: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
        objectId: '634dd674-f919-4cba-8749-87c02c9c6c51'
        name: 'MS-LZ-Owners'
      }
    ]
    virtualNetworks: [
      {
        name: 'core-hub-vnet-eastus'
        subId: '32eb88b4-4029-4094-85e3-ec8b7ce1fc00'
        vnetAddressSpace: '10.0.16.0/22'
        dnsServers: []
        type: 'Hub'
        location: 'eastus'
        resourceGroupName: 'core-hub-networking-eastus-rg'
        nsgRules: []
        routes: []
        disableBgpRoutePropagation: false
        subnets: [
          {
            name: 'GatewaySubnet'
            addressPrefix: '10.0.19.224/27'
            nsg: false
            routeTable: false
          }
          {
            name: 'AzureBastionSubnet'
            addressPrefix: '10.0.19.128/26'
            nsg: false
            routeTable: false
          }
          {
            name: 'AzureFirewallSubnet'
            addressPrefix: '10.0.19.64/26'
            nsg: false
            routeTable: false
          }
          {
            name: 'RouteServerSubnet'
            addressPrefix: '10.0.19.192/27'
            nsg: false
            routeTable: false
          }
          {
            name: 'Trust'
            addressPrefix: '10.0.19.0/28'
            nsg: false
            routeTable: false
          }
          {
            name: 'Untrust'
            addressPrefix: '10.0.19.16/28'
            nsg: false
            routeTable: false
          }
          {
            name: 'Management'
            addressPrefix: '10.0.16.32/27'
            nsg: false
            routeTable: false
          }
          {
            name: 'DomainControllers'
            addressPrefix: '10.0.16.0/28'
            nsg: true
            routeTable: true
          }
        ]
        gateways: [
          {
            name: 'Core-VPN'
            size: 'VpnGw1'
            type: 'Vpn'
            activeActive: true
            asn: 65000
          }
          {
            name: 'Core-ER'
            size: 'Standard'
            type: 'ExpressRoute'
            activeActive: false
            asn: 65515
          }
        ]
        tags: {
          Environment: 'Prod'
          HoursOfOperation: '24-7'
        }
      }
      {
        name: 'core-spoke-eastus-vnet'
        subId: '32eb88b4-4029-4094-85e3-ec8b7ce1fc00'
        vnetAddressSpace: '10.0.20.0/22'
        dnsServers: []
        type: 'Spoke'
        location: 'eastus'
        resourceGroupName: 'core-spoke-network-eastus-rg'
        nsgRules: []
        routes: []
        disableBgpRoutePropagation: false
        subnets: [
          {
            name: 'VDI'
            addressPrefix: '10.0.20.0/25'
            nsg: true
            routeTable: true
          }
        ]
        tags: {
          Environment: 'Prod'
          HoursOfOperation: '24-7'
          Spoke: 'True'
        }
      }
    ] 
    policyAssignments: []         
  }   
}

module routeServer '../../Modules/Microsoft.Network/virtualHubs/routeServer.bicep' = {
  name: 'Route-Server-Deploy'
  scope: resourceGroup('32eb88b4-4029-4094-85e3-ec8b7ce1fc00','core-hub-networking-eastus-rg')
  dependsOn: [
    baseInfra
  ]
  params: {
    location: 'eastus'
    routeServerName: 'rt-server'
    vnetId: resourceId('32eb88b4-4029-4094-85e3-ec8b7ce1fc00','core-hub-networking-eastus-rg','Microsoft.Network/virtualNetworks','core-hub-vnet-eastus')
    tags: {
      Environment: 'Prod'
    } 
  } 
}

module networkManager '../../Modules/Microsoft.Network/networkManagers/networkManagers.bicep' = {
  name: 'Network-Manager-Deployment'
  scope: resourceGroup('32eb88b4-4029-4094-85e3-ec8b7ce1fc00','core-hub-networking-eastus-rg')
  dependsOn: [
    baseInfra
  ]
  params: {
    description: 'Network Manager for MS-Demo'
    location: 'eastus'
    managementGroups: [
       '/providers/Microsoft.Management/managementGroups/CoreServices'
    ]
    name: 'MS-Demo-NM'
    tags: {
      Environment: 'Prod'
    } 
    subscriptions: [
      
    ]     
  }    
}

module networkManagerGroup '../../Modules/Microsoft.Network/networkManagers/networkGroups/networkGroups.bicep' = {
  name: 'Network-Manager-Group-Deployment'
  scope: resourceGroup('32eb88b4-4029-4094-85e3-ec8b7ce1fc00','core-hub-networking-eastus-rg')
  dependsOn: [
    networkManager
  ]
  params: {
    networkManagerName: 'MS-Demo-NM'
    description: 'Spokes to Peer'
    networkGroupName: 'Spoke-VNETs'
    tagName: 'Spoke'    
  }    
}

module networkConnectivityConfig '../../Modules/Microsoft.Network/networkManagers/connectivityConfigurations/connectivityConfigurations.bicep' = {
  name: 'Network-Config-Deploy'
  scope: resourceGroup('32eb88b4-4029-4094-85e3-ec8b7ce1fc00','core-hub-networking-eastus-rg')
  params: {
    connectivityConfigName: 'EastUS-Hub-Spoke'
    hubVnetId: resourceId('32eb88b4-4029-4094-85e3-ec8b7ce1fc00','core-hub-networking-eastus-rg','Microsoft.Network/virtualNetworks','core-hub-vnet-eastus')
    description: 'Peering VNETs in EastUS' 
    networkGroupId: networkManagerGroup.outputs.groupId
    networkManagerName: 'MS-Demo-NM'
  } 
}
