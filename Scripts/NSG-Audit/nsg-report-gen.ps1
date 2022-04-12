param (
    $path
)

$data = ConvertFrom-Json $((Get-Content -Path $path) -join "") -Depth 10
$interfacesReport = @()
$subnetsReport = @()
foreach($d in $data)
{
    foreach($subnet in $d.ConnectedDevices)
    {
        if($subnet.subnet -notlike "*GatewaySubnet")
        {
            $subnetNsg = $null
            $subnetdefaultRules = $true
            $subnetNsg = $d.NSGsWithDefaultRules | ?{$_.subnets -contains $subnet.subnet}
            if($subnetNsg -eq $null)
            {
                $subnetNsg = $d.NSGsWithSecurityRules | ?{$_.subnets -contains $subnet.subnet}
                $subnetdefaultRules = $false
            }
            foreach($interface in $subnet.interfaces)
            {
                $rule = $null
                $interfaceDefaultRules = $true
                $rule = $d.NSGsWithDefaultRules | ?{$_.interfaces -contains $($interface.Split("/")[0..8] -join "/")}
                if($rule -eq $null)
                {
                    $rule = $d.NSGsWithSecurityRules | ?{$_.interfaces -contains $($interface.Split("/")[0..8] -join "/")}
                    $interfaceDefaultRules = $false
                }
                $interfacesReport += New-Object -TypeName psobject -Property @{
                    SubscriptionName = $d.SubscriptionName
                    SubscriptionId = $d.SubscriptionId
                    Interface = $($interface.Split("/")[0..8] -join "/")
                    InterfaceNSG = $rule
                    InterfaceDefaultRules = $interfaceDefaultRules
                    Subnet = $subnet.subnet
                    SubnetNSG = $subnetNsg
                    SubnetDefaultRules = $subnetdefaultRules
                }
            }
        }        
    }
}
$reportHtml = @'
<html>
<head>
<title>NSG Audit</title>
</head>
<body>
<p>Interfaces Protected with Default Rules</p>
<table>
<tr><th>Interface</th><th>Subnet</th><th>VNET</th><th>Subscription</th></tr>
{0}
</table>
<p>Interfaces With Custom Rules Configured</p>
<table>
{1}
</table>
<p>Interfaces With No NSG Associated</p>
<table>
{2}
</table>
</body>
</html>
'@
$interfacesPortectedWithDefaultRules = $interfacesReport | ?{($_.SubnetDefaultRules -eq $false -and $_.InterfaceDefaultRules -eq $true) -or ($_.SubnetDefaultRules -eq $true -and $_.InterfaceDefaultRules -eq $true) -or ($_.SubnetDefaultRules -eq $true -and $_.InterfaceDefaultRules -eq $false)}
$interfacesCustomRules = $interfacesReport | ?{($_.SubnetDefaultRules -eq $false -and $_.InterfaceDefaultRules -eq $false -and $_.SubnetNSG -ne $null) -or ($_.SubnetDefaultRules -eq $false -and $_.InterfaceDefaultRules -eq $false -and $_.InterfaceNSG -ne $null)}
$interfacesOpen = $interfacesReport | ?{$_.SubnetNSG -eq $null -and $_.InterfaceNSG -eq $null}
$htmlInterfacesPortectedWithDefaultRules = @()
foreach($interface in $interfacesPortectedWithDefaultRules)
{
    $htmlInterfacesPortectedWithDefaultRules += "<tr><td>$($interface.Interface.split("/")[-1])</td><td>$($interface.Subnet.split("/")[-1])</td><td>$($interface.Subnet.split("/")[8])</td><td>$($interface.SubscriptionId)</td></tr>"
}
$($reportHtml -f $($htmlInterfacesPortectedWithDefaultRules -join "")) | Out-File "$($PWD.Path)\interfaceReport.html"
#ConvertTo-Json -InputObject $interfacesReport -Depth 10 > "$($PWD.Path)\interfaceReport.json"