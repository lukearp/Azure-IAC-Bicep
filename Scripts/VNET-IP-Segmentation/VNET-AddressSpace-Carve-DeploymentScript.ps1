param (
    $subscription,
    $subnets,
    $vnetAddressSpaces
)

#Check for PS Subnet Carver Module
try {
    #Install-Module -Name PSSubnetCarver -Force -Confirm:$false
    #Import-Module -Name PSSubnetCarver
    
} 
catch {
    
}
$subnets = ConvertFrom-Json $subnets
$vnetAddressSpaces = ConvertFrom-Json $vnetAddressSpaces

for ($i = 0; $i -lt $vnetAddressSpaces.count; $i++)
{
    New-SCContext -Name $($subscription + "-" + $i) -RootAddressSpace $vnetAddressSpaces[$i]
}

$subnets = ConvertFrom-Json $subnets
$vnetAddressSpaces = ConvertFrom-Json $vnetAddressSpaces

foreach ($subnet in $subnets) {
    if($subnet.cider -eq $true) {
        for ($i = 0; $i -lt $vnetAddressSpaces.count; $i++) {
            try {
                $subnetReserve = Get-SCSubnet -Context $($subscription + "-" + $i) -ReserveCIDR $subnet.addressSize -ErrorAction SilentlyContinue
                $subnet | Add-Member -Name AddressSpaceReserved -Value $($subnetReserve.NetworkIPAddress.ToString() + "/" + $subnetReserve.CIDR) -MemberType NoteProperty
                break;
            } catch {
                
            }            
        }        
    }
    else {
        for ($i = 0; $i -lt $vnetAddressSpaces.count; $i++) {
            try {
                $subnetReserve = Get-SCSubnet -Context $($subscription + "-" + $i) -ReserveCount $subnet.addressSize -ErrorAction SilentlyContinue
                $subnet | Add-Member -Name AddressSpaceReserved -Value $($subnetReserve.NetworkIPAddress.ToString() + "/" + $subnetReserve.CIDR) -MemberType NoteProperty
                break;
            } catch {
                
            }            
        }
    }
}

$DeploymentScriptOutputs = @{};
$DeploymentScriptOutputs['output'] = $subnets