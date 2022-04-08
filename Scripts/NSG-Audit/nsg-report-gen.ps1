param (
    $path
)

$data = ConvertFrom-Json $((Get-Content -Path $path) -join "") -Depth 10
$interfacesReport = @()
foreach($d in $data)
{
    foreach($subnet in $d.ConnectedDevices)
    {
        if($subnet.subnet -notlike "*GatewaySubnet")
        {
            foreach($interface in $subnet.interfaces)
            {
                $rule = ""
                $rule = $d.NSGsWithSecurityRules | ?{$_.interfaces -contains $($interface.Split("/")[0..8] -join "/")}
                if($rule -eq "")
                {
                    $rule = $d.NSGsWithDefaultRules | ?{$_.interfaces -contains $($interface.Split("/")[0..8] -join "/")}
                }
                $interfacesReport += New-Object -TypeName psobject -Property @{
                    SubscriptionName = $d.SubscriptionName
                    SubscriptionId = $d.SubscriptionId
                    Interface = $($interface.Split("/")[0..8] -join "/")
                    NSGName = $rule.nsgName
                    NSGRg = $rule.nsgResourceGroup
                    Subnet = $subnet.subnet
                }
            }
        }        
    }
}

$interfacesWithNoNsg = $interfacesReport | ?{$_.NSGName -eq $null}
$noNsgReport = @()
foreach($interface in $interfacesWithNoNsg)
{
    $noNsgReport += $interface
}

ConvertTo-Json -InputObject $interfacesReport -Depth 10 > "$($PWD.Path)\interfaceReport.json"
ConvertTo-Json -InputObject $interfacesWithNoNsg -Depth 10 > "$($PWD.Path)\interfacesWithNoNsg.json"