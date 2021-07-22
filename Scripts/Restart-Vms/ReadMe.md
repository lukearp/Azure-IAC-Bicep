# What is this for?
Script to restart Azure VMs

# Parameters
This script takes 3 arguments and is designed to be used in an Azure DeploymentScript.  

args[0] = Bicep friendly array of VM Names.  Ex: ['vm1''vm2']
args[1] = Azure Resource Group name that the VMs are located in
args[2] = Azure Subscription ID the VMs are located in.

# How to use?
```powershell
.\restart-vms.ps1 "['vm1''vm2']" "myResourceGroup" "xxx-xxxx-xxxxx"
```