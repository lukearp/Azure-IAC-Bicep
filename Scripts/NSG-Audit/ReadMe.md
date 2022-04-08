# What is this for?
Script to inventory all NSGs that have rules besides default rules.  All Subnets that do not have NSGs associated, and all connected devices that do not have NSGs associated.

# Parameters
nsg-audit.ps1 requires the TenantID governing the Azure Subscriptions you want to audit.  
nsg-report-gen.ps1 requires a path to the report.json file that nsg-audit.ps1 generates. 

# How to use?