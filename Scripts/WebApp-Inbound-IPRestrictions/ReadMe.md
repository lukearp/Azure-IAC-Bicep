# What is this for?

Add Inbound IP Restrictions to App Service and have Public Network Access changed from Enabled from all networks to Enabled from select virtualnetworks and IP Addresses.

# How to use?

Two functions addRules and UpdateRules.  You would create an array, and then run addRules and set the parameters for the inbound sources you want to allow or deny.  Once you array is built, then you set it using the UpdateRules functions.  Below is an example:

```powershell
# . sourcing the PS1 file to load functions into session
. .\Manage-Inbound-AppService-IPRestrictions.ps1

$rules = @()
$rules += addRules -sourceIp 1.1.1.1/32 -action Allow -priortiy 100 -ruleName MyRule -ruleDescription "This is my rule"
$rules += addRules -sourceIp 2.2.2.2/32 -action Deny -priortiy 101 -ruleName DenyMe

UpdateRules -rules $rules -webAppName MyAppServices -webAppResourceGroup AppServices -webAppSubscription 456beea5-e9a5-4fde-aa3e-0000000
```