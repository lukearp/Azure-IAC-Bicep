# Azure AI Sandbox

## Overview
This Bicep template is designed for the deployment of various Azure resources essential for a AI Sandbox and its associated components. It uses Bicep for template generation and follows an incremental deployment mode.

## Resources Deployed
- **Resource Group**: A container that holds related resources for an Azure solution.
- **Storage Account**: Provides a unique namespace for your Azure Storage data, accessible from anywhere in the world.
- **Storage Container**: A blob container within the storage account to organize and manage blobs.
- **Search Service**: Delivers full-text search capabilities.
- **Key Vault**: Safeguards cryptographic keys and secrets used by cloud applications and services.
- **Container Registry**: Manages private Docker container images.
- **Application Insights**: An extensible Application Performance Management (APM) service for developers.
- **Machine Learning Workspace**: A centralized workspace for managing and organizing machine learning activities.
- **Azure AI Studio**: Azure AI Studio brings together various Azure AI capabilities that were previously available as standalone Azure services, providing a seamless experience for developers, data scientists, and AI engineers to build, deploy, and manage AI models and applications.

## Configuration Details
- **Network Configuration**: Optional virtual networks, network security groups, and subnets with specific IP rules and network actions.
- **Role Assignments**: Specifies role-based access controls for the resources.
- **Cognitive Services Accounts**: Configured with public access and network ACLs.
- **Diagnostics Settings**: Options for storage accounts with hierarchical namespace and diagnostics.
- **KeyVault Storage**: Option to store keys and secrets in Azure KeyVault.

## Dependencies
The resources have interdependencies, such as the machine learning workspace being linked to the storage account, key vault, container registry, and application insights.

## Conditions
The template specifies conditions for public access, diagnostics settings, and relies on reference functions to fetch output values from dependent deployments.

## Deployment Mode
The deployment is executed in an incremental mode, ensuring that only resources that do not exist are added, and existing resources are left unchanged.

For more detailed information on the deployment process and configuration, please refer to the ARM template provided.

## Parameters
param | type | notes
------|------|------
location | string | Azure Region
NamePrefix | string | Code to represent agency
deployVnet | bool | Deploy resources within a Virtual Network (new VNET will be deployed if True)
deployOpenAI | bool | Deploy Azure Open AI Studio (Subscription White Listing Required)
SubscriptionContributors | array | Array of Object IDs that will be a Contributor of the deployed Azure Subscription
NetworkAddressPrefix | string | If Deploy VNET True, the Address Space of the VNET Deployed
allowedSources | array | Array of Public IPs to restrict access to the PaaS Services.  If empty, all sources allowed.
AISearchSku | string | Sku of AI Search resource.  

## Example

```bicep
module AISandbox '.\AzureAI-Sandbox.bicep' = {
    name: 'Sandbox Deployment'
    param: {
        NamePrefix: '1234'
        deployVnet: false
        deployOpenAI: false
        SubscriptionContributors: [
            '1111-1111-11111'
            '1111-5555-77777'
        ]
        allowedSources: [
            '35.175.25.192'
        ]
        location: 'eastus'
    }
}
```