# What does this do?
Converts App Gateway Listeners and routing rules to Azure Front Door Premium/Standard.

Currently only supports migrating Redirect Rules

# What does this require?
A user that has reader rights to the App Gateway appliance and read/write to the target Azure Front Door.  App Gateway and Front Door needs to be in the same Azure Subscription

# Parameters
param | type | notes
------|------|------
appGatewayName | string | Name of the Front Door App Gateway
appGatewayRg | string | Name of the App Gateway Resource Group
frontDoorName | string | Name of the Front Door
frontDoorRg | string | Name of the Front Door Resource Group