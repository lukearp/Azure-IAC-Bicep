targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  location: 'eastus'
  name: 'aks-demo'
  tags: {
    Environment: 'Prod'
    HoursOfOperation: 'N/A'  
  }   
}

module agentsubnet '../../../../../Modules/Microsoft.Network/virtualNetworks/subnets/subnets.bicep' = {
  name: 'aks-agent-AKS-Subnet-Deployment'
  scope: resourceGroup('core-spoke-network-eastus-rg')  
  params: {
    addressPrefix: '10.0.21.0/24'
    subnetName: 'aks-agent'
    vnetname: 'core-spoke-eastus-vnet'
    routeTableName: 'core-spoke-eastus-vnet-eastus-rt'
    nsgName: 'core-spoke-eastus-vnet-eastus-nsg'  
  } 
}

module acisubnet '../../../../../Modules/Microsoft.Network/virtualNetworks/subnets/subnets.bicep' = {
  name: 'aks-aci-AKS-Subnet-Deployment'
  scope: resourceGroup('core-spoke-network-eastus-rg')  
  params: {
    addressPrefix: '10.0.22.0/26'
    subnetName: 'aks-aci'
    vnetname: 'core-spoke-eastus-vnet'
    routeTableName: 'core-spoke-eastus-vnet-eastus-rt'
    nsgName: 'core-spoke-eastus-vnet-eastus-nsg'  
  } 
}

module aks '../../../../../Modules/Microsoft.ContainerService/managedClusters.bicep' = {
  name: 'Luke-AKS-Demo-Deploy'
  scope: resourceGroup(rg.name)
  params: {
    aadProfileEnabled: true
    aciConnectorLinuxEnabled: true
    aciVnetSubnetName: split(acisubnet.outputs.subnetId,'/')[10]
    dnsPrefix: 'luke-aks-deploy'
    networkPlugin: 'azure'
    internalAddressCider: '192.168.0.0/16'
    dnsServiceIP: '192.168.0.10'
    location: 'eastus'
    name: 'aks-demo'
    networkPolicy: 'null'
    tier: 'Free'
    tags: {
      Environment: 'Prod'
      HoursOfOperation: 'N/A'  
    }
    kubernetesVersion: '1.22.6'
    adminGroupObjectIDs: [
      'c3e931b2-c462-42a9-a2ea-f626d2c8ef13'
    ]
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: 0
        count: 1
        enableAutoScaling: true
        minCount: 1
        maxCount: 3
        vmSize: 'Standard_B4ms'
        osType: 'Linux'
        storageProfile: 'ManagedDisks'
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        maxPods: 60
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
        nodeLabels: {}
        nodeTaints: []
        enableNodePublicIP: false
        tags: {}
        vnetSubnetID: agentsubnet.outputs.subnetId
      }
    ] 
    enableRBAC: true                            
  }    
}
