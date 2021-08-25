param (
    $subscriptions,
    $subnets,
    $cloudAddressSpace,
    $cloudName
)

#Check for PS Subnet Carver Module
try {
    Import-Module -Name PSSubnetCarver
} 
catch {
    Install-Module -Name PSSubnetCarver
    Import-Module -Name PSSubnetCarver
}

New-SCContext -Name $cloudName -RootAddressSpace $cloudAddressSpace

foreach ($subscription in $subscriptions) {
    $contextName = $subscription.name + "-" + $subscription.region
    try {
        Get-SCContext -Name $contextName 
    }
    catch {
       
        if($subscription.cider -eq $true) {
            $ipReserve = Get-SCSubnet -Context $cloudName -ReserveCIDR $subscription.addressSize
            New-SCContext -Name $contextName -RootAddressSpace $($ipReserve.NetworkIPAddress.ToString() + "/" + $ipReserve.CIDR)
        }
        else {
            $ipReserve = Get-SCSubnet -Context $cloudName -ReserveCount $subscription.addressSize
            New-SCContext -Name $contextName -RootAddressSpace $($ipReserve.NetworkIPAddress.ToString() + "/" + $ipReserve.CIDR)
        }
    }
    $subnetsOfSubscription = $subnets | ?{$_.Subscription -eq $subscription.name}
    foreach ($subnet in $subnetsOfSubscription) {
        if($subnet.cider -eq $true) {
            $subnetReserve = Get-SCSubnet -Context $($subnet.subscription + "-" + $subnet.region) -ReserveCIDR $subnet.addressSize
            $subnet | Add-Member -Name AddressSpaceReserved -Value $($subnetReserve.NetworkIPAddress.ToString() + "/" + $subnetReserve.CIDR) -MemberType NoteProperty
        }
        else {
            $subnetReserve = Get-SCSubnet -Context $($subnet.subscription + "-" + $subnet.region) -ReserveCount $subnet.addressSize
            $subnet | Add-Member -Name AddressSpaceReserved -Value $($subnetReserve.NetworkIPAddress.ToString() + "/" + $subnetReserve.CIDR) -MemberType NoteProperty
        }
    }
}
