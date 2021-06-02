Connect-AzAccount -Identity -SubscriptionId $args[2];
$vms = $args[0].Split("[").Split("]").Split("'");
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
        Start-AzVM -Name $vm -ResourceGroupName $args[1];
    }
}
$vms