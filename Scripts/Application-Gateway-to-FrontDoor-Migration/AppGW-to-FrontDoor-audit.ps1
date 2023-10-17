param (
    [string]$appGatewayName,
    [string]$appGatewayRg,
    [string]$csvPath
)
<#
    TODO: Account for Path Based Redirect Rules:
    UrlPathMaps.DefaultRedirectConfiguration for default redirect rule
    $appGateway.UrlPathMaps.PathRules.DefaultRedirectConfiguration.Id
    $appGateway.UrlPathMaps.PathRules.Paths    
    $appGateway.UrlPathMaps.PathRules.RedirectConfiguration.Id
#>
$appGateway = Get-AzApplicationGateway -Name $appGatewayName -ResourceGroupName $appGatewayRg
$hostNames = $appGateway.HttpListeners.HostNames
$hostNames += $appGateway.HttpListeners.HostName
$hostNames = $hostNames | Select -Unique
Add-Content -Path $csvPath -Value "AppGateway,Listner,HostName,RedirectTarget"
foreach ($listener in $appGateway.HttpListeners) {   
    $listenerHostNames = @() 
    $appGwRoutingRule = $appGateway.RequestRoutingRules | ? { $_.HttpListener.Id.Split("/")[-1] -eq $listener.Name }
    $redirectRule = $null
    $redirectRule = $appGateway.RedirectConfigurations | ? { $_.Id -eq $appGwRoutingRule.RedirectConfiguration.Id }    
    if($listener.HostName -ne $null)
    {
        if ($listener.HostName[0] -eq "*" -and $listener.HostName[1] -ne ".") {
            $listenerHostNames += $($listener.HostName.split("*")[1])
            $listenerHostNames += $($listener.HostName.replace("*", "www."))
        }
        else {
            $listenerHostNames += $($listener.HostName)
        }
    }    
    foreach ($name in $listener.HostNames) {
        if ($name[0] -eq "*" -and $name[1] -ne ".") {
            $listenerHostNames += $($name.split("*")[1])
            $listenerHostNames += $($name.replace("*", "www."))
        }
        else {
            $listenerHostNames += $($name)
        }
    }
    foreach ($hostName in $listenerHostNames) {
        if ($redirectRule -eq $null) {
            $urlMap = $appGateway.UrlPathMaps | ? { $_.Id -eq $appGwRoutingRule.UrlPathMap.Id }            
            $defaultRedirect = $appGateway.RedirectConfigurations | ? { $_.Id -eq $urlMap.DefaultRedirectConfiguration.Id }
            Add-Content -Path $csvPath -Value "$($appGateway.Name),$($listener.Name),$($hostName),$($defaultRedirect.TargetUrl)"
            foreach ($rule in $urlMap.PathRules) {
                foreach($path in $rule.Paths)
                {
                    Add-Content -Path $csvPath -Value "$($appGateway.Name),$($listener.Name),$($hostName + $path),$(($appGateway.RedirectConfigurations | ? { $_.Id -eq $rule.RedirectConfiguration.Id }).TargetUrl)"
                }
            }
        }
        else { 
            Add-Content -Path $csvPath -Value "$($appGateway.Name),$($listener.Name),$($hostName),$($redirectRule.TargetUrl)"
        }
    }
}