# What does this do?

Backs up the Azure Firewall Policy when an update to the policy is successfully applied.  This expects an Event Grid trigger.  Once the event is triggered, the function gets the Resource ID, exports the template, searches for an IP Groups, and adds DependsOn resource IDs to Rule Collections so deployments don't fail.  

# What is needed?

An Azure Event Grid Subscription monitoring Microsoft.Resources.ResourceWriteSuccess filtered on subject:

!(./img/EventGrid-AdvanacedFilter.png)

An Azure Function App with System Managed Identity with Reader access to the Firewall Policies that will be backed up and Reader access to all IP Groups referenced in the policy.

Target Azure Storage account with Blob versioning enabled.

