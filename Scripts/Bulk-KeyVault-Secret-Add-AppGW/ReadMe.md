# What does this script do?
Bulk adds KeyVault Certificates to Application Gateways 

# What does this module Require?
Managed Identity with rights to Get,List from the KeyVault/s
Networking configured to allow the App Gateway Subnets to access the KeyVault/s

# Parameters
param | type | notes
------|------|------
Currently no paramters.  You just set the values of the top two variables:

```powershell
$keyVaultSecrets = @(
    "https://<keyvaultname>.vault.azure.net:443/secrets/<certificatename>/",
    "https://<keyvaultname>.vault.azure.net:443/secrets/<certificatename>/"
)
$managedIdentity = "<Managed-Identity-ResourceID>"
```