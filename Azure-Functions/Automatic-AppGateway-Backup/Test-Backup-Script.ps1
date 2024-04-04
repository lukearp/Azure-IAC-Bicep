$appGatewayName = "ingress-aks"
$appGatewayResourceGroup = "temp-appgw"

$rootTemplate = @'
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "appGateway_name": {
            "type": "string",
            "defaultVaule": ""
        },
        "appGateway_subnet": {
            "type": "string",
            "defaultVaule": ""
        },
        "vnetResourceId": {
            "type": "string",
            "defaultVaule": ""
        }
    },
    "resources": [
        {
            "type": "Microsoft.Network/publicIPAddresses",
            "apiVersion": "2023-09-01",
            "name": "[format('{0}-pip', parameters('appGateway_name'))]",
            "location": "[parameters('location')]",
            "sku": {
                "name": "Standard",
                "tier": "Regional"
            },
            "zones": [],
            "properties": {
                "publicIPAddressVersion": "IPv4",
                "publicIPAllocationMethod": "Static"
            }
        }
    ]
}
'@

$frontendIpResourceString = @'
[{{
    "name": "{0}",
    "properties": {{
        "privateIPAllocationMethod": "Dynamic",
        "publicIPAddress": {{
            "id": "[resourceId('Microsoft.Network/publicIPAddresses',format('{0}-pip', parameters('appGateway_name')))]"
        }}
    }}
}},
{{
    "name": "{1}",
    "properties": {{
        "privateIPAllocationMethod": "Static",
        "privateIPAddress": "{2}", 
        "subnet": {{
            "id": "[concat(parameters('vnetResourceId'), '/subnets/', parameters('appGateway_subnet'))]"
        }}
    }}
}}]
'@

$fronendPortResourceString = @'
{{
    "name": "{0}",
    "properties": {{
        "port": {1}
    }}
}}
'@
<#
HostName = null
SslCertificate = null
SslProfile = null
#>
$listnerResourceFirewallPolicyString = @'
{{
    "FrontendIpConfiguration": {{
      "Id": "[concat(resourceId('Microsoft.Network/applicationGateways',parameters('appGateway_name')),'/frontendIPConfigurations/{1}')]"
    }},
    "FrontendPort": {{
      "Id": "[concat(resourceId('Microsoft.Network/applicationGateways',parameters('appGateway_name')),'/frontendPorts/{2}')]"
    }},
    "Protocol": "{3}",
    "HostName": {4},
    "HostNames": [],
    "SslCertificate": {5},
    "RequireServerNameIndication": {6},
    "Type": "Microsoft.Network/applicationGateways/httpListeners",
    "CustomErrorConfigurations": [],
    "FirewallPolicy": {{
      "Id": "[resourceId('Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies', parameters('{0}'))]"
    }},
    "SslProfile": {7},
    "Name": "{8}"
}}
'@

$listnerResourceString = @'
{{
    "FrontendIpConfiguration": {{
      "Id": "[concat(resourceId('Microsoft.Network/applicationGateways',parameters('appGateway_name')),'/frontendIPConfigurations/{0}')]"
    }},
    "FrontendPort": {{
      "Id": "[concat(resourceId('Microsoft.Network/applicationGateways',parameters('appGateway_name')),'/frontendPorts/{1}')]"
    }},
    "Protocol": "{2}",
    "HostName": {3},
    "HostNames": [],
    "SslCertificate": {4},
    "RequireServerNameIndication": {5},
    "Type": "Microsoft.Network/applicationGateways/httpListeners",
    "CustomErrorConfigurations": [],    
    "SslProfile": {6},
    "Name": "{7}"
}}
'@

$backendHttpSettingResourceString = @'
{{
    "Port": {1},
    "Protocol": "{2}",
    "CookieBasedAffinity": "{3}",
    "RequestTimeout": {4},
    "ConnectionDraining": {5},
    "AuthenticationCertificates": [],
    "TrustedRootCertificates": [],
    "HostName": {6},
    "PickHostNameFromBackendAddress": {7},
    "AffinityCookieName": "{8}",
    "Path": {9},
    "Type": "Microsoft.Network/applicationGateways/backendHttpSettingsCollection",
    "Name": "{0}"
}}
'@

$backendHttpSettingCustomProbeResourceString = @'
{{
    "Port": {2},
    "Protocol": "{3}",
    "CookieBasedAffinity": "{4}",
    "RequestTimeout": {5},
    "ConnectionDraining": {6},
    "Probe": {{
      "Id": "{0}"
    }},
    "AuthenticationCertificates": [],
    "TrustedRootCertificates": [],
    "HostName": {7},
    "PickHostNameFromBackendAddress": {8},
    "AffinityCookieName": "{9}",
    "Path": {10},
    "Type": "Microsoft.Network/applicationGateways/backendHttpSettingsCollection",
    "Name": "{1}"
}}
'@

$backendAddressPoolResourceString = @'
{{
    "name": "{0}",
    "properties": {{
        "backendAddresses": []
    }}
}}
'@

$gatewayIpResourceString = @'
{{
    "name": "{0}",
    "properties": {{
        "subnet": {{
            "id": "[concat(parameters('vnetResourceId'), '/subnets/', parameters('appGateway_subnet'))]"
        }}
    }}
}}
'@

$sslCertificatesResourceString = @'
{{
    "name": "{0}",
    "properties": {{
        "keyVaultSecretId": "{1}"
    }}
}}
'@

$trustedRootResourceString = @'
{{
    "Data": "{1}",
    "Type": "Microsoft.Network/applicationGateways/trustedRootCertificates",
    "Name": "{0}",
}}
'@

$appGwResourceString = @'
{{
    "type": "Microsoft.Network/applicationGateways",
    "apiVersion": "2023-06-01",
    "name": "[parameters('appGateway_name')]",
    "dependsOn": [
        "[resourceId('Microsoft.Network/publicIPAddresses', format('{{0}}-pip', parameters('appGateway_name')))]"
    ],
    "location": "[parameters('location')]",
    "identity": {0},
    "properties": {{
        "sku": {1},
        "gatewayIPConfigurations": [],
        "sslCertificates": [],
        "trustedRootCertificates": [],
        "trustedClientCertificates": [],
        "sslProfiles": [],
        "frontendIPConfigurations": [],
        "frontendPorts": [],
        "backendAddressPools": [],
        "loadDistributionPolicies": [],
        "backendHttpSettingsCollection": [],
        "backendSettingsCollection": [],
        "httpListeners": [],
        "listeners": [],
        "urlPathMaps": [],
        "requestRoutingRules": [],
        "routingRules": [],
        "probes": [],
        "rewriteRuleSets": [],
        "redirectConfigurations": [],
        "privateLinkConfigurations": [],
        "sslPolicy": {{}},
        "enableHttp2": true,
        "autoscaleConfiguration": {{}},
        "firewallPolicy": {{
            "id": "[resourceId('Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies',parameters('{2}'))]"
        }}
    }}
}}
'@

$wafResourceString = @'
{{
    "type": "Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies",
    "apiVersion": "2023-09-01",
    "name": "[parameters('{0}')]",
    "location": "[parameters('location')]",
    "tags": {1},
    "properties": {2}
}}
'@

$appGateway = Get-AzApplicationGateway -Name $appGatewayName -ResourceGroupName $appGatewayResourceGroup
#Listeners $appGateway.httpListeners.FirewallPolicy.id
#URLPathMaps $appGateway.UrlPathMaps.PathRules.FirewallPolicy.id
#FirewallPolicy $appGateway.FirewallPolicy.id
$wafPolicies = @()
$wafPolicies += $appGateway.httpListeners.FirewallPolicy.id
$wafPolicies += $appGateway.UrlPathMaps.PathRules.FirewallPolicy.id
$wafPolicies += $appGateway.FirewallPolicy.id
$wafPolicies = $wafPolicies | Select -Unique
$count = 0
$locationParameter = New-Object -TypeName psobject -Property @{
    type = "string"
}
#$wafResources = @()
$template = ConvertFrom-Json -InputObject $rootTemplate -Depth 10
$template.parameters | Add-Member -Name "location" -MemberType NoteProperty -Value $locationParameter
foreach($policy in $wafPolicies)
{
    $wafPolicy = $null
    $wafPolicy = Get-AzApplicationGatewayFirewallPolicy -Name $policy.split("/")[8] -ResourceGroupName $policy.split("/")[4]
    $policyProperties = New-Object -typename psobject -Property @{
        CustomRules = $wafPolicy.CustomRules
        PolicySettings = $wafPolicy.PolicySettings
        ManagedRules = $wafPolicy.ManagedRules        
    }
    $template.resources += ConvertFrom-Json -InputObject $($wafResourceString -f $($wafPolicy.Name + "-" + $count),$(ConvertTo-Json -InputObject $wafPolicy.Tag -Depth 10),$(ConvertTo-Json -InputObject $policyProperties -Depth 10)) -Depth 10
    $paramVaule = New-Object -TypeName psobject -Property @{
        type = "string"
        defaultValue = $wafPolicy.Name
    }
    $template.parameters | Add-Member -Name $wafPolicy.Name <#$($wafPolicy.Name + "-" + $count).ToString()#> -Value $paramVaule -MemberType NoteProperty
    #$count++
}
$newAppGw = ConvertFrom-Json -InputObject $($appGwResourceString -f $(ConvertTo-Json -InputObject $appGateway.Identity -Depth 10),$(ConvertTo-Json -InputObject $appGateway.Sku -Depth 10),$($wafPolicies[0].split("/")[8] + "-0"))
foreach($gatewayIpConfig in $appGateway.GatewayIPConfigurations)
{
    $newAppGw.properties.gatewayIPConfigurations += ConvertFrom-Json -InputObject $($gatewayIpResourceString -f $gatewayIpConfig.Name) -Depth 10
}
foreach($sslCertificate in $appGateway.SslCertificates)
{
    $newAppGw.properties.sslCertificates += ConvertFrom-Json -InputObject $($sslCertificatesResourceString -f $sslCertificate.Name, $sslCertificate.KeyVaultSecretId) -Depth 10
}
foreach($rootCert in $appGateway.TrustedRootCertificates)
{
    $newAppGw.properties.trustedRootCertificates += ConvertFrom-Json -InputObject $($trustedRootResourceString -f $rootCert.Name,$rootCert.Data)
}
$secondary = ""
if($appGateway.FrontendIPConfigurations.Count -eq 1)
{
     $secondary = "Private"   
}
else {
    $secondary = $appGateway.FrontendIPConfigurations[1].Name
}
$firstIpOfSubnet = "[format('{0}.{1}.{2}.{3}', split(split(reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, split(parameters('vnetResourceId'), '/')[4]), 'Microsoft.Network/virtualNetworks/subnets', split(parameters('vnetResourceId'), '/')[8], parameters('appGateway_subnet')), '2023-09-01').addressPrefix, '/')[0], '.')[0], split(split(reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, split(parameters('vnetResourceId'), '/')[4]), 'Microsoft.Network/virtualNetworks/subnets', split(parameters('vnetResourceId'), '/')[8], parameters('appGateway_subnet')), '2023-09-01').addressPrefix, '/')[0], '.')[1], split(split(reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, split(parameters('vnetResourceId'), '/')[4]), 'Microsoft.Network/virtualNetworks/subnets', split(parameters('vnetResourceId'), '/')[8], parameters('appGateway_subnet')), '2023-09-01').addressPrefix, '/')[0], '.')[2], string(add(int(split(split(reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, split(parameters('vnetResourceId'), '/')[4]), 'Microsoft.Network/virtualNetworks/subnets', split(parameters('vnetResourceId'), '/')[8], parameters('appGateway_subnet')), '2023-09-01').addressPrefix, '/')[0], '.')[3]), 4)))]"
$newAppGw.properties.frontendIPConfigurations += ConvertFrom-Json -InputObject $($frontendIpResourceString -f $appGateway.FrontendIPConfigurations[0].Name,$secondary,$firstIpOfSubnet)
foreach($frontEndPort in $appGateway.FrontendPorts)
{
    $newAppGw.properties.frontendPorts += ConvertFrom-Json -InputObject $($fronendPortResourceString -f $frontEndPort.Name,$frontEndPort.Port) -Depth 10
}
foreach($backendPool in $appGateway.BackendAddressPools)
{
    $backend = ConvertFrom-Json -InputObject $($backendAddressPoolResourceString -f $backendPool.Name) -Depth 10
    $backend.properties.backendAddresses += $backendPool.BackendAddresses
    $newAppGw.properties.backendAddressPools += $backend
}
foreach($httpSetting in $appGateway.BackendHttpSettingsCollection)
{
    if($null -ne $httpSetting.Probe)
    {
        $backendSetting = ConvertFrom-Json -InputObject $($backendHttpSettingCustomProbeResourceString -f "[concat(resourceId('Microsoft.Netowrk/applicationGateways',parameters('appGateway_name')),'/probes/$($httpSetting.Probe.Id.Split("/")[10])')]",$httpSetting.Name,$httpSetting.Port.ToString(),$httpSetting.Protocol,$httpSetting.CookieBasedAffinity,$httpSetting.RequestTimeout.ToString(),$($httpSetting.ConnectionDraining -eq $null ? "null" : "`"$($httpSetting.ConnectionDraining)`""),$($httpSetting.HostName -eq $null ? "null" : "`"$($httpSetting.HostName)`""),$httpSetting.PickHostNameFromBackendAddress.ToString().ToLower(),$httpSetting.AffinityCookieName,$($httpSetting.Path -eq $null ? "null" : "`"$($httpSetting.Path)`"")) -Depth 10
        foreach($rootCert in $httpSetting.TrustedRootCertificates)
        {
            $backendSetting.TrustedRootCertificates += New-Object -TypeName psobject -Property @{
                Id = "[concat(resourceId('Microsoft.Netowrk/applicationGateways',parameters('appGateway_name')),'/trustedRootCertificates/$($rootCert.Id.Split("/")[10])')]"
            }
        }        
        $newAppGw.properties.backendHttpSettingsCollection += $backendSetting
    }
    else {
        $backendSetting = ConvertFrom-Json -InputObject $($backendHttpSettingResourceString -f $httpSetting.Name,$httpSetting.Port.ToString(),$httpSetting.Protocol,$httpSetting.CookieBasedAffinity,$httpSetting.RequestTimeout.ToString(),$($httpSetting.ConnectionDraining -eq $null ? "null" : "`"$($httpSetting.ConnectionDraining)`""),$($httpSetting.HostName -eq $null ? "null" : "`"$($httpSetting.HostName)`""),$httpSetting.PickHostNameFromBackendAddress.ToString().ToLower(),$httpSetting.AffinityCookieName,$($httpSetting.Path -eq $null ? "null" : "`"$($httpSetting.Path)`"")) -Depth 10
        foreach($rootCert in $httpSetting.TrustedRootCertificates)
        {
            $backendSetting.TrustedRootCertificates += New-Object -TypeName psobject -Property @{
                Id = "[concat(resourceId('Microsoft.Netowrk/applicationGateways',parameters('appGateway_name')),'/trustedRootCertificates/$($rootCert.Id.Split("/")[10])')]"
            }
        }
        $newAppGw.properties.backendHttpSettingsCollection += $backendSetting
    }
}
foreach($listener in $appGateway.HttpListeners)
{
    if($null -ne $listener.FirewallPolicy)
    {
        $wafName = ($template.parameters | Get-Member | ?{$_.Name -eq "$($listener.FirewallPolicy.Id.Split(`"/`")[8])"}).Name 
        $listenerSetting = ConvertFrom-Json -InputObject $($listnerResourceFirewallPolicyString -f $wafName,$listener.FrontendIpConfiguration.Id.Split("/")[10],$listener.FrontendPort.Id.Split("/")[10],$listener.Protocol,$($listener.HostName -eq $null ? "null" : "`"$($listener.HostName)`""),$($listener.SslCertificate -eq $null ? "null" : "`"[concat(resourceId('Microsoft.Network/applicationGateways',parameters('appGateway_name)),'/sslCertificates/$($listener.SslCertificate.Id.Split("/")[10])')]`""),$listener.RequireServerNameIndication.ToString().ToLower(),$($listener.SslProfile -eq $null ? "null" : "`"[concat(resourceId('Microsoft.Network/applicationGateways',parameters('appGateway_name)),'/sslCertificates/$($listener.SslProfile.Id.Split("/")[10])')]`""),$listener.Name )
        $listenerSetting.HostNames += $listener.HostNames
        $newAppGw.properties.httpListeners += $listenerSetting
    }
    else 
    {
        $listenerSetting = ConvertFrom-Json -InputObject $($listnerResourceString -f $listener.FrontendIpConfiguration.Id.Split("/")[10],$listener.FrontendPort.Id.Split("/")[10],$listener.Protocol,$($listener.HostName -eq $null ? "null" : "`"$($listener.HostName)`""),$($listener.SslCertificate -eq $null ? "null" : "`"[concat(resourceId('Microsoft.Network/applicationGateways',parameters('appGateway_name)),'/sslCertificates/$($listener.SslCertificate.Id.Split("/")[10])')]`""),$listener.RequireServerNameIndication.ToString().ToLower(),$($listener.SslProfile -eq $null ? "null" : "`"[concat(resourceId('Microsoft.Network/applicationGateways',parameters('appGateway_name)),'/sslCertificates/$($listener.SslProfile.Id.Split("/")[10])')]`""),$listener.Name )
        $listenerSetting.HostNames += $listener.HostNames
        $newAppGw.properties.httpListeners += $listenerSetting
    }
}
$template.resources += $appGwResourceString