Connect-AzAccount -Identity -SubscriptionId $args[2];
$vms = $args[0].Split("[").Split("]").Split("'");
foreach ($vm in $vms) {
    if($vm -ne "")
    {
        Stop-AzVM -Name $vm -ResourceGroupName $args[1] -Force -Confirm:$false;
    }
}
sleep 15;
foreach ($vm in $vms) {
    if($vm -ne "")
    {
        Start-AzVM -Name $vm -ResourceGroupName $args[1];
    }
}
sleep 120
$vms