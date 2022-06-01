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
        name: 'core-vpn-vnet-eastus'
        subId: '32eb88b4-4029-4094-85e3-ec8b7ce1fc00'
        vnetAddressSpace: '10.0.12.0/24'
        dnsServers: []
        type: 'Hub'
        location: 'eastus'
        resourceGroupName: 'core-vpn-networking-eastus-rg'
        nsgRules: []
        routes: []
        disableBgpRoutePropagation: false
        subnets: [
          {
            name: 'GatewaySubnet'
            addressPrefix: '10.0.12.224/27'
            nsg: false
            routeTable: false
          }
          {
            name: 'RouteServerSubnet'
            addressPrefix: '10.0.12.192/27'
            nsg: false
            routeTable: false
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
        ]
        tags: {
          Environment: 'Prod'
          HoursOfOperation: '24-7'
          Spoke: 'True'
        }
      }
      {
        name: 'core-er-vnet-eastus'
        subId: '32eb88b4-4029-4094-85e3-ec8b7ce1fc00'
        vnetAddressSpace: '10.0.12.0/24'
        dnsServers: []
        type: 'Hub'
        location: 'eastus'
        resourceGroupName: 'core-er-networking-eastus-rg'
        nsgRules: []
        routes: []
        disableBgpRoutePropagation: false
        subnets: [
          {
            name: 'GatewaySubnet'
            addressPrefix: '10.0.12.224/27'
            nsg: false
            routeTable: false
          }
          {
            name: 'RouteServerSubnet'
            addressPrefix: '10.0.12.192/27'
            nsg: false
            routeTable: false
          }
        ]
        gateways: [
          {
            name: 'Core-ER'
            size: 'Standard'
            type: 'ExpressRoute' 
            activeActive: false
            asn: 65000
          }
        ]
        tags: {
          Environment: 'Prod'
          HoursOfOperation: '24-7'
          Spoke: 'True'
        }
      }
      {
        name: 'core-workloads-eastus-vnet'
        subId: '32eb88b4-4029-4094-85e3-ec8b7ce1fc00'
        vnetAddressSpace: '10.0.16.0/22'
        dnsServers: []
        type: 'Spoke'
        location: 'eastus'
        resourceGroupName: 'core-workloads-network-eastus-rg'
        nsgRules: []
        routes: []
        disableBgpRoutePropagation: false
        subnets: [
          {
            name: 'VDI'
            addressPrefix: '10.0.17.0/25'
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
      {
        name: 'core-transit-eastus-vnet'
        subId: '32eb88b4-4029-4094-85e3-ec8b7ce1fc00'
        vnetAddressSpace: '10.0.14.0/24'
        dnsServers: []
        type: 'Spoke'
        location: 'eastus'
        resourceGroupName: 'core-transit-network-eastus-rg'
        nsgRules: []
        routes: []
        disableBgpRoutePropagation: false
        subnets: [
          {
            name: 'Trust'
            addressPrefix: '10.0.14.0/28'
            nsg: false
            routeTable: false
          }
          {
            name: 'Untrust'
            addressPrefix: '10.0.14.16/28'
            nsg: false
            routeTable: false
          }
          {
            name: 'Mgmt'
            addressPrefix: '10.0.14.32/27'
            nsg: true
            routeTable: true
          }
        ]
        tags: {
          Environment: 'Prod'
          HoursOfOperation: '24-7'
        }
      }
    ] 
    policyAssignments: []         
  }   
}

module routeServerVpn '../../Modules/Microsoft.Network/virtualHubs/routeServer.bicep' = {
  name: 'Route-VPN-Server-Deploy'
  scope: resourceGroup('32eb88b4-4029-4094-85e3-ec8b7ce1fc00','core-vpn-networking-eastus-rg')
  dependsOn: [
    baseInfra
  ]
  params: {
    location: 'eastus'
    routeServerName: 'rt-server'
    vnetId: resourceId('32eb88b4-4029-4094-85e3-ec8b7ce1fc00','core-vpn-networking-eastus-rg','Microsoft.Network/virtualNetworks','core-vpn-vnet-eastus')
    tags: {
      Environment: 'Prod'
    } 
    allowBranchToBranchTraffic: false 
  } 
}

module routeServerEr '../../Modules/Microsoft.Network/virtualHubs/routeServer.bicep' = {
  name: 'Route-ER-Server-Deploy'
  scope: resourceGroup('32eb88b4-4029-4094-85e3-ec8b7ce1fc00','core-er-networking-eastus-rg')
  dependsOn: [
    baseInfra
  ]
  params: {
    location: 'eastus'
    routeServerName: 'rt-server'
    vnetId: resourceId('32eb88b4-4029-4094-85e3-ec8b7ce1fc00','core-er-networking-eastus-rg','Microsoft.Network/virtualNetworks','core-er-vnet-eastus')
    tags: {
      Environment: 'Prod'
    } 
    allowBranchToBranchTraffic: false 
  } 
}

module networkManager '../../Modules/Microsoft.Network/networkManagers/networkManagers.bicep' = {
  name: 'Network-Manager-Deployment'
  scope: resourceGroup('32eb88b4-4029-4094-85e3-ec8b7ce1fc00','core-vpn-networking-eastus-rg')
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
  scope: resourceGroup('32eb88b4-4029-4094-85e3-ec8b7ce1fc00','core-vpn-networking-eastus-rg')
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
  scope: resourceGroup('32eb88b4-4029-4094-85e3-ec8b7ce1fc00','core-vpn-networking-eastus-rg')
  params: {
    connectivityConfigName: 'EastUS-Hub-Spoke'
    hubVnetId: resourceId('32eb88b4-4029-4094-85e3-ec8b7ce1fc00','core-vpn-networking-eastus-rg','Microsoft.Network/virtualNetworks','core-vpn-vnet-eastus')
    description: 'Peering VNETs in EastUS' 
    networkGroupId: networkManagerGroup.outputs.groupId
    networkManagerName: 'MS-Demo-NM'
  } 
}
