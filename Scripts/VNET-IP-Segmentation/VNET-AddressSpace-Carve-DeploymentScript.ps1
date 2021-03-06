param (
    $subscription,
    $subnets,
    $vnetAddressSpaces,
    $moduleUrl
)

Install-Module -Name PSSubnetCarver -Force -Confirm:$false #-MinimumVersion 1.0.1 -MaximumVersion 1.0.1
Import-Module -Name PSSubnetCarver 

$subnets = ConvertFrom-Json $subnets
$vnetAddressSpaces = ConvertFrom-Json $vnetAddressSpaces   

Write-Output $subnets
Write-Output $vnetAddressSpaces
if($vnetAddressSpaces.GetType().BaseType.Name -eq "Array") {
    Write-Output "Multiple Address Spaces"
    for ($i = 0; $i -lt $vnetAddressSpaces.count; $i++)
    {
        Set-SCContext -Name $($subscription + "-" + $i) -RootAddressSpace $vnetAddressSpaces[$i]
    }
} else {
    Write-Output "Single Address Space"
    Set-SCContext -Name $($subscription + "-0") -RootAddressSpace $vnetAddressSpaces
}

foreach ($subnet in $subnets) {
    if($subnet.cidr -eq $true) {
        Write-Output "$($subnet.name) is using Cidr"
        if ($vnetAddressSpaces.GetType().BaseType.Name -eq "Array") {
            for ($i = 0; $i -lt $vnetAddressSpaces.count; $i++) {
                try {
                    $subnetReserve = Get-SCSubnet -Context $($subscription + "-" + $i) -ReserveCIDR $subnet.addressSize -ErrorAction SilentlyContinue
                    Write-Output "$($subnet.name) has $($subnetReserve.NetworkIPAddress.ToString())/$( $subnetReserve.CIDR)"
                    $subnet | Add-Member -Name AddressSpaceReserved -Value $($subnetReserve.NetworkIPAddress.ToString() + "/" + $subnetReserve.CIDR) -MemberType NoteProperty
                    Write-Output "Address Space Added to Object"
                    break;
                } catch {
                    
                }            
            }    
        } else {
            try {
                $subnetReserve = Get-SCSubnet -Context $($subscription + "-0") -ReserveCIDR $subnet.addressSize -ErrorAction SilentlyContinue
                Write-Output "$($subnet.name) has $($subnetReserve.NetworkIPAddress.ToString())/$( $subnetReserve.CIDR)"
                $subnet | Add-Member -Name AddressSpaceReserved -Value $($subnetReserve.NetworkIPAddress.ToString() + "/" + $subnetReserve.CIDR) -MemberType NoteProperty
                Write-Output "Address Space Added to Object"
            } catch {
                
            }   
        }           
    }
    else {
        Write-Output "$($subnet.name) is using Count"
        if ($vnetAddressSpaces.GetType().BaseType.Name -eq "Array") {
            for ($i = 0; $i -lt $vnetAddressSpaces.count; $i++) {
                try {
                    $subnetReserve = Get-SCSubnet -Context $($subscription + "-" + $i) -ReserveCount $subnet.addressSize -ErrorAction SilentlyContinue
                    Write-Output "$($subnet.name) has $($subnetReserve.NetworkIPAddress.ToString())/$( $subnetReserve.CIDR)"
                    $subnet | Add-Member -Name AddressSpaceReserved -Value $($subnetReserve.NetworkIPAddress.ToString() + "/" + $subnetReserve.CIDR) -MemberType NoteProperty
                    Write-Output "Address Space Added to Object"
                    break;
                } catch {
                    
                }            
            }
        } else {
            try {
                $subnetReserve = Get-SCSubnet -Context $($subscription + "-0") -ReserveCount $subnet.addressSize -ErrorAction SilentlyContinue
                Write-Output "$($subnet.name) has $($subnetReserve.NetworkIPAddress.ToString())/$( $subnetReserve.CIDR)"
                $subnet | Add-Member -Name AddressSpaceReserved -Value $($subnetReserve.NetworkIPAddress.ToString() + "/" + $subnetReserve.CIDR) -MemberType NoteProperty
                Write-Output "Address Space Added to Object"
            } catch {
                
            }  
        }       
    }
}

$DeploymentScriptOutputs = @{};
$DeploymentScriptOutputs['subnetObjs'] = $subnets