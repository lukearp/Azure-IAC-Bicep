# What is this for?
Script to remove VNET Peers

# Parameters
This script takes 1 arguments and is designed to be used in an Azure DeploymentScript.  

args[0] = Resource ID of a VNET Peer

# How to use?
```powershell
.\Remove-VNET-Peers.ps1 "/subscriptions/XXX-XXXX-XXXX-XXXX-XXXXXXX/resourceGroups/MYRG/providers/Microsoft.Network/virtualNetworks/VIRTUALNETWORKNAME/virtualNetworkPeerings/PEERINGNAME"
```