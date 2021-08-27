param (
    $subscription,
    $subnets,
    $vnetAddressSpaces,
    $moduleUrl
)

#Install-Module -Name PSSubnetCarver -Force -Confirm:$false
#Import-Module -Name PSSubnetCarver 
Invoke-WebRequest -Uri "https://github.com/lukearp/Azure-IAC-Bicep/releases/download/DSC/PSSubnetCarver.1.2.0.zip" -OutFile "PSSubnetCarver.zip"
Expand-Archive .\PSSubnetCarver.zip -DestinationPath .\PSSubnetCarver
Import-Module .\PSSubnetCarver\
$subnets = ConvertFrom-Json $subnets
$vnetAddressSpaces = ConvertFrom-Json $vnetAddressSpaces   

Write-Output $subnets
Write-Output $vnetAddressSpaces
<#if($vnetAddressSpaces.GetType().BaseType.Name -eq "Array") {
    Write-Output "Multiple Address Spaces"
    for ($i = 0; $i -lt $vnetAddressSpaces.count; $i++)
    {
        New-SCContext -Name $($subscription + "-" + $i) -RootAddressSpace $vnetAddressSpaces[$i]
    }
} else {
    Write-Output "Single Address Space"
    New-SCContext -Name $($subscription + "-0") -RootAddressSpace $vnetAddressSpaces
}#>
New-SCContext -Name "MyContext" -RootAddressSpace "10.20.0.0/17"
Get-SCContext
New-SCContext -Name "Again" -RootAddressSpace $vnetAddressSpaces
Get-SCContext
New-SCContext -Name $subscription -RootAddressSpace "10.55.0.0/20"
<#
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
$DeploymentScriptOutputs['output'] = ConvertTo-Json $subnets
#>