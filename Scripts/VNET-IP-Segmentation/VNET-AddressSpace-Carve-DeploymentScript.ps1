param (
    $subscription,
    $subnets,
    $vnetAddressSpaces
)

#Check for PS Subnet Carver Module
try {
    Install-Module -Name PSSubnetCarver -Force -Confirm:$false
    Import-Module -Name PSSubnetCarver    
} 
catch {
    
}
$subnets = ConvertFrom-Json $subnets
$vnetAddressSpaces = ConvertFrom-Json $vnetAddressSpaces
Write-Output $subnets
Write-Output $vnetAddressSpaces
if($vnetAddressSpaces.GetType().BaseType.Name -eq "Array") {
    Write-Output "Multiple Address Spaces"
    for ($i = 0; $i -lt $vnetAddressSpaces.count; $i++)
    {
        New-SCContext -Name $($subscription + "-" + $i) -RootAddressSpace $vnetAddressSpaces[$i]
    }
} else {
    Write-Output "Single Address Space"
    New-SCContext -Name $($subscription + "-0") -RootAddressSpace $vnetAddressSpaces
}

foreach ($subnet in $subnets) {
    if($subnet.cider -eq $true) {
        if ($vnetAddressSpaces.GetType().BaseType.Name -eq "Array") {
            for ($i = 0; $i -lt $vnetAddressSpaces.count; $i++) {
                try {
                    $subnetReserve = Get-SCSubnet -Context $($subscription + "-" + $i) -ReserveCIDR $subnet.addressSize -ErrorAction SilentlyContinue
                    $subnet | Add-Member -Name AddressSpaceReserved -Value $($subnetReserve.NetworkIPAddress.ToString() + "/" + $subnetReserve.CIDR) -MemberType NoteProperty
                    break;
                } catch {
                    
                }            
            }    
        } else {
            try {
                $subnetReserve = Get-SCSubnet -Context $($subscription + "-0") -ReserveCIDR $subnet.addressSize -ErrorAction SilentlyContinue
                $subnet | Add-Member -Name AddressSpaceReserved -Value $($subnetReserve.NetworkIPAddress.ToString() + "/" + $subnetReserve.CIDR) -MemberType NoteProperty
            } catch {
                
            }   
        }           
    }
    else {
        if ($vnetAddressSpaces.GetType().BaseType.Name -eq "Array") {
            for ($i = 0; $i -lt $vnetAddressSpaces.count; $i++) {
                try {
                    $subnetReserve = Get-SCSubnet -Context $($subscription + "-" + $i) -ReserveCount $subnet.addressSize -ErrorAction SilentlyContinue
                    $subnet | Add-Member -Name AddressSpaceReserved -Value $($subnetReserve.NetworkIPAddress.ToString() + "/" + $subnetReserve.CIDR) -MemberType NoteProperty
                    break;
                } catch {
                    
                }            
            }
        } else {
            try {
                $subnetReserve = Get-SCSubnet -Context $($subscription + "-0") -ReserveCount $subnet.addressSize -ErrorAction SilentlyContinue
                $subnet | Add-Member -Name AddressSpaceReserved -Value $($subnetReserve.NetworkIPAddress.ToString() + "/" + $subnetReserve.CIDR) -MemberType NoteProperty
            } catch {
                
            }  
        }       
    }
}

$DeploymentScriptOutputs = @{};
$DeploymentScriptOutputs['output'] = ConvertTo-Json $subnets