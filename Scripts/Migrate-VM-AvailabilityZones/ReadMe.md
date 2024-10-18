# Script Function
To migrate a VM from a Zonal to Regional deployment.  The script will power down VM, snapshot disks, create new disks from snapshots with ZRS Redundancy, and then create a New VM with the new disks, or replace the original VMs with ZRS disks attached and zone removed.

# Parameters
param | type | notes
------|------|------
SubscriptionId | String | Subscription ID of VM
ResourceGroupName | String | Resource Group Name of VM
VMName | String | Name of VM
DiskSku | String | Disk SKU, "StandardSSD_ZRS" or "PremiumSSD_ZRS"
replaceExisting | Switch | If switch is present, original VM is deleted and replace.  If not present, new VM is created with -zrs to the name.