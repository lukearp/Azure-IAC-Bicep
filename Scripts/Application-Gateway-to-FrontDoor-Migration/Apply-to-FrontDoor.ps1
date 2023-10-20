param (
    [string]$frontDoorName,
    [string]$frontDoorRg,
    [string]$csvPath,
    [string]$dnsCsvPath = ".\dnsTXT.csv"
)

$frontDoor = Get-AzFrontDoorCdnProfile -Name $frontDoorName -ResourceGroupName $frontDoorRg
$endpoint = Get-AzFrontDoorCdnEndpoint -ProfileName $frontDoor.Name -ResourceGroupName $frontDoor.ResourceGroupName
$records = Import-Csv -Path $csvPath
$listeners = $records.Listener | Select -Unique
#Add-Content -Path $csvPath -Value "TXTRcrd,Value"
$domainCount = 0
$batchNumber = 1
$hostNames = @()
$hostNameBatch = @()
foreach ($listener in $listeners) {
    $recordsByListener = $records | ? { $_.Listener -eq $listener }
    foreach ($hostName in $recordsByListener.hostName) {
        if ($hostNames -notcontains $hostName.split("/")[0]) {
            if ($domainCount -ge 95) {
                $batchNumber++
                $domainCount = 0
            }
            $hostNames += $hostName.Split("/")[0]            
            $domainCount++
        }
        $hostNameBatch += New-Object -TypeName psobject -Property @{
            batch = $batchNumber
            hostName = $hostName.Split("/")[0]
            sourcePath = "/" + $($hostName.Split("/")[1..$($hostName.Split("/").Count)] -join "/")
            target = ($recordsByListener | ?{$_.hostName -eq $hostName}).RedirectTarget
        }
    }
}

$origionGroup = Get-AzFrontDoorCdnOriginGroup -ProfileName $frontDoor.Name -ResourceGroupName $frontDoor.ResourceGroupName

$count = 0
foreach($hostName in $hostNames)
{
    $frontdoorHost = New-AzFrontDoorCdnCustomDomain -CustomDomainName $("Domain-" + $count) -ProfileName $frontDoor.Name -ResourceGroupName $frontDoor.ResourceGroupName -HostName $hostName
    Add-Content -Path $dnsCsvPath -Value "_dnsauth.$($hostName),$($frontdoorhost.ValidationPropertyValidationToken)"
    $ruleSet = New-AzFrontDoorCdnRuleSet -Name $("Domain" + $count) -ProfileName $frontDoor.Name -ResourceGroupName $frontDoor.ResourceGroupName
    New-AzFrontDoorCdnRoute -EndpointName $endpoint.Name -Name $("Domain-" + $count) -ProfileName $frontDoor.Name -ResourceGroupName $frontDoor.ResourceGroupName -RuleSet $ruleSet -ForwardingProtocol 'MatchRequest' -HttpsRedirect 'Disabled' -CustomDomain $frontdoorHost -OriginGroupId $origionGroup.Id
    $rules = $hostNameBatch | ?{$_.hostName -eq $hostName}
    $ruleCount = 0
    foreach ($rule in $rules)
    {
        $name = $("Rule" + $ruleCount)
        $condition = New-AzCdnDeliveryRuleUrlPathConditionObject -Name 'UrlPath' -ParameterOperator Equal -ParameterMatchValue $rule.sourcePath -ParameterTransform 'Lowercase'
        $targetHost = $rule.target.Split("://")[1].split("/")[0]
        $targetPath = "/" + $($rule.target.Split("://")[1].split("/")[1..$($rule.target.Split("://").split("/").count - 1) ] -join "/")
        if ($rule.target.Split("://")[1].split("/").count -gt 0) {
            $action = New-AzFrontDoorCdnRuleUrlRedirectActionObject -Name 'UrlRedirect' -ParameterRedirectType 'PermanentRedirect' -ParameterDestinationProtocol 'MatchRequest' -ParameterCustomHostname $targetHost -ParameterCustomPath $targetPath
        }
        else {
            $action = New-AzFrontDoorCdnRuleUrlRedirectActionObject -Name 'UrlRedirect' -ParameterRedirectType 'PermanentRedirect' -ParameterDestinationProtocol 'MatchRequest' -ParameterCustomHostname $targetHost
        }
        New-AzFrontDoorCdnRule -Name $name -ProfileName $frontDoor.Name -ResourceGroupName $frontDoor.ResourceGroupName -SetName $ruleSet.Name -Action $action -Condition $condition -Order $ruleCount
        $ruleCount++;
    }
    $count++
}
<#
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
    if ($totalHosts -le 99) {
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
#>