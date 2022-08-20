# What does this module do?
Deploy a VM that installs the Web-Server Role, and has the option to join the domain.

# What does this module require?

An existing Virtual Network with 1 subnets

Optional:
Key Vault with a secret for Admin Password.  The Users deploying the template will need an Access Policy to Get Secrets.

# Sample Module

```Bicep
resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: 'VAULTNAME'
  scope: resourceGroup('RESOURCEGROUPNAME')   
}

module iis '../Standard-Deployments/IIS-Server/iis-server.bicep' = {
  name: 'Web-Server'
  scope: resourceGroup('iis')
  params: {
     servername: 'web-server'
     location: 'eastus'
     vmsize: 'Standard_D3_v2'
     vnetRg: 'rg_vnet'
     vnetName: 'my-vnet'
     subnetName: 'my-subnet'
     osversion: '2019-datacenter-gensecond'
     localadmin: 'localadmin'
     localadminpassword: keyVault.getsecret('adminpass')
     domainjoin: false             
  }   
}
```
