targetScope = 'subscription'

var dnsServers = [
  '10.0.16.5'
]

module workloads '../../Standard-Deployments/Update-VNET-DNS/dnsServerAdd.bicep' = {
  name: 'Workload-VNET-DNS-Set'
  scope: resourceGroup('core-workloads-networking-eastus-rg')  
  params: {
    vnetName: 'core-workloads-eastus-vnet'
    dnsServers: dnsServers  
  } 
}
