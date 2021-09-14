# What does this module do?
Deploys an App Gateway, Internal APIM, KeyVault, Private DNS, and Managed Idenity.  It configures the default listeners for Dev Portal, Gateway, and Management.  The SSL Will be using KeyVault generated Certificates that are not publicly trusted.  In order to get working for full functionality, you will need to replace the App GW Listener Certificates with publicly trusted certs.  This can be generated via Azure App Service Certificates.  

Template Deploys:
1. Application Gateway with Public IP
2. Azure KeyVault
3. Private DNS Zone
4. Azure API Management Internal (Either Dev or Premium SKU)
5. User Managed Identity

# What does this module Require?
An Azure Resource Group that you have contributor rights to.  If you are using an existing VNET, you will need rights to join machines to the Subnets.  

# Parameters

# Sample Module