targetScope = 'subscription'
var clusterName = 'aks-demo'
var clusterLocation = 'eastus'
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
  scope: resourceGroup('core-workloads-networking-eastus-rg')  
  params: {
    addressPrefix: '10.0.19.0/24'
    subnetName: 'aks-agent'
    vnetname: 'core-workloads-eastus-vnet'
    //routeTableName: 'core-workloads-eastus-vnet-eastus-rt'
    //nsgName: 'core-spoke-eastus-vnet-eastus-nsg'  
  } 
}

module acisubnet '../../../../../Modules/Microsoft.Network/virtualNetworks/subnets/subnets.bicep' = {
  name: 'aks-aci-AKS-Subnet-Deployment'
  scope: resourceGroup('core-workloads-networking-eastus-rg')  
  params: {
    addressPrefix: '10.0.18.0/26'
    subnetName: 'aks-aci'
    vnetname: 'core-workloads-eastus-vnet'
    //routeTableName: 'core-workloads-eastus-vnet-eastus-rt'
    //nsgName: 'core-spoke-eastus-vnet-eastus-nsg'  
  } 
}

module workspace 'loganalytics-workspaces.bicep' = {
  name: 'AKS-Demo-Workspace-Logging'  
}

module keyVault '../../../../../Modules/Microsoft.Keyvault/vaults.bicep' = {
  name: 'AKS-Secret-Vault'
  scope: resourceGroup(rg.name)
  params: {
    location: 'eastus'
    name: 'AKS-Secret-Vault'
    sku: 'standard'
    tags: {
      Environment: 'Prod'
    }    
    enableRbacAuthorization: true  
  }   
}

module acr '../../../../../Modules/Microsoft.ContainerRegistry/registries.bicep' = {
  name: 'Luke-AKS-Demo-ACR-Deploy'
  scope: resourceGroup(rg.name)
  params: {
    location: 'eastus'
    name: 'luke-aks-demo-acr'
    adminUserEnabled: true
    anonymousPullEnabled: false
    sku: 'Basic'
    tags: {
      Environment: 'Prod'
    }
    zoneRedundancy: 'Disabled'       
  }   
}

module aks '../../../../../Modules/Microsoft.ContainerService/managedClusters.bicep' = {
  name: 'Luke-AKS-Demo-Deploy'
  scope: resourceGroup(rg.name)
  params: {
    aadProfileEnabled: true
    aciConnectorLinuxEnabled: false
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
        enableAutoScaling: false
        //minCount: 1
        //maxCount: 3
        vmSize: 'Standard_B4ms'
        osType: 'Linux'
        storageProfile: 'ManagedDisks'
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        maxPods: 50
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
    enableOmsAgent: true
    omsWorkspaceId: workspace.outputs.workspaceResourceId   
    enableSecretStoreCSIDriver: true                          
  }    
}

module keyvaultIdentity '../../../../../Modules/Microsoft.ManagedIdentity/userAssignedIdentities.bicep' = {
  name: 'AKS-Keyvault-ManagedIdentity-ClientId'
  dependsOn: [
    aks
  ]
  scope: resourceGroup('MC_${rg.name}_${clusterName}_${clusterLocation}')  
  params: {
    location: clusterLocation
    name: 'azurekeyvaultsecretsprovider-${clusterName}'  
    tags: {
      Environment: 'Prod'
      HoursOfOperation: 'N/A'
      AutoStop: 'True'
    } 
  }
}

module keyVaultRbac '../../../../../Modules/Microsoft.Authorization/roleAssignments/roleAssignments-rg.bicep' = {
  name: 'Keyvault-RBAC-Assignment'
  scope: resourceGroup(rg.name)
  dependsOn: [
    keyVault
  ]
  params: {
    name: 'Kevault-SPN'
    objectId: keyvaultIdentity.outputs.principalId 
    roleDefinitionId: '4633458b-17de-408a-b874-0445c86b69e6'  
  } 
}
