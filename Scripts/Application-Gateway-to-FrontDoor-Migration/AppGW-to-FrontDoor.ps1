param (
    [string]$appGatewayName,
    [string]$appGatewayRg,
    [string]$frontDoorName,
    [string]$frontDoorRg,
    [string]$csvPath
)

$appGateway = Get-AzApplicationGateway -Name $appGatewayName -ResourceGroupName $appGatewayRg
$frontDoor = Get-AzFrontDoorCdnProfile -Name $frontDoorName -ResourceGroupName $frontDoorRg
$endpoint = Get-AzFrontDoorCdnEndpoint -ProfileName $frontDoor.Name -ResourceGroupName $frontDoor.ResourceGroupName
$hostNames = $appGateway.HttpListeners.HostNames
$hostNames += $appGateway.HttpListeners.HostName
$hostNames = $hostNames | Select -Unique
Add-Content -Path $csvPath -Value "TXTRcrd,Value"
foreach ($hostName in $hostNames[0..99]) {
    $token = $null
    $token = (New-AzFrontDoorCdnCustomDomain -CustomDomainName $hostName.Split(".")[0] -ProfileName $frontDoor.Name -ResourceGroupName $frontDoor.ResourceGroupName -HostName $hostName).ValidationPropertyValidationToken
    Add-Content -Path $csvPath -Value "_dnsauth.$($hostName),$($token)" 
}

if ($hostNames.Count -gt 100) {
    Add-Content -Path ".\log.txt" -Value $($hostNames[100..$($hostNames.Count)] -join "`n")
}

$ruleSet = New-AzFrontDoorCdnRuleSet -Name "RedirectRules" -ProfileName $frontDoor.Name -ResourceGroupName $frontDoor.ResourceGroupName
$origionGroup = Get-AzFrontDoorCdnOriginGroup -ProfileName $frontDoor.Name -ResourceGroupName $frontDoor.ResourceGroupName
$rules = @()
$rulesOver100 = @()
$totalHosts = 0
foreach ($listener in $appGateway.HttpListeners) {    
    $appGwRoutingRule = $appGateway.RequestRoutingRules | ? { $_.HttpListener.Id.Split("/")[-1] -eq $listener.Name }
    $redirectRule = $appGateway.RedirectConfigurations | ? { $_.Id -eq $appGwRoutingRule.RedirectConfiguration.Id }
    $listenerHostNames = $listener.HostName
    $listenerHostNames += $listener.HostNames
    $customDomains = @()
    foreach ($hostName in $listenerHostNames) {
        if ($totalHosts -le 99) {
            $rules += New-Object -TypeName psobject -Property @{
                hostname       = $hostName
                redirectTarget = $redirectRule.TargetUrl
            }
            $customDomains += Get-AzFrontDoorCdnCustomDomain -CustomDomainName $hostName.Split(".")[0] -ProfileName $frontDoor.Name -ResourceGroupName $frontDoor.ResourceGroupName
        }        
        else {
            $rulesOver100 += New-Object -TypeName psobject -Property @{
                hostname       = $hostName
                redirectTarget = $redirectRule.TargetUrl
            }
        }
        $totalHosts++;
    }
    if($totalHosts -le 99)
    {
        New-AzFrontDoorCdnRoute -EndpointName $endpoint.Name -Name $listener.Name -ProfileName $frontDoor.Name -ResourceGroupName $frontDoor.ResourceGroupName -RuleSet $ruleSet -ForwardingProtocol 'MatchRequest' -HttpsRedirect 'Disabled' -CustomDomain $customDomains -OriginGroupId $origionGroup.Id
    }
}
$count = 1
foreach ($rule in $rules) {
    $name = $("Rule" + $count)
    $condition = New-AzFrontDoorCdnRuleHostNameConditionObject -Name 'HostName' -ParameterMatchValue $rule.hostname -ParameterOperator 'Equal'
    $targetHost = $rule.redirectTarget.Split("://")[1].split("/")[0]
    $targetPath = "/" + $($rule.redirectTarget.Split("://")[1].split("/")[1..$($rule.redirectTarget.Split("://").split("/").count - 1) ] -join "/")
    if ($rule.redirectTarget.Split("://")[1].split("/").count -gt 0) {
        $action = New-AzFrontDoorCdnRuleUrlRedirectActionObject -Name 'UrlRedirect' -ParameterRedirectType 'PermanentRedirect' -ParameterDestinationProtocol 'MatchRequest' -ParameterCustomHostname $targetHost -ParameterCustomPath $targetPath
    }
    else {
        $action = New-AzFrontDoorCdnRuleUrlRedirectActionObject -Name 'UrlRedirect' -ParameterRedirectType 'PermanentRedirect' -ParameterDestinationProtocol 'MatchRequest' -ParameterCustomHostname $targetHost
    }
    New-AzFrontDoorCdnRule -Name $name -ProfileName $frontDoor.Name -ResourceGroupName $frontDoor.ResourceGroupName -SetName $ruleSet.Name -Action $action -Condition $condition -Order $count
    $count++;
}
Out-File -FilePath ".\over100-$((Get-Date -f s).Replace(":","-")).json" -InputObject $(ConvertTo-Json -InputObject $rulesOver100)