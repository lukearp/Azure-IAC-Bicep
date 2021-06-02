Connect-AzAccount -Identity -SubscriptionId $args[2];
foreach ($vm in $args[0]) {
    Stop-AzVM -Name $vm -ResourceGroupName $args[1] -Force -Confirm:$false;
}
sleep 15;
foreach ($vm in $args[0]) {
    Start-VM -Name $vm -ResourceGroupName $args[1];
}
