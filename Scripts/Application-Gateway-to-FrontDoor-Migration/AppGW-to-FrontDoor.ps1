param (
    [string]$appGatewayName,
    [string]$appGatewayRg,
    [string]$frontDoorName,
    [string]$frontDoorRg
)

$appGateway = Get-AzApplicationGateway -Name $appGatewayName -ResourceGroupName $appGatewayRg
$frontDoor = Get-AzFrontDoorCdnProfile -Name $frontDoorName -ResourceGroupName $frontDoorRg
$endpoint = Get-AzFrontDoorCdnEndpoint -ProfileName $frontDoor.Name -ResourceGroupName $frontDoor.ResourceGroupName
$hostNames = $appGateway.HttpListeners.HostNames
$hostNames += $appGateway.HttpListeners.HostName
$hostNames = $hostNames | Select -Unique

foreach($hostName in $hostNames)
{
    New-AzFrontDoorCdnCustomDomain -CustomDomainName $hostName.Split(".")[0] -ProfileName $frontDoor.Name -ResourceGroupName $frontDoor.ResourceGroupName -HostName $hostName -AsJob
}
$ruleSet = New-AzFrontDoorCdnRuleSet -Name "RedirectRules" -ProfileName $frontDoor.Name -ResourceGroupName $frontDoor.ResourceGroupName
$origionGroup = Get-AzFrontDoorCdnOriginGroup -ProfileName $frontDoor.Name -ResourceGroupName $frontDoor.ResourceGroupName
$rules = @()
foreach($listener in $appGateway.HttpListeners)
{    
    $appGwRoutingRule = $appGateway.RequestRoutingRules | ?{$_.HttpListener.Id.Split("/")[-1] -eq $listener.Name}
    $redirectRule = $appGateway.RedirectConfigurations | ?{$_.Id -eq $appGwRoutingRule.RedirectConfiguration.Id}
    $listenerHostNames = $listener.HostName
    $listenerHostNames += $listener.HostNames
    $customDomains = @()
    foreach($hostName in $listenerHostNames)
    {
        $rules += New-Object -TypeName psobject -Property @{
            hostname = $hostName
            redirectTarget = $redirectRule.TargetUrl
        }
        $customDomains += Get-AzFrontDoorCdnCustomDomain -CustomDomainName $hostName.Split(".")[0] -ProfileName $frontDoor.Name -ResourceGroupName $frontDoor.ResourceGroupName
    }
    New-AzFrontDoorCdnRoute -EndpointName $endpoint.Name -Name $listener.Name -ProfileName $frontDoor.Name -ResourceGroupName $frontDoor.ResourceGroupName -RuleSet $ruleSet -ForwardingProtocol 'MatchRequest' -HttpsRedirect 'Disabled' -CustomDomain $customDomains -OriginGroupId $origionGroup.Id
}
$count = 1
foreach($rule in $rules)
{
    $name = $("Rule" + $count)
    $condition = New-AzFrontDoorCdnRuleHostNameConditionObject -Name 'HostName' -ParameterMatchValue $rule.hostname -ParameterOperator 'Equal'
    $action = New-AzFrontDoorCdnRuleUrlRedirectActionObject -Name 'UrlRedirect' -ParameterRedirectType 'PermanentRedirect' -ParameterDestinationProtocol 'MatchRequest' -ParameterCustomHostname $rule.redirectTarget.Split("://")[1]
    New-AzFrontDoorCdnRule -Name $name -ProfileName $frontDoor.Name -ResourceGroupName $frontDoor.ResourceGroupName -SetName $ruleSet.Name -Action $action -Condition $condition -Order $count
    $count++;
}