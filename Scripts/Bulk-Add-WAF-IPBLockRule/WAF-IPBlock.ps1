$ErrorActionPreference = 'Stop'

$ruleName = 'BlockMaliciousIP'
$defaultIpsToBlock = @(
    '1.1.1.1',
    '20.50.10.2',
    '24.40.10.2'
)

function Test-IpMatchValue {
    param([Parameter(Mandatory)][string]$Value)

    $parts = $Value.Split('/', 2)
    $parsedAddress = $null
    if (-not [IPAddress]::TryParse($parts[0], [ref]$parsedAddress)) {
        return $false
    }

    if ($parts.Count -eq 1) {
        return $true
    }

    $prefixLength = 0
    if (-not [int]::TryParse($parts[1], [ref]$prefixLength)) {
        return $false
    }

    $maximumPrefixLength = if ($parsedAddress.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork) { 32 } else { 128 }
    return $prefixLength -ge 0 -and $prefixLength -le $maximumPrefixLength
}

function New-ApplicationGatewayBlockRule {
    param([Parameter(Mandatory)][string[]]$MatchValues)

    return [ordered]@{
        name                   = $ruleName
        priority               = 1
        state                  = 'Enabled'
        ruleType               = 'MatchRule'
        action                 = 'Block'
        skippedManagedRuleSets = @()
        matchConditions        = @(
            [ordered]@{
                operator           = 'IPMatch'
                negationConditon   = $false
                matchVariables     = @(
                    [ordered]@{
                        variableName = 'RemoteAddr'
                    }
                )
                matchValues        = $MatchValues
                transforms         = @()
            }
        )
    }
}

function New-FrontDoorBlockRule {
    param([Parameter(Mandatory)][string[]]$MatchValues)

    return [ordered]@{
        name                       = $ruleName
        priority                   = 1
        ruleType                   = 'MatchRule'
        action                     = 'Block'
        rateLimitDurationInMinutes = 1
        enabledState               = 'Enabled'
        rateLimitThreshold         = 0
        matchConditions            = @(
            [ordered]@{
                operator        = 'IPMatch'
                negateCondition = $false
                matchVariable   = 'RemoteAddr'
                transforms      = @()
                matchValue      = $MatchValues
                selector        = $null
            }
        )
    }
}

function Get-ReorderedRules {
    param(
        [AllowNull()][object[]]$ExistingRules,
        [Parameter(Mandatory)]$NewRule
    )

    # Remove every prior copy of BlockMaliciousIP, then shift only rules whose
    # priorities conflict with the new priority 1 or with another shifted rule.
    $remainingRules = @(
        $ExistingRules |
            Where-Object { $_.name -ine $ruleName } |
            Sort-Object @{ Expression = { [int]$_.priority } }, @{ Expression = { [string]$_.name } }
    )

    $nextAvailablePriority = 2
    foreach ($rule in $remainingRules) {
        $assignedPriority = [Math]::Max([int]$rule.priority, $nextAvailablePriority)
        if ($assignedPriority -gt 100) {
            throw "Rule '$($rule.name)' cannot be shifted because custom-rule priority 100 is already occupied."
        }

        $rule.priority = $assignedPriority
        $nextAvailablePriority = $assignedPriority + 1
    }

    return @($NewRule) + $remainingRules
}

function Get-WafPolicies {
    $query = @'
resources
| where type in~ (
    "microsoft.network/applicationgatewaywebapplicationfirewallpolicies",
    "microsoft.network/frontdoorwebapplicationfirewallpolicies"
)
| project id, name, type
| order by type asc, name asc
'@

    $policies = @()
    $skipToken = $null

    do {
        if ($skipToken) {
            $page = Search-AzGraph -Query $query -UseTenantScope -First 1000 -SkipToken $skipToken
        }
        else {
            $page = Search-AzGraph -Query $query -UseTenantScope -First 1000
        }

        $policies += @($page)
        $skipToken = $page.SkipToken
    } while ($skipToken)

    return $policies
}

function Update-WafPolicy {
    param(
        [Parameter(Mandatory)]$Policy,
        [Parameter(Mandatory)][string[]]$MatchValues
    )

    $policyType = ([string]$Policy.type).ToLowerInvariant()
    switch ($policyType) {
        'microsoft.network/applicationgatewaywebapplicationfirewallpolicies' {
            $apiVersion = '2024-05-01'
            $policyKind = 'ApplicationGateway'
        }
        'microsoft.network/frontdoorwebapplicationfirewallpolicies' {
            $apiVersion = '2022-05-01'
            $policyKind = 'FrontDoor'
        }
        default {
            throw "Unsupported WAF policy type '$($Policy.type)'."
        }
    }

    $path = "$($Policy.id)?api-version=$apiVersion"
    $getResponse = Invoke-AzRestMethod -Path $path -Method GET
    $resource = $getResponse.Content | ConvertFrom-Json

    if ($policyKind -eq 'ApplicationGateway') {
        $existingRules = @($resource.properties.customRules)
        $newRule = New-ApplicationGatewayBlockRule -MatchValues $MatchValues
        $updatedRules = @(Get-ReorderedRules -ExistingRules $existingRules -NewRule $newRule)

        if ($null -eq $resource.properties.PSObject.Properties['customRules']) {
            $resource.properties | Add-Member -NotePropertyName customRules -NotePropertyValue $updatedRules
        }
        else {
            $resource.properties.customRules = $updatedRules
        }
    }
    else {
        $existingRules = @($resource.properties.customRules.rules)
        $newRule = New-FrontDoorBlockRule -MatchValues $MatchValues
        $updatedRules = @(Get-ReorderedRules -ExistingRules $existingRules -NewRule $newRule)

        if ($null -eq $resource.properties.customRules) {
            $resource.properties | Add-Member -NotePropertyName customRules -NotePropertyValue ([pscustomobject]@{ rules = $updatedRules })
        }
        else {
            $resource.properties.customRules.rules = $updatedRules
        }
    }

    # Only send writable policy properties. GET responses also contain read-only
    # fields such as provisioningState and resource associations.
    $writableProperties = [ordered]@{
        customRules    = $resource.properties.customRules
        policySettings = $resource.properties.policySettings
        managedRules   = $resource.properties.managedRules
    }

    $payload = [ordered]@{
        location   = $resource.location
        properties = $writableProperties
    }

    if ($null -ne $resource.tags) {
        $payload.tags = $resource.tags
    }

    if ($null -ne $resource.sku) {
        $payload.sku = $resource.sku
    }

    $putResponse = Invoke-AzRestMethod `
        -Path $path `
        -Method PUT `
        -Payload ($payload | ConvertTo-Json -Depth 100 -Compress)

    return [ordered]@{
        policyName = $Policy.name
        policyType = $policyKind
        resourceId = $Policy.id
        statusCode = $putResponse.StatusCode
        ruleCount  = $updatedRules.Count
    }
}

try {
    $ipsToBlock = $defaultIpsToBlock

    $ipsToBlock = @($ipsToBlock | Sort-Object -Unique)
    if ($ipsToBlock.Count -eq 0) {
        throw 'At least one IP address or CIDR range must be supplied in ipsToBlock.'
    }

    $invalidValues = @($ipsToBlock | Where-Object { -not (Test-IpMatchValue -Value $_) })
    if ($invalidValues.Count -gt 0) {
        throw "Invalid IP address or CIDR value(s): $($invalidValues -join ', ')"
    }

    $policies = @(Get-WafPolicies)
    $results = @()

    foreach ($policy in $policies) {
        try {
            $results += Update-WafPolicy -Policy $policy -MatchValues $ipsToBlock
        }
        catch {
            Write-Warning "Failed to update WAF policy '$($policy.id)': $($_.Exception.Message)"
            $results += [ordered]@{
                policyName = $policy.name
                policyType = $policy.type
                resourceId = $policy.id
                statusCode = $null
                error      = $_.Exception.Message
            }
        }
    }

    # $failureCount = @($results | Where-Object { $_.error }).Count
    # $statusCode = if ($failureCount -eq 0) { 200 } elseif ($failureCount -lt $results.Count) { 207 } else { 500 }
    # $responseBody = [ordered]@{
    #     ruleName     = $ruleName
    #     matchValues  = $ipsToBlock
    #     policyCount  = $policies.Count
    #     successCount = $policies.Count - $failureCount
    #     failureCount = $failureCount
    #     results      = $results
    # }
}
catch {
    Write-Warning $_.Exception.Message
    # $statusCode = 400
    # $responseBody = [ordered]@{
    #     error = $_.Exception.Message
    # }
}
