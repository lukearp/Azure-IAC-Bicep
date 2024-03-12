# What does this do?

Searches for Azure Managed Disks that can be shared, and finds the VMs connected to these disks.  It then tags the Disks for DiskBackupNeeded == true.

VMs that have Shared Managed Disks attach cannot have VM Backups enabled through Azure Backup, so Disk Based backups are required.  These can be managed through Azure Backup Vaults.  

If the Disk is already configured for Backups in the Backup Vault, the Tag is set to False.  

# What is required?

Reader access to the Backup Vaults, Disks, and VMs.  Tag Contributor on Disks, and the Powershell Module 'Az.ResourceGraph' installed.

```
Install-Module -Name Az.ResourceGraph
```