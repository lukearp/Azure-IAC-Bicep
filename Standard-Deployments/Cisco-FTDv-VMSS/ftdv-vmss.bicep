param namePrefix string
param vnetName string
param vnetRg string
param adminUsername string
@secure()
param adminPassword string
@allowed([
  'ftdv-azure-byol'
  'ftdv-azure-payg'
])
param imageSku string
@allowed([
  '700.94.0'
  '67065.0.0'
  '66459.0.0'
  '640110.0.0'
])
param imageVersion string
@allowed([
  'Standard_D3'
  'Standard_D3_v2'
  'Standard_D4_v2'
  'Standard_D5_v2'
])
param vmSize string = 'Standard_D3_v2'
param zones array = []
param count int = 1
param mgmtSubnet string
param diagSubnet string
param insideSubnet string
param outsideSubnet string
param location string

var elbName = '${namePrefix}-elb'
var ilbName = '${namePrefix}-ilb'
var vmssName = '${namePrefix}-vmss'
var customData = concat('{"AdminPassword":"', adminPassword, '","Hostname": "cisco-ftdv", "FmcIp": "DONTRESOLVE", "FmcRegKey":"1234", "FmcNatId":"5678"}')
var imagePublisher = 'cisco'
var imageOffer = 'cisco-ftdv'

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetRg) 
}

resource elbpip 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: '${elbName}-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource elb 'Microsoft.Network/loadBalancers@2021-05-01' = {
  name: elbName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEnd'
        properties: {
          publicIPAddress: {
            id: elbpip.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'backendPool'
      }
    ]
    loadBalancingRules: [
      {
        properties: {
          frontendIPConfiguration: {
            id: '${resourceId('Microsoft.Network/loadBalancers', elbName)}/frontendIpConfigurations/LoadBalancerFrontend' 
          }
          backendAddressPool: {
            id: '${resourceId('Microsoft.Network/loadBalancers', elbName)}/backendAddressPools/BackendPool' 
          }
          probe: {
            id: '${resourceId('Microsoft.Network/loadBalancers', elbName)}/probes/lbprobe' 
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          idleTimeoutInMinutes: 30 
        }
        name: 'lbrule' 
      } 
    ]
    probes: [
      {
        properties: {
          protocol: 'Tcp'
          port: 22
          intervalInSeconds: 5
          numberOfProbes: 2
        }
        name: 'lbprobe'
      }
    ] 
  }
}

resource ilb 'Microsoft.Network/loadBalancers@2021-05-01' = {
  name: ilbName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEnd'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/${insideSubnet}'
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'backendPool'
      }
    ]
    loadBalancingRules: [
      {
        properties: {
          frontendIPConfiguration: {
            id: '${resourceId('Microsoft.Network/loadBalancers',ilbName)}/frontendIpConfigurations/LoadBalancerFrontend' 
          }
          backendAddressPool: {
            id: '${resourceId('Microsoft.Network/loadBalancers',ilbName)}/backendAddressPools/BackendPool' 
          }
          probe: {
            id: '${resourceId('Microsoft.Network/loadBalancers',ilbName)}/probes/lbprobe' 
          }
          protocol: 'All'
          frontendPort: 0
          backendPort: 0
          idleTimeoutInMinutes: 30
        }
        name: 'lbrule'
      }
    ]
    probes: [
      {
        properties: {
          port: 22
          protocol: 'Tcp'
          intervalInSeconds: 5
          numberOfProbes: 2
        }
        name: 'lbprobe'
      }
    ] 
  }
}

resource ciscoFtd 'Microsoft.Compute/virtualMachineScaleSets@2021-11-01' = {
  name: vmssName
  location: location
  sku: {
    name: vmSize
    capacity: count
  }
  zones: zones 
  plan: {
    name: imageSku
    publisher: imagePublisher
    product: imageOffer
  } 
  properties: {
    singlePlacementGroup: false
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        imageReference: {
          offer: imageOffer
          publisher: imagePublisher
          sku: imageSku
          version: imageVersion 
        }
      }
      osProfile: {
        computerNamePrefix: vmssName
        adminUsername: adminUsername
        adminPassword: adminPassword
        customData: base64(customData)
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true 
        }
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'mgmt'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'myIpConfig'
                  properties: {
                    subnet: {
                      id: '${vnet.id}/subnets/${mgmtSubnet}'
                    } 
                  }
                }
              ]
            } 
          }
          {
            name: 'diag'
            properties: {
              primary: false
              ipConfigurations: [
                {
                  name: 'myIpConfig'
                  properties: {
                    subnet: {
                      id: '${vnet.id}/subnets/${diagSubnet}'
                    }
                  }
                }
              ]
            }
          }
          {
            name: 'outside'
            properties: {
              primary: false
              enableAcceleratedNetworking: true
              enableIPForwarding: true  
              ipConfigurations: [
                {
                  name: 'myIpConfig'
                  properties: {
                    subnet: {
                      id: '${vnet.id}/subnets/${outsideSubnet}'
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: '${elb.id}/backendAddressPools/backendPool'
                      }
                    ]
                  }
                }
              ]
            }
          }
          {
            name: 'inside'
            properties: {
              primary: false
              enableAcceleratedNetworking: true
              enableIPForwarding: true  
              ipConfigurations: [
                {
                  name: 'myIpConfig'
                  properties: {
                    subnet: {
                      id: '${vnet.id}/subnets/${insideSubnet}'
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: '${ilb.id}/backendAddressPools/backendPool'
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      } 
    } 
  }
}
