Connect-AzAccount -Identity -SubscriptionId $args[2];
$vms = $args[0].split(',');
foreach ($vm in $vms) {
    if($vm -ne $null)
    {
        Stop-AzVM -Name $vm -ResourceGroupName $args[1] -Force -Confirm:$false;
    }
}
sleep 15;
foreach ($vm in $vms) {
    if($vm -ne $null)
    {
        Start-VM -Name $vm -ResourceGroupName $args[1];
    }
}
