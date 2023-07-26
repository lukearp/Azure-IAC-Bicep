param name string
param location string
@description('Optional DNS prefix to use with hosted Kubernetes API server FQDN.')
param dnsPrefix string

@description('The version of Kubernetes.')
param kubernetesVersion string = '1.7.7'

@description('Network plugin used for building Kubernetes network.')
@allowed([
  'azure'
  'kubenet'
])
param networkPlugin string

@description('Boolean flag to turn on and off of RBAC.')
param enableRBAC bool = true

@description('An array of AAD group object ids to give administrative access.')
param adminGroupObjectIDs array = []

@description('Enable private network access to the Kubernetes cluster.')
param enablePrivateCluster bool = false

@description('Boolean flag to turn on and off http application routing.')
param enableHttpApplicationRouting bool = false

@description('Boolean flag to turn on and off Azure Policy addon.')
param enableAzurePolicy bool = false

@description('Boolean flag to turn on and off secret store CSI driver.')
param enableSecretStoreCSIDriver bool = false

@description('Boolean flag to turn on and off omsagent addon.')
param enableOmsAgent bool = false
@description('Specify the resource id of the OMS workspace.')
param omsWorkspaceId string = ''
param aadProfileEnabled bool
param agentPoolProfiles array
param internalAddressCider string
@description('Containers DNS server IP address.')
param dnsServiceIP string
@description('Network policy used for building Kubernetes network. Values \'azure\' | \'calico\' | null')
@allowed([
  'null'
  'azure'
  'calico'
])
param networkPolicy string
@description('A CIDR notation IP for Docker bridge.')
param dockerBridgeCidr string = '172.17.0.1/16'
@description('A Cidr to use for the Pods when Kubenet is used.')
param podCidr string = ''
@description('Name of virtual network subnet used for the ACI Connector.')
param aciVnetSubnetName string

@description('Enables the Linux ACI Connector.')
param aciConnectorLinuxEnabled bool
@allowed([
  'Paid'
  'Free'
])
param tier string
param tags object

var networkProfile = networkPolicy == 'null' && networkPlugin == 'azure' ? {
  loadBalancerSku: 'standard'
  networkPlugin: networkPlugin
  networkPolicy: null
  serviceCidr: internalAddressCider
  dnsServiceIP: dnsServiceIP
  dockerBridgeCidr: dockerBridgeCidr 
} : networkPolicy == 'null' && networkPlugin != 'azure' ? {
  loadBalancerSku: 'standard'
  networkPlugin: networkPlugin
  networkPolicy: null
  serviceCidr: internalAddressCider
  dnsServiceIP: dnsServiceIP
  dockerBridgeCidr: dockerBridgeCidr
  podCidr: podCidr 
} : networkPolicy != 'null' && networkPlugin == 'azure' ? {
  loadBalancerSku: 'standard'
  networkPlugin: networkPlugin
  networkPolicy: networkPolicy
  serviceCidr: internalAddressCider
  dnsServiceIP: dnsServiceIP
  dockerBridgeCidr: dockerBridgeCidr 
} : {
  loadBalancerSku: 'standard'
  networkPlugin: networkPlugin
  networkPolicy: networkPolicy
  serviceCidr: internalAddressCider
  dnsServiceIP: dnsServiceIP
  dockerBridgeCidr: dockerBridgeCidr 
  podCidr: podCidr
}

var addonProfiles = enableOmsAgent == true && aciConnectorLinuxEnabled == true ? {
  httpApplicationRouting: {
    enabled: enableHttpApplicationRouting 
  }
  azurepolicy: {
    enabled: enableAzurePolicy
  }
  azureKeyvaultSecretsProvider: {
    enabled: enableSecretStoreCSIDriver
  }
  omsAgent: {
    enabled: enableOmsAgent
    config: {
      logAnalyticsWorkspaceResourceID: omsWorkspaceId
    }
  }
  aciConnectorLinux: {
    enabled: aciConnectorLinuxEnabled
    config: {
      SubnetName: aciVnetSubnetName 
    }
 }
} : enableOmsAgent == false && aciConnectorLinuxEnabled == true ? {
  httpApplicationRouting: {
    enabled: enableHttpApplicationRouting 
  }
  azurepolicy: {
    enabled: enableAzurePolicy
  }
  azureKeyvaultSecretsProvider: {
    enabled: enableSecretStoreCSIDriver
  }
  aciConnectorLinux: {
    enabled: aciConnectorLinuxEnabled
    config: {
      SubnetName: aciVnetSubnetName 
    }
 }
} : enableOmsAgent == true && aciConnectorLinuxEnabled == false ? {
  httpApplicationRouting: {
    enabled: enableHttpApplicationRouting 
  }
  azurepolicy: {
    enabled: enableAzurePolicy
  }
  azureKeyvaultSecretsProvider: {
    enabled: enableSecretStoreCSIDriver
  }
  omsAgent: {
    enabled: enableOmsAgent
    config: {
      logAnalyticsWorkspaceResourceID: omsWorkspaceId
    }
  }
} : {
  httpApplicationRouting: {
    enabled: enableHttpApplicationRouting 
  }
  azurepolicy: {
    enabled: enableAzurePolicy
  }
  azureKeyvaultSecretsProvider: {
    enabled: enableSecretStoreCSIDriver
  }
}

resource aks 'Microsoft.ContainerService/managedClusters@2022-03-02-preview' = {
 name: name
 location: location  
 identity: {
   type: 'SystemAssigned' 
 }
 sku: {
   name: 'Basic'
   tier: tier  
 }
 tags: tags
 properties: { 
   aadProfile: {
      managed: aadProfileEnabled
      adminGroupObjectIDs: adminGroupObjectIDs
   }
   apiServerAccessProfile: {
     enablePrivateCluster: enablePrivateCluster
   }
   enableRBAC: enableRBAC
   dnsPrefix: dnsPrefix
   kubernetesVersion: kubernetesVersion 
   addonProfiles: addonProfiles
  networkProfile: networkProfile 
  agentPoolProfiles: agentPoolProfiles     
 }    
}
