# What does this do?
Gives a quick way to enable and disable a collection of Logic apps by giving a resource group.  

# What is required?
Az Powershell Commandlets installed:

```powershell
Install-Module -Name Az
```
Azure RBAC Permisions on specified Resource Group to set the status of the Logic App.

# Parameters
param | type | notes
------|------|------
resourceGroupName | string | Required, Name of Resource Group
Disable | switch | Set switch to disable logic apps.  Don't set if you want to enable

# Example
```powershell
# Enable
.\Set-LogicAppStatus.ps1 -resourceGroupName "My-RG"

# Disable
.\Set-LogicAppStatus.ps1 -resourceGroupName "My-RG" -Disable
```
