param($eventGridEvent,$TriggerMetadata)

$testing = $env:Testing #$true for True $false for False
$testAppGatewayId = $env:TestAppGatewayId # Resource ID of test firewall policy
$templateResourceGroup = $env:TemplateResourceGroup
$templateResourceSubscription = $env:TemplateResourceSubscription
$drRegion = $env:DrRegion
$testRun = $false
if($testing -eq "TRUE")
{
    $testRun = $true
}

if($testRun -eq $false) {
    $user = $eventGridEvent.data.claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn']
    $appGatewayId = $eventGridEvent.data.resourceUri.split("/")[0..8] -join "/"
} else {
    $user = "testuser@test.com"
    $appGatewayId = $testAppGatewayId
}

$appGatewayName = $appGatewayId.split("/")[8]
$appGatewayResourceGroup = $appGatewayId.split("/")[4]
$appGatewaySubscription = $appGatewayId.split("/")[2]

$rootTemplate = @'
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "appGateway_name": {
            "type": "string",
            "defaultValue": ""
        },
        "appGateway_subnet": {
            "type": "string",
            "defaultValue": ""
        },
        "vnetResourceId": {
            "type": "string",
            "defaultValue": ""
        }
    },
    "variables": {},
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
    ],
    "outputs": {
        "publicIp": {
            "type": "string",
            "value": "[reference(resourceId('Microsoft.Network/publicIPAddresses', format('{0}-pip', parameters('appGateway_name')))).ipAddress]"
        }
    }
}
'@

$frontendIpResourceString = @'
[{{
    "name": "{0}",
    "properties": {{
        "privateIPAllocationMethod": "Dynamic",
        "publicIPAddress": {{
            "id": "[resourceId('Microsoft.Network/publicIPAddresses',concat(parameters('appGateway_name'),'-pip'))]"
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
    "properties": {{
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
    "CustomErrorConfigurations": [],
    "FirewallPolicy": {{
      "Id": "[resourceId('Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies', parameters('{0}'))]"
    }},
    "SslProfile": {7}
}},
    "Name": "{8}"
}}
'@

$firewallPolicyResourceString = @'
{{
    "Id": "[resourceId('Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies', parameters('{0}'))]"
}}
'@

$listnerResourceString = @'
{{
    "properties": {{
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
    "CustomErrorConfigurations": [],    
    "SslProfile": {6}
}},
    "Name": "{7}"
}}
'@

$backendHttpSettingResourceString = @'
{{
    "properties":{{
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
    "Path": {9}
}},
    "Name": "{0}"
}}
'@

$backendHttpSettingCustomProbeResourceString = @'
{{
    "properties": {{
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
    "Path": {10}
}},
    "Name": "{1}"
}}
'@

$backendAddressPoolResourceString = @'
{{
    "name": "{0}",
    "properties": {{
        "backendAddresses": [],
        "backendIpConfigurations": []
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
    "properties": {{
    "Data": "{1}"
}},
    "Name": "{0}",
}}
'@

<#
DefaultRewriteRuleSet = null
DefaultRedirectConfiguration = null
#>
$urlPathMapResourceString = @'
{{
    "properties": {{
    "DefaultBackendAddressPool": {{
        "Id": "[concat(resourceId('Microsoft.Network/applicationGateways',parameters('appGateway_name')),'/backendAddressPools/{1}')]"
    }},
    "DefaultBackendHttpSettings": {{
        "Id": "[concat(resourceId('Microsoft.Network/applicationGateways',parameters('appGateway_name')),'/backendHttpSettingsCollection/{2}')]"
    }},
    "DefaultRewriteRuleSet": {3},
    "DefaultRedirectConfiguration": {4},
    "PathRules": []
}},
    "Name": "{0}",
}}
'@

$routingRuleBackendHttpSettingsResourceString = @'
{{
    "Id": "[concat(resourceId('Microsoft.Network/applicationGateways',parameters('appGateway_name')),'/backendHttpSettingsCollection/{0}')]"
}}
'@

$pathRulesResourceString = @'
{{
    "properties": {{
    "Paths": [],
    "BackendAddressPool": {1},
    "BackendHttpSettings": {2},
    "RewriteRuleSet": {3},
    "RedirectConfiguration": {4},
    "FirewallPolicy": {5}
}},
    "Name": "{0}",
}}
'@

$pathRedirectRuleResourceString = @'
{{
    "Id": "[concat(resourceId('Microsoft.Network/applicationGateways',parameters('appGateway_name')),'/redirectConfigurations/{0}')]"
}}
'@

$routingRuleBackendResourceString = @'
{{
    "Id": "[concat(resourceId('Microsoft.Network/applicationGateways',parameters('appGateway_name')),'/backendAddressPools/{0}')]"
}}
'@

$routingRuleHttpSettingResourceString = @'
{{
    "Id": "[concat(resourceId('Microsoft.Network/applicationGateways',parameters('appGateway_name')),'/backendHttpSettingsCollection/{0}')]"
}}
'@

$routingRewriteRuleIdResourceString = @'
{{
    "id": "[concat(resourceId('Microsoft.Network/applicationGateways',parameters('appGateway_name')),'/rewriteRuleSets/{0}')]"
}}
'@

$routingUrlPathIdResourceString = @'
{{
    "id": "[concat(resourceId('Microsoft.Network/applicationGateways',parameters('appGateway_name')),'/urlPathMaps/{0}')]"
}}
'@

$routingUrlPathRulesIdResourceString = @'
{{
    "id": "[concat(resourceId('Microsoft.Network/applicationGateways',parameters('appGateway_name')),'/urlPathMaps/{0}/pathRules/{1}')]"
}}
'@

$routingRuleIdResoruceString = @'
{{
    "id": "[concat(resourceId('Microsoft.Network/applicationGateways',parameters('appGateway_name')),'/requestRoutingRules/{0}')]"
}}
'@

$routingRuleResourceString = @'
{{
    "properties": {{
    "RuleType": "{1}",
    "Priority": {2},
    "BackendAddressPool": {3},
    "BackendHttpSettings": {4},
    "HttpListener": {{
        "Id": "[concat(resourceId('Microsoft.Network/applicationGateways',parameters('appGateway_name')),'/httpListeners/{5}')]"
    }},
    "UrlPathMap": {6},
    "RewriteRuleSet": {7},
    "RedirectConfiguration": {8}
}},
    "Name": "{0}"
}}
'@
#Conditions,RequestHeaderConfigurations,ResponseHeaderConfigurations = Array UrlConfiguration = null
$rewriteRuleResourceString = @'
{{
    "Name": "{0}",
    "RuleSequence": {1},
    "Conditions": {2},
    "ActionSet": {3}
}}
'@

$rewriteRuleSetResourceString = @'
{{
    "properties": {{
    "RewriteRules": []
    }},
    "Name": "{0}",
}}
'@
#Port = null
$probeResourceString = @'
{{
    "properties": {{
    "Protocol": "{1}",
    "Host": {2},
    "Path": "{3}",
    "Interval": {4},
    "Timeout": {5},
    "UnhealthyThreshold": {6},
    "PickHostNameFromBackendHttpSettings": {7},
    "MinServers": {8},
    "Port": {9},
    "Match": {10}
}},
    "Name": "{0}",
}}
'@

$trustedClientCertResourceString = @'
{{
    "properties":{{
    "Data": "{1}",
    "ClientCertIssuerDN": "{2}"
}},
    "Name": "{0}",
}}
'@

$sslProfileTrustedCertificateResourceString = @'
{{
    "Id": "[concat(resourceId('Microsoft.Network/applicationGateways',parameters('appGateway_name')),'/trustedClientCertificates/{0}')]"
}}
'@
#SslPolicy = nul
$sslProfileResourceString = @'
{{
    "properties": {{
    "SslPolicy": {1},
    "ClientAuthConfiguration": {2},
    "TrustedClientCertificates": []
}},
    "Name": "{0}",
}}
'@

$redirectTargetListenerResourceString = @'
{{
    "Id": "[concat(resourceId('Microsoft.Network/applicationGateways',parameters('appGateway_name')),'/httpListeners/{0}')]"
}}
'@

$redirectRuleResourceString = @'
{{
    "properties": {{
    "RedirectType": "{1}",
    "TargetListener": {2},
    "TargetUrl": {3},
    "IncludePath": {4},
    "IncludeQueryString": {5},
    "RequestRoutingRules": [],
    "UrlPathMaps": [],
    "PathRules": []
    }},
    "Name": "{0}"
}}
'@

$appGatewayIdentityResourceString = @'
{{
    "Type": "UserAssigned",
    "UserAssignedIdentities": {{
      "{0}": {{}}
    }}
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

$appGwResourceNoIdentityString = @'
{{
    "type": "Microsoft.Network/applicationGateways",
    "apiVersion": "2023-06-01",
    "name": "[parameters('appGateway_name')]",
    "dependsOn": [
        "[resourceId('Microsoft.Network/publicIPAddresses', format('{{0}}-pip', parameters('appGateway_name')))]"
    ],
    "location": "[parameters('location')]",
    "identity": {{}},
    "properties": {{
        "sku": {0},
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
            "id": "[resourceId('Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies',parameters('{1}'))]"
        }}
    }}
}}
'@

$appGwResourceNoPolicyString = @'
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
        "autoscaleConfiguration": {{}}
    }}
}}
'@
#,"webApplicationFirewallConfiguration": {{}},        "autoscaleConfiguration": {{}}

$appGwResourceNoPolicyNoIdenityString = @'
{{
    "type": "Microsoft.Network/applicationGateways",
    "apiVersion": "2023-06-01",
    "name": "[parameters('appGateway_name')]",
    "dependsOn": [
        "[resourceId('Microsoft.Network/publicIPAddresses', format('{{0}}-pip', parameters('appGateway_name')))]"
    ],
    "location": "[parameters('location')]",
    "identity": {{}},
    "properties": {{
        "sku": {0},
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
        "autoscaleConfiguration": {{}}
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

Select-AzSubscription -Subscription $appGatewaySubscription
$appGateway = Get-AzApplicationGateway -Name $appGatewayName -ResourceGroupName $appGatewayResourceGroup
#Listeners $appGateway.httpListeners.FirewallPolicy.id
#URLPathMaps $appGateway.UrlPathMaps.PathRules.FirewallPolicy.id
#FirewallPolicy $appGateway.FirewallPolicy.id
$wafPolicies = @()
$walPoliciesAll = @()
$walPoliciesAll += $appGateway.FirewallPolicy.id
$walPoliciesAll += $appGateway.httpListeners.FirewallPolicy.id
$walPoliciesAll += $appGateway.UrlPathMaps.PathRules.FirewallPolicy.id
$wafPolicies += $walPoliciesAll | Select -Unique

$locationParameter = New-Object -TypeName psobject -Property @{
    type = "string"
}
#$wafResources = @()
$template = ConvertFrom-Json -InputObject $rootTemplate -Depth 20
$template.parameters | Add-Member -Name "location" -MemberType NoteProperty -Value $locationParameter
$userIdentity = ""
foreach ($key in $appGateway.Identity.UserAssignedIdentities.Keys) { $userIdentity = $key }
if($null -eq $appGateway.FirewallPolicy.id -and $null -ne $appGateway.Identity) {
    Write-Output "No Firewall Policy and has Identity"
    $newAppGw = ConvertFrom-Json -InputObject $($appGwResourceNoPolicyString -f $($appGatewayIdentityResourceString -f $userIdentity),$(ConvertTo-Json -InputObject $appGateway.Sku -Depth 20))
}
elseif($null -ne $appGateway.Identity) {
    Write-Output "Firewall Policy and has Identity"
    $newAppGw = ConvertFrom-Json -InputObject $($appGwResourceString -f $($appGatewayIdentityResourceString -f $userIdentity),$(ConvertTo-Json -InputObject $appGateway.Sku -Depth 20),$($wafPolicies[0].split("/")[8]))
}
elseif($null -eq $appGateway.FirewallPolicy.id)
{
    Write-Output "No Firewall Policy and No Identity"
    $newAppGw = ConvertFrom-Json -InputObject $($appGwResourceNoPolicyNoIdenityString -f $(ConvertTo-Json -InputObject $appGateway.Sku -Depth 20)) 
}
else 
{
    Write-Output "Firewall Policy and No Identity"
    $newAppGw = ConvertFrom-Json -InputObject $($appGwResourceNoIdentityString -f $(ConvertTo-Json -InputObject $appGateway.Sku -Depth 20),$($wafPolicies[0].split("/")[8]))
}
foreach($policy in $wafPolicies)
{
    $wafPolicy = $null
    $wafPolicy = Get-AzApplicationGatewayFirewallPolicy -Name $policy.split("/")[8] -ResourceGroupName $policy.split("/")[4]
    $customRules = @()
    foreach($customRule in $wafPolicy.CustomRules)
    {
        $matchConditions = @()
        foreach($matchCondition in $customRule.MatchConditions)
        {
            $condition = $matchCondition | Select MatchVariables,NegationConditon,MatchValues,Transforms
            $condition | Add-Member -MemberType NoteProperty -Name Operator -Value $matchCondition.OperatorProperty
            $matchConditions += $condition
        }

        $customRules += New-Object -TypeName psobject -Property @{
            Name = $customRule.Name
            Priority = $customRule.Priority
            RateLimitDuration = $customRule.RateLimitDuration
            RuleType = $customRule.RuleType
            MatchConditions = $matchConditions
            GroupByUserSession = $customRule.GroupByUserSession
            Action = $customRule.Action
            State = $customRule.State
        }
    }

    $policyProperties = New-Object -typename psobject -Property @{
        CustomRules = $customRules
        PolicySettings = $wafPolicy.PolicySettings
        ManagedRules = $wafPolicy.ManagedRules        
    }
    $template.resources += ConvertFrom-Json -InputObject $($wafResourceString -f $($wafPolicy.Name),$(ConvertTo-Json -InputObject $wafPolicy.Tag -Depth 20),$(ConvertTo-Json -InputObject $policyProperties -Depth 20)) -Depth 20
    $paramVaule = New-Object -TypeName psobject -Property @{
        type = "string"
        defaultValue = $wafPolicy.Name
    }
    $template.parameters | Add-Member -Name $wafPolicy.Name <#$($wafPolicy.Name + "-" + $count).ToString()#> -Value $paramVaule -MemberType NoteProperty
    $newAppGw.dependsOn += "[resourceId('Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies',parameters('$($wafPolicy.Name)'))]"
    #$count++
}
if($null -ne $appGateway.AutoscaleConfiguration)
{
    $newAppGw.properties.autoscaleConfiguration = $appGateway.AutoscaleConfiguration
}
foreach($gatewayIpConfig in $appGateway.GatewayIPConfigurations)
{
    $newAppGw.properties.gatewayIPConfigurations += ConvertFrom-Json -InputObject $($gatewayIpResourceString -f $gatewayIpConfig.Name) -Depth 20
}
foreach($sslCertificate in $appGateway.SslCertificates)
{
    $newAppGw.properties.sslCertificates += ConvertFrom-Json -InputObject $($sslCertificatesResourceString -f $sslCertificate.Name, $sslCertificate.KeyVaultSecretId) -Depth 20
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
$firstIpOfSubnet = "[format('{0}.{1}.{2}.{3}', split(split(if(contains(reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, split(parameters('vnetResourceId'), '/')[4]), 'Microsoft.Network/virtualNetworks/subnets', split(parameters('vnetResourceId'), '/')[8], parameters('appGateway_subnet')), '2023-09-01'), 'addressPrefix'), tryGet(reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, split(parameters('vnetResourceId'), '/')[4]), 'Microsoft.Network/virtualNetworks/subnets', split(parameters('vnetResourceId'), '/')[8], parameters('appGateway_subnet')), '2023-09-01'), 'addressPrefix'), reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, split(parameters('vnetResourceId'), '/')[4]), 'Microsoft.Network/virtualNetworks/subnets', split(parameters('vnetResourceId'), '/')[8], parameters('appGateway_subnet')), '2023-09-01').addressPrefixes[0]), '/')[0], '.')[0], split(split(if(contains(reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, split(parameters('vnetResourceId'), '/')[4]), 'Microsoft.Network/virtualNetworks/subnets', split(parameters('vnetResourceId'), '/')[8], parameters('appGateway_subnet')), '2023-09-01'), 'addressPrefix'), tryGet(reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, split(parameters('vnetResourceId'), '/')[4]), 'Microsoft.Network/virtualNetworks/subnets', split(parameters('vnetResourceId'), '/')[8], parameters('appGateway_subnet')), '2023-09-01'), 'addressPrefix'), reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, split(parameters('vnetResourceId'), '/')[4]), 'Microsoft.Network/virtualNetworks/subnets', split(parameters('vnetResourceId'), '/')[8], parameters('appGateway_subnet')), '2023-09-01').addressPrefixes[0]), '/')[0], '.')[1], split(split(if(contains(reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, split(parameters('vnetResourceId'), '/')[4]), 'Microsoft.Network/virtualNetworks/subnets', split(parameters('vnetResourceId'), '/')[8], parameters('appGateway_subnet')), '2023-09-01'), 'addressPrefix'), tryGet(reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, split(parameters('vnetResourceId'), '/')[4]), 'Microsoft.Network/virtualNetworks/subnets', split(parameters('vnetResourceId'), '/')[8], parameters('appGateway_subnet')), '2023-09-01'), 'addressPrefix'), reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, split(parameters('vnetResourceId'), '/')[4]), 'Microsoft.Network/virtualNetworks/subnets', split(parameters('vnetResourceId'), '/')[8], parameters('appGateway_subnet')), '2023-09-01').addressPrefixes[0]), '/')[0], '.')[2], add(int(split(split(if(contains(reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, split(parameters('vnetResourceId'), '/')[4]), 'Microsoft.Network/virtualNetworks/subnets', split(parameters('vnetResourceId'), '/')[8], parameters('appGateway_subnet')), '2023-09-01'), 'addressPrefix'), tryGet(reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, split(parameters('vnetResourceId'), '/')[4]), 'Microsoft.Network/virtualNetworks/subnets', split(parameters('vnetResourceId'), '/')[8], parameters('appGateway_subnet')), '2023-09-01'), 'addressPrefix'), reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, split(parameters('vnetResourceId'), '/')[4]), 'Microsoft.Network/virtualNetworks/subnets', split(parameters('vnetResourceId'), '/')[8], parameters('appGateway_subnet')), '2023-09-01').addressPrefixes[0]), '/')[0], '.')[3]), 4))]"
$newAppGw.properties.frontendIPConfigurations += ConvertFrom-Json -InputObject $($frontendIpResourceString -f $appGateway.FrontendIPConfigurations[0].Name,$secondary,$firstIpOfSubnet)
foreach($frontEndPort in $appGateway.FrontendPorts)
{
    $newAppGw.properties.frontendPorts += ConvertFrom-Json -InputObject $($fronendPortResourceString -f $frontEndPort.Name,$frontEndPort.Port) -Depth 20
}
foreach($backendPool in $appGateway.BackendAddressPools)
{
    $backend = ConvertFrom-Json -InputObject $($backendAddressPoolResourceString -f $backendPool.Name) -Depth 20
    $backend.properties.backendAddresses += $backendPool.BackendAddresses
    $backend.properties.backendIpConfigurations += $backendPool.BackendIpConfigurations
    $newAppGw.properties.backendAddressPools += $backend
}
foreach($httpSetting in $appGateway.BackendHttpSettingsCollection)
{
    if($null -ne $httpSetting.Probe)
    {
        $backendSetting = ConvertFrom-Json -InputObject $($backendHttpSettingCustomProbeResourceString -f "[concat(resourceId('Microsoft.Netowrk/applicationGateways',parameters('appGateway_name')),'/probes/$($httpSetting.Probe.Id.Split("/")[10])')]",$httpSetting.Name,$httpSetting.Port.ToString(),$httpSetting.Protocol,$httpSetting.CookieBasedAffinity,$httpSetting.RequestTimeout.ToString(),$($httpSetting.ConnectionDraining -eq $null ? "null" : "`"$($httpSetting.ConnectionDraining)`""),$($httpSetting.HostName -eq $null ? "null" : "`"$($httpSetting.HostName)`""),$httpSetting.PickHostNameFromBackendAddress.ToString().ToLower(),$httpSetting.AffinityCookieName,$($httpSetting.Path -eq $null ? "null" : "`"$($httpSetting.Path)`"")) -Depth 20
        foreach($rootCert in $httpSetting.TrustedRootCertificates)
        {
            $backendSetting.properties.TrustedRootCertificates += New-Object -TypeName psobject -Property @{
                Id = "[concat(resourceId('Microsoft.Netowrk/applicationGateways',parameters('appGateway_name')),'/trustedRootCertificates/$($rootCert.Id.Split("/")[10])')]"
            }
        }        
        $newAppGw.properties.backendHttpSettingsCollection += $backendSetting
    }
    else {
        $backendSetting = ConvertFrom-Json -InputObject $($backendHttpSettingResourceString -f $httpSetting.Name,$httpSetting.Port.ToString(),$httpSetting.Protocol,$httpSetting.CookieBasedAffinity,$httpSetting.RequestTimeout.ToString(),$($httpSetting.ConnectionDraining -eq $null ? "null" : (ConvertTo-Json -InputObject $($httpSetting.ConnectionDraining))),$($httpSetting.HostName -eq $null ? "null" : "`"$($httpSetting.HostName)`""),$httpSetting.PickHostNameFromBackendAddress.ToString().ToLower(),$httpSetting.AffinityCookieName,$($httpSetting.Path -eq $null ? "null" : "`"$($httpSetting.Path)`"")) -Depth 20
        foreach($rootCert in $httpSetting.TrustedRootCertificates)
        {
            $backendSetting.properties.TrustedRootCertificates += New-Object -TypeName psobject -Property @{
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
        $listenerSetting = ConvertFrom-Json -InputObject $($listnerResourceFirewallPolicyString -f $wafName,$listener.FrontendIpConfiguration.Id.Split("/")[10],$listener.FrontendPort.Id.Split("/")[10],$listener.Protocol,$($listener.HostName -eq $null ? "null" : "`"$($listener.HostName)`""),$($listener.SslCertificate -eq $null ? "null" : "{ `"id`":`"[concat(resourceId('Microsoft.Network/applicationGateways',parameters('appGateway_name')),'/sslCertificates/$($listener.SslCertificate.Id.Split("/")[10])')]`"}"),$listener.RequireServerNameIndication.ToString().ToLower(),$($listener.SslProfile -eq $null ? "null" : "{ `"id`":`"[concat(resourceId('Microsoft.Network/applicationGateways',parameters('appGateway_name')),'/sslProfiles/$($listener.SslProfile.Id.Split("/")[10])')]`"}"),$listener.Name )
        $listenerSetting.properties.HostNames += $listener.HostNames
        $newAppGw.properties.httpListeners += $listenerSetting
    }
    else 
    {
        $listenerSetting = ConvertFrom-Json -InputObject $($listnerResourceString -f $listener.FrontendIpConfiguration.Id.Split("/")[10],$listener.FrontendPort.Id.Split("/")[10],$listener.Protocol,$($listener.HostName -eq $null ? "null" : "`"$($listener.HostName)`""),$($listener.SslCertificate -eq $null ? "null" : "{ `"id`":`"[concat(resourceId('Microsoft.Network/applicationGateways',parameters('appGateway_name')),'/sslCertificates/$($listener.SslCertificate.Id.Split("/")[10])')]`"}"),$listener.RequireServerNameIndication.ToString().ToLower(),$($listener.SslProfile -eq $null ? "null" : "{ `"id`":`"[concat(resourceId('Microsoft.Network/applicationGateways',parameters('appGateway_name')),'/sslProfiles/$($listener.SslProfile.Id.Split("/")[10])')]`"}"),$listener.Name )
        $listenerSetting.properties.HostNames += $listener.HostNames
        $newAppGw.properties.httpListeners += $listenerSetting
    }
}
foreach($urlPathMap in $appGateway.UrlPathMaps)
{
    $map = ConvertFrom-Json -InputObject $($urlPathMapResourceString -f $urlPathMap.Name,$urlPathMap.DefaultBackendAddressPool.Id.Split("/")[10],$urlPathMap.DefaultBackendHttpSettings.Id.Split("/")[10],$($urlPathMap.DefaultRewriteRuleSet -eq $null ? "null" : $(pathRewriteRuleResourceString -f $urlPathMap.DefaultRewriteRuleSet.Id.Split("/")[10])),$($urlPathMap.DefaultRedirectConfiguration -eq $null ? "null" : $($pathRedirectRuleResourceString -f $urlPathMap.DefaultRedirectConfiguration.Id.Split("/")[10]))) -Depth 20
    foreach($rule in $urlPathMap.PathRules)
    {
        $pathRule = ConvertFrom-Json -InputObject $($pathRulesResourceString -f $rule.Name,$($rule.BackendAddressPool -eq $null ? "null" : $routingRuleBackendResourceString -f $rule.BackendAddressPool.Id.Split("/")[10]),$($rule.BackendHttpSettings -eq $null ? "null" : $routingRuleBackendHttpSettingsResourceString -f $rule.BackendHttpSettings.Id.Split("/")[10]),$($rule.RewriteRuleSet -eq $null ? "null" : $($pathRewriteRuleResourceString -f $rule.RewriteRuleSet.Id.Split("/")[10])),$($rule.RedirectConfiguration -eq $null ? "null" : $pathRedirectRuleResourceString -f $rule.RedirectConfiguration.Id.Split("/")[10]),$($rule.FirewallPolicy -eq $null ? "null" : $($firewallPolicyResourceString -f $rule.FirewallPolicy.Id.Split("/")[8])))
        $pathRule.properties.Paths += $rule.Paths
        $map.properties.PathRules += $pathRule
    }
    $newAppGw.properties.urlPathMaps += $map
}
foreach($routingRule in $appGateway.RequestRoutingRules)
{
    $newAppGw.properties.requestRoutingRules += ConvertFrom-Json -InputObject $($routingRuleResourceString -f $routingRule.Name,$routingRule.RuleType,$routingRule.Priority,$($routingRule.BackendAddressPool -eq $null ? "null" : $($routingRuleBackendResourceString -f $routingRule.BackendAddressPool.Id.Split("/")[10])),$($routingRule.BackendHttpSettings -eq $null ? "null" : $($routingRuleHttpSettingResourceString -f $routingRule.BackendHttpSettings.Id.Split("/")[10])),$routingRule.HttpListener.Id.Split("/")[10],$($routingRule.UrlPathMap -eq $null ? "null" : $($routingUrlPathIdResourceString -f $routingRule.UrlPathMap.Id.Split("/")[10])),$($routingRule.RewriteRuleSet -eq $null ? "null" : $($routingRewriteRuleIdResourceString -f $routingRule.RewriteRuleSet.Id.Split("/")[10])),$($routingRule.RedirectConfiguration -eq $null ? "null" : $($pathRedirectRuleResourceString -f $routingRule.RedirectConfiguration.Id.Split("/")[10] ))) -Depth 20
}
foreach($probe in $appGateway.Probes)
{
    $newAppGw.properties.probes += ConvertFrom-Json -InputObject $($probeResourceString -f $probe.Name,$probe.Protocol,$($probe.Host -eq $null ? "null" : "`"$probe.Host`""),$probe.Path,$probe.Interval,$probe.Timeout,$probe.UnhealthyThreshold,$probe.PickHostNameFromBackendHttpSettings.ToString().ToLower(),$probe.MinServers,$($probe.Port -eq $null ? "null" : $probe.Port),$(ConvertTo-Json -InputObject $probe.Match -Depth 20)) -Depth 20
}
foreach($rewrite in $appGateway.RewriteRuleSets)
{
    $ruleSet = ConvertFrom-Json -InputObject $($rewriteRuleSetResourceString -f $rewrite.Name) -Depth 20
    foreach($rewriteRule in $rewrite.RewriteRules)
    {
        $ruleSet.properties.RewriteRules += ConvertFrom-Json -InputObject $($rewriteRuleResourceString -f $rewriteRule.Name,$rewriteRule.RuleSequence,$(ConvertTo-Json -InputObject $rewriteRule.Conditions -Depth 20),$(ConvertTo-Json -InputObject $rewriteRule.ActionSet -Depth 20)) -Depth 20
    }
    $newAppGw.properties.rewriteRuleSets += $ruleSet
}
foreach($redirect in $appGateway.RedirectConfigurations)
{
    $redirectRule = ConvertFrom-Json -InputObject $($redirectRuleResourceString -f $redirect.Name,$redirect.RedirectType,$($redirect.TargetListener -eq $null ? "null" : $redirectTargetListenerResourceString -f $redirect.TargetListener.Id.Split("/")[10]),$($redirect.TargetUrl -eq $null ? "null" : "`"$($redirect.TargetUrl)`""),($redirect.IncludePath -eq $null ? "null" : $redirect.IncludePath.ToString().ToLower()),$($redirect.IncludeQueryString -eq $null ? "null" : $redirect.IncludeQueryString.ToString().ToLower()))
    foreach($requestRouting in $redirect.RequestRoutingRules)
    {
        $redirectRule.properties.RequestRoutingRules += ConvertFrom-Json -InputObject $($routingRuleIdResoruceString -f $requestRouting.Id.Split("/")[10]) -Depth 20
    }
    foreach($pathRules in $redirect.PathRules)
    {
        $redirectRule.properties.PathRules += ConvertFrom-Json -InputObject $($routingUrlPathRulesIdResourceString -f $pathRules.Id.Split("/")[10],$pathRules.Id.Split("/")[12]) -Depth 20
    }
    foreach($urlPath in $redirect.UrlPathMaps)
    {
        $redirectRule.properties.UrlPathMaps += ConvertFrom-Json -InputObject $($routingUrlPathIdResourceString -f $urlPath.Id.Split("/")[10]) -Depth 20
    }
    $newAppGw.properties.redirectConfigurations += $redirectRule
}
foreach($sslProfile in $appGateway.SslProfiles)
{
    $profileSsl = ConvertFrom-Json -InputObject $($sslProfileResourceString -f $sslProfile.Name,$($sslProfile.SslPolicy -eq $null ? "null" : $(ConvertTo-Json -InputObject $($sslProfile.SslPolicy | Select PolicyType,PolicyName,CipherSuites,MinProtocolVersion) -Depth 20)),$(ConvertTo-Json -InputObject $sslProfile.ClientAuthConfiguration -Depth 20)) -Depth 20
    foreach($trustedCert in $sslProfile.TrustedClientCertificates)
    {
        $profileSsl.properties.TrustedClientCertificates += ConvertFrom-Json -InputObject $($sslProfileTrustedCertificateResourceString -f $trustedCert.Id.Split("/")[10]) -Depth 20
    }
    $newAppGw.properties.sslProfiles += $profileSsl
}
foreach($trustedClientCert in $appGateway.TrustedClientCertificates)
{
    $newAppGw.properties.trustedClientCertificates += ConvertFrom-Json -InputObject $($trustedClientCertResourceString -f $trustedClientCert.Name,$trustedClientCert.Data,$trustedClientCert.ClientCertIssuerDN) -Depth 20
}
$template.resources += $newAppGw
$template.variables | Add-Member -MemberType NoteProperty -name "User" -Value $user
$templateSpec
Select-AzSubscription -Subscription $templateResourceSubscription
$currentTemplateSpec = Get-AzTemplateSpec -ResourceGroupName $templateResourceGroup -Name $($appGateway.Name + "-DR-Template")
if($null -eq $currentTemplateSpec)
{
    New-AzTemplateSpec -ResourceGroupName $templateResourceGroup -Name $($appGateway.Name + "-DR-Template") -Location $drRegion -TemplateJson $(ConvertTo-Json -InputObject $template -Depth 20) -Version "1"
}
else {
    $version = $currentTemplateSpec.Versions.Count + 1
    New-AzTemplateSpec -ResourceGroupName $templateResourceGroup -Name $($appGateway.Name + "-DR-Template") -Location $drRegion -TemplateJson $(ConvertTo-Json -InputObject $template -Depth 20) -Version $version 
}