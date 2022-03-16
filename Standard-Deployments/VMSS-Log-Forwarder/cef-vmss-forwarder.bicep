targetScope = 'subscription'
param targetResourceGroup string
param location string
@metadata({
  description: 'The base name for the VM Scale Set. The VMSS name will be set to the value of this parameter plus \'-vmss\'.'
})
param BaseName string
@metadata({
  description: 'The minimum number of autoscale instances.'
})
@minValue(1)
param AutoscaleMin int = 1
@metadata({
  description: 'The maximum number of autoscale instances.'
})
@maxValue(10)
param AutoscaleMax int = 5
@allowed([
  'Standard_F4s_v2'
])
@metadata({
  description: 'The VM / instance size to use for the scale set instances.'
})
param InstanceSize string = 'Standard_F4s_v2'
@metadata({
  description:'The disk size of the OS drive of each instance.'
})
@allowed([
  32
  64
])
param DiskSize int = 64
@allowed([
  'UbuntuServer-20.04-LTS'
  'UbuntuServer-18.04-LTS'
])
@metadata({
  description: 'The OS publisher, image, and SKU to use for the scale set instances.'
})
param OSImage string = 'UbuntuServer-20.04-LTS'
@metadata({
  description: 'The administrative username for the scale set instances.'
})
param AdminUserName string = 'syslogcef'
@secure()
@metadata({
  description: 'The administrative password for the scale set instances.'
})
param AdminPassword string
@metadata({
  description: 'The name of the storage account used for boot diagnostics in the VMSS.'
})
param StroageAccountName string
@metadata({
  description: 'Indicates whether a new storage account, used for boot diagnostics in the VMSS, is deployed.'
})
param DeployNewStorageAccount bool = false
param WorkspaceId string
@secure()
param WorkspaceKey string
param VNetResourceID string
param LBSubnetName string
param VMSSSubnetName string
@allowed([
  'External'
  'Internal'
])
param LoadBalancerAccessibility string = 'Internal'
param LoadBalancerFrontendIPIsStatic bool = false
@metadata({
  description: 'When the frontend load balancer is available internally and a private static IP address should be used, indicates the private static IP address to use.'
})
param LoadBalancerFrontendPrivateStaticIPAddress string = ''
param tags object = {}

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  location: location
  name: targetResourceGroup
  tags: tags 
}

module storageAccount 'storage.bicep' = if(DeployNewStorageAccount == true) {
  scope: resourceGroup(rg.name)
  name: 'Storage-Account-Deploy'
  params: {
    location: location
    StroageAccountName: StroageAccountName 
    tags: tags 
  }    
}

module pipLb 'publicIp.bicep' = if(LoadBalancerAccessibility == 'External') {
  name: 'PIP-Deploy'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    name: '${BaseName}-PIPLB' 
    tags: tags
  }    
}

var pipValue = LoadBalancerAccessibility == 'External' ? pipLb.outputs.id : ''

module lb 'lb.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'LB-Deploy'
  params: {
    location: location
    name: '${BaseName}-LB'
    tags: tags
    type: LoadBalancerAccessibility
    pipId: pipValue
    subnetId: '${VNetResourceID}/subnets/${LBSubnetName}'
    staticIp: LoadBalancerFrontendIPIsStatic == true ? LoadBalancerFrontendPrivateStaticIPAddress : ''       
  }  
}

module vmss 'vmss.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'VMSS-Deploy'
  params: {
    AutosccaleMin: AutoscaleMin
    AutosccaleMax: AutoscaleMax
    backendPoolId: lb.outputs.backendPoolId
    BaseName: BaseName
    DiskSize: DiskSize
    InstanceSize: InstanceSize
    location: location
    name: BaseName
    OSImage: OSImage
    password: AdminPassword
    username: AdminUserName
    StorageAccountName: StroageAccountName
    subnetId: '${VNetResourceID}/subnets/${VMSSSubnetName}'
    tags: tags
    WorkspaceKey: WorkspaceKey
    WorkspaceId: WorkspaceId            
  } 
}
