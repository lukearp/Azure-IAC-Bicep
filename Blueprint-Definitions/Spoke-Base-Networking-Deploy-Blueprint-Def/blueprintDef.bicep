targetScope = 'managementGroup'
param blueprintName string
param displayName string
param description string
param resourceGroups object = {}

resource blueprintDef 'Microsoft.Blueprint/blueprints@2018-11-01-preview' = {
  name: blueprintName 
  properties: {
    displayName: displayName
    description: description
    targetScope: 'subscription' 
    parameters: {
      deploy_vnetName: {
        type: 'string'
        metadata: {
          description: 'Name of Spoke Virtual Network'
          displayName: 'VNET Name' 
        } 
      }
      deploy_resourceGroupName: {
        type: 'string'
        metadata: {
          description: 'Name of Resource Group that Spoke VNET will be deployed too' 
          displayName: 'ResourceGroup Name'
        }
      } 
      deploy_projectTagValue: {
        type: 'string'
        metadata: {
          description: 'Value of Tag named Project' 
          displayName: 'Project Tag Value'
        }
      }
      deploy_existingVnet: {
        type: 'bool'
        metadata: {
          description: 'Is the Spoke VNET Already deployed true or false' 
          displayName: 'VNET Existing'
        }
      }
      deploy_addressspaceOctet3int: {
        type: 'int'
        metadata: {
          description: '3rd Octect of the IPv4 address space.  The first two are vars in the template' 
          displayName: 'Value for third Octect'
        }
      }
      deploy_CIDR: {
        type: 'string'
        metadata: {
          description: 'CIDR value for the VNET Address Space' 
          displayName: 'CIDR'
        }
      }
      deploy_dnsServers: {
        type: 'array'
        metadata: {
          description: 'Array of DNS Server IPs' 
          displayName: 'DNS Servers'
        }
      }
      deploy_additionalSubnet: {
        type: 'bool'
        metadata: {
          description: 'Are you deploying new Subnets to an existing VNET true or false' 
          displayName: 'Additional Subnets'
        }
      }
      deploy_subnets: {
        type: 'string'
        metadata: {
          description: 'Array of Azure ARM Subnet Objects.  If additionalSubnets is true, the subnets will be considered new' 
          displayName: 'Subnets'
        }
      }
      deploy_hubVnetId: {
        type: 'string'
        metadata: {
          description: 'Resource ID of the HUB VNET' 
          displayName: 'Hub VNET Resource ID'
        }
      }
      deploy_hubAddressSpace: {
        type: 'string'
        metadata: {
          description: 'Address space of the HUB VNET' 
          displayName: 'HUB Address Space'
        }
      }
      deploy_location: {
        type: 'string'
        metadata: {
          description: 'Target Deploy Region' 
          displayName: 'Azure Region'
        }
      }
      deploy_nvaIp: {
        type: 'string'
        metadata: {
          description: 'IPv4 address of the NVA (Firewall Appliance)'
          displayName: 'NVA IP'  
        }
      }
      deploy_gatewayRtId: {
        type: 'string'
        metadata: {
          description: 'Resource ID of the Route Table on the Gateway Subnet to ensure symmetric routing.'
          displayName: 'Gateway Subnet Route Table'  
        }
      }
      deploy_additionalAddressSpace: {
        type: 'array'
        metadata: {
          description: 'Array of Address spaces to be added to the VNET.  updateAddressSpace must = true'
          displayName: 'Additional Address Space to Add'  
        }
      }
      deploy_updateAddressSpace: {
        type: 'bool'
        metadata: {
          description: 'Add additional address space true or false'
          displayName: 'Add Additional Address Space'  
        }
      }
      deploy_userManagedIdentityId: {
        type: 'string'
        metadata: {
          description: 'Resource ID of a managed identity to handle Peer Deletions for Updated Address Space'
          displayName: 'User Managed Identity'  
        }
      }
    }
    resourceGroups: resourceGroups 
  }
}

resource artifacts 'Microsoft.Blueprint/blueprints/artifacts@2018-11-01-preview' = {
  kind: 'template'
  parent: blueprintDef
  name: 'Resources'
  properties: {
    parameters:{
      vnetName: {
        value: '[parameters(\'deploy_vnetName\')]'
      }
      resourceGroupName: {
        value: '[parameters(\'deploy_resourceGroupName\')]'
      }
      projectTagValue: {
        value: '[parameters(\'deploy_projectTagValue\')]'
      }
      existingVnet: {
        value: '[parameters(\'deploy_existingVnet\')]'
      }
      addressspaceOctet3int: {
        value: '[parameters(\'deploy_addressspaceOctet3int\')]'
      }
      CIDR: {
        value: '[parameters(\'deploy_CIDR\')]'
      }
      dnsServers: {
        value: '[parameters(\'deploy_dnsServers\')]'
      }
      additionalSubnet: {
        value: '[parameters(\'deploy_additionalSubnet\')]'
      }
      subnets: {
        value: '[parameters(\'deploy_subnets\')]'
      }
      hubVnetId: {
        value: '[parameters(\'deploy_hubVnetId\')]'
      }
      hubAddressSpace: {
        value: '[parameters(\'deploy_hubAddressSpace\')]'
      }
      location: {
        value: '[parameters(\'deploy_location\')]'
      }
      nvaIp: {
        value: '[parameters(\'deploy_nvaIp\')]'
      }
      additionalAddressSpace: {
        value: '[parameters(\'deploy_additionalAddressSpace\')]'
      }
      updateAddressSpace: {
        value: '[parameters(\'deploy_updateAddressSpace\')]'
      }
      userManagedIdentityId: {
        value: '[parameters(\'deploy_userManagedIdentityId\')]'
      }
      gatewayRtId: {
        value: '[parameters(\'deploy_gatewayRtId\')]'
      }
    }
    template: json(loadTextContent('../../Starndard-Deployments/Spoke-Base-Networking-Deploy/Spoke-Blueprint.json'))
  }  
}
