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
<style>
.nsgs {{
  font-family: Arial, Helvetica, sans-serif;
  border-collapse: collapse;
  width: 100%;
}}

.nsgs td, #customers th {{
  border: 1px solid #ddd;
  padding: 8px;
}}

.nsgs tr:nth-child(even){{background-color: #f2f2f2;}}

.nsgs tr:hover {{background-color: #ddd;}}

.nsgs th {{
  padding-top: 12px;
  padding-bottom: 12px;
  text-align: left;
  background-color: #00bfff;
  color: white;
}}
</style>
<body>
<h2>Interfaces With No NSG Associated</h2>
<table class="nsgs">
<tr><th>Interface</th><th>Subnet</th><th>VNET</th><th>Subscription</th></tr>
{0}
</table>
<h2>Interfaces With Custom Rules Configured</h2>
<table class="nsgs">
<tr><th>Interface</th><th>NSGS Associated</th><th>Inbound from Internet Allowed</th><th>Subnet</th><th>VNET</th><th>Subscription</th></tr>
{1}
</table>
<h2>Interfaces Protected with Default Rules</h2>
<table class="nsgs">
<tr><th>Interface</th><th>NSGS Associated</th><th>Subnet</th><th>VNET</th><th>Subscription</th></tr>
{2}
</table>
</body>
</html>
'@
$interfacesPortectedWithDefaultRules = $interfacesReport | ?{($_.SubnetDefaultRules -eq $false -and $_.InterfaceDefaultRules -eq $true) -or ($_.SubnetDefaultRules -eq $true -and $_.InterfaceDefaultRules -eq $true) -or ($_.SubnetDefaultRules -eq $true -and $_.InterfaceDefaultRules -eq $false)}
$interfacesCustomRules = $interfacesReport | ?{($_.SubnetDefaultRules -eq $false -and $_.InterfaceDefaultRules -eq $false -and $_.SubnetNSG -ne $null) -or ($_.SubnetDefaultRules -eq $false -and $_.InterfaceDefaultRules -eq $false -and $_.InterfaceNSG -ne $null)}
$interfacesOpen = $interfacesReport | ?{$_.SubnetNSG -eq $null -and $_.InterfaceNSG -eq $null}
$htmlInterfacesPortectedWithDefaultRules = @()
$htmlinterfacesCustomRules = @()
$htmlinterfacesOpen = @()
foreach($interface in $interfacesPortectedWithDefaultRules)
{
    $nsgs = ""
    if($interface.SubnetNSG -ne $null)
    {
        $nsgs = $interface.SubnetNSG.nsgName
    }
    if ($interface.InterfaceNSG -ne $null -and $interface.SubnetNSG -ne $null) {
        $nsgs += "," + $interface.InterfaceNSG.nsgName
    }
    elseif($interface.InterfaceNSG -ne $null) {
        $nsgs = $interface.InterfaceNSG.nsgName 
    }
    $htmlInterfacesPortectedWithDefaultRules += "<tr><td>$($interface.Interface.split("/")[-1])</td><td>$($nsgs)</td><td>$($interface.Subnet.split("/")[-1])</td><td>$($interface.Subnet.split("/")[8])</td><td>$($interface.SubscriptionId)</td></tr>"
}
foreach($interface in $interfacesCustomRules)
{   
    $allowedInboundInet = $false  
    $rules = $interface.SubnetNSG.rules | ?{($_.SourceAddressPrefix -eq "*" -or $_.SourceAddressPrefix -eq "Internet" ) -and $_.Access -eq "Allow" -and $_.Priority -lt 5000} 
    $nsgs = $interface.SubnetNSG.nsgName
    if($rules.Count -gt 0 -or $interface.SubnetNSG -eq $null)
    { 
        #$nsgs += $interface.SubnetNSG.nsgName       
        if($interface.InterfaceNSG -ne $null)
        {
            $rules = $null
            $rules = $interface.InterfaceNSG.rules | ?{($_.SourceAddressPrefix -eq "*" -or $_.SourceAddressPrefix -eq "Internet" ) -and $_.Access -eq "Allow" -and $_.Priority -lt 5000}
            if($rules.Count -gt 0)
            {
                $nsgs += "," + $interface.InterfaceNSG.nsgName
                $allowedInboundInet = $true
            }
        }
        else {
            $allowedInboundInet = $true
        }        
    }
    $htmlinterfacesCustomRules += "<tr><td>$($interface.Interface.split("/")[-1])</td><td>$($nsgs)</td><td>$($allowedInboundInet)</td><td>$($interface.Subnet.split("/")[-1])</td><td>$($interface.Subnet.split("/")[8])</td><td>$($interface.SubscriptionId)</td></tr>"
}
foreach($interface in $interfacesOpen)
{
    $htmlinterfacesOpen += "<tr><td>$($interface.Interface.split("/")[-1])</td><td>$($interface.Subnet.split("/")[-1])</td><td>$($interface.Subnet.split("/")[8])</td><td>$($interface.SubscriptionId)</td></tr>"
}
$($reportHtml -f $($htmlinterfacesOpen -join ""),$($htmlinterfacesCustomRules -join ""),$($htmlInterfacesPortectedWithDefaultRules -join "")) | Out-File "$($PWD.Path)\interfaceReport.html"
#ConvertTo-Json -InputObject $interfacesReport -Depth 10 > "$($PWD.Path)\interfaceReport.json"