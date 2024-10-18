# What does this script do?
Renames an Azure Virtual Machine.  It enumerates through all Network Interfaces and Disks to make sure the Delete Option is set to Detach, removes the VM, then redeploys the same VM with a new Name. 

# What does this module Require?
Ran by user that has at least VM Contributor rights within the Azure Portal

# Parameters
param | type | notes
------|------|------
subscriptionId | string | Subscription that VM is deployed to
vmName | string | VM that will have the name changed
newVmName | string | New name of the VM
resourceGroupName | string | Resource Group Name that VM is deployed to