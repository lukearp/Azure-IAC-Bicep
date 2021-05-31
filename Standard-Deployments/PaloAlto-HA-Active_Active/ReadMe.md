# What does this module do?
There are two options of this deployment:
1. paloAlto-ha-aa.bicep - VM Deployment
2. paloAlto-ha-vmss.bicep - Virtual Machine Scale Set Deployment

Deploys a Palo Alto HA Pair in an Active Active configuration.  Deploys:    
1. Azure Storage Account with File Share configured for Palo Boot Strapping
2. Up to 9 Palo Alto Appliances across 3 Availability Zones *If AZ Zones are supported in the Region*
3. Azure Public Load Balancer for Untrust
4. Azure Private Load Balancer for Trust

All palos will pull their default configuration from the bootstrap.xml and init-cfg.txt files within the 'config' directory of the Azure Storage Account deployed.  These default settings can be configured within the init-cfg.bicep and bootstrapxm.bicep files.

Once deployment is complete using the default bootstrapxml.bicep and init-cfg.bicep:
1. Count of appliances deployed across 3 Availability zones
2. Trust Interfaces connected to Palo-Trust Azure Standardard LB with HA ports enabled
3. Untrust Interfaces connected to Palo-Untrust with only an Outbound Rule associated for Internet NAT
4. Each Palo appliance will have the following config
    * Two Virtual Routers named Untrust and Trust
    * Two zones named Untrust and Trust
    * Default security policy allowing Trust to reach Untrust
    * NAT Rule to allow outbound access to the internet.    

# What does this module require?

An existing Virtual Network with 3 subnets:
1. Management
2. Untrust
3. Trust

A User Assigned Managed Identity that has Contributor rights to the Resource Group Scope

Key Vault with a secret for Admin Password.  The Users deploying the template will need an Access Policy to Get Secrets.

# Sample Module

```Bicep
resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: 'VAULTNAME'
  scope: resourceGroup('RESOURCEGROUPNAME')   
}

module palo '../Standard-Deployments/PaloAlto-HA-Active_Active/paloAlto-ha-aa.bicep' = {
  name: 'testPalo'
  scope: resourceGroup('bicep_palo')
  params: {
     adminPasswordSecret: keyVault.getSecret('KEYVAULTSECRET_NAME')
     adminUserName: 'localadmin'
     count: 2
     imageVersion: 'latest'
     managementSubnetName: 'mgmt'
     paloNamePrefix: 'east'
     planName: 'byol'
     planOffer: 'vmseries-forms'
     trustSubnetName: 'Trust'
     untrustSubnetName: 'Untrust'
     vmSize: 'Standard_D3_v2'
     vnetId: '/subscriptions/SUBID/resourceGroups/bicep_palo/providers/Microsoft.Network/virtualNetworks/palo-bicep'
     managedIdentityId: '/subscriptions/SUBID/resourceGroups/user-identities/providers/Microsoft.ManagedIdentity/userAssignedIdentities/template-spec'             
  }   
}
```
