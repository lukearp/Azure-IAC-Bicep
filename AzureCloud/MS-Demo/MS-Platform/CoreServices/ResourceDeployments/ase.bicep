targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'Demo-ASE'
  location: 'eastus'
}

module ase '../../../../../Modules/Microsoft.Web/hostingEnvironments/hostingEnvironments.bicep' = {
  name: 'ASE'
  scope: resourceGroup(rg.name)
  params: {
    aseSubnetName: 'ASE'
    location: 'eastus'
    name: 'luke-demo-gihub'
    virtualNetworkName: 'core-workloads-eastus-vnet'
    virtualNetworkRg: 'core-workloads-networking-eastus-rg'
    kind: 'ASEV3'
    internalLoadBalancingMode: 'Web, Publishing'
    zoneRedundant: false
    tags: {
      Environment: 'Demo'
    }         
  } 
}

module logicApp '../../../../../Standard-Deployments/LogicApp-Standard/LogicApp-Standard.bicep' = {
  name: 'Logic-App-Deploy'
  scope: resourceGroup(rg.name)
  params: {
    aseId: ase.outputs.aseId
    location: 'eastus'
    name: 'luke-ase-logicapp'
    appPlanSize: 'I1V2'
    tags: {
      Environment: 'Demo'
    }    
  }
}
