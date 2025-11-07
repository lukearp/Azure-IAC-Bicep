function UpdateRules {
    param (
        [array]$rules,
        $webAppName,
        $webAppResourceGroup,
        $webAppSubscription,
        [Switch]$govCloud
    )

    if ($govCloud) {
        $url = "https://management.usgovcloudapi.net/subscriptions/$($webAppSubscription)/resourceGroups/$($webAppResourceGroup)/providers/Microsoft.Web/sites/$($webAppName)/config/web?api-version=2024-11-01"
    }
    else {
        $url = "https://management.azure.com/subscriptions/$($webAppSubscription)/resourceGroups/$($webAppResourceGroup)/providers/Microsoft.Web/sites/$($webAppName)/config/web?api-version=2024-11-01"
    }

    $app = (Invoke-AzRestMethod -Method get -uri $url).Content | ConvertFrom-Json -Depth 10

    $ipRestrictionRules = $rules
    # if($app.properties.ipSecurityRestrictions.Count -gt 0)
    # {
    #     $ipRestrictionRules += $app.properties.ipSecurityRestrictions
    # }    

    $ipRestriction = New-Object -TypeName psobject -Property @{
        properties = New-Object -TypeName psobject -Property @{
            ipSecurityRestrictions              = $ipRestrictionRules
            ipSecurityRestrictionsDefaultAction = "Deny"
        }
    }

    $ipRestriction.Properties.ipSecurityRestrictions.Add($app.properties.ipSecurityRestrictions)

    Invoke-AzRestMethod -Method PATCH -Uri $url -Payload $(ConvertTo-Json -Depth 10 -InputObject $ipRestriction)
}

function addRules {
    param (
        [string]$sourceIp,
        [ValidateSet("Allow", "Deny")]
        [string]$action,
        [int]$priortiy,
        [string]$ruleName,
        [string]$ruleDescription = ""
    )

    return New-Object -TypeName psobject -Property @{
        ipAddress   = $sourceIp
        action      = $action
        priority    = $priortiy
        name        = $ruleName 
        description = $ruleDescription
    }
}