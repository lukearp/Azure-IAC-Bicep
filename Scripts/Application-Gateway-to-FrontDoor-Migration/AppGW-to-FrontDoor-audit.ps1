param (
    [string]$appGatewayName,
    [string]$appGatewayRg,
    [string]$csvPath
)

$appGateway = Get-AzApplicationGateway -Name $appGatewayName -ResourceGroupName $appGatewayRg
$hostNames = $appGateway.HttpListeners.HostNames
$hostNames += $appGateway.HttpListeners.HostName
$hostNames = $hostNames | Select -Unique
Add-Content -Path $csvPath -Value "AppGateway,Listner,HostName,RedirectTarget"
$rules = @()
foreach ($listener in $appGateway.HttpListeners) {    
    $appGwRoutingRule = $appGateway.RequestRoutingRules | ? { $_.HttpListener.Id.Split("/")[-1] -eq $listener.Name }
    $redirectRule = $appGateway.RedirectConfigurations | ? { $_.Id -eq $appGwRoutingRule.RedirectConfiguration.Id }
    $listenerHostNames = $listener.HostName
    $listenerHostNames += $listener.HostNames
    $customDomains = @()
    foreach ($hostName in $listenerHostNames) {
        Add-Content -Path $csvPath -Value "$($appGateway.Name),$($listener.Name),$($hostName),$($redirectRule.TargetUrl)"
    }
}