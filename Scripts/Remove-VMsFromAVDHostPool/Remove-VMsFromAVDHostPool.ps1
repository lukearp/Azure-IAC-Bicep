param(
    [array] $vms,
    [string] $hostpoolName,
    [string] $hostpoolResourceGroup,
    [string] $subscription
)
function Remove-VMsFromHostPool {
    param(
        [array] $vms,
        [string] $hostpoolName,
        [string] $hostpoolResourceGroup
    )
    $hosts = @()
    foreach($vm in $vms)
    {
        $hosts += (Get-AzWvdSessionHost -HostPoolName $hostpoolName -ResourceGroupName $hostpoolResourceGroup | ?{$_.Name -like "*$($vm)*"}).Name
    }
    foreach($sessionHost in $hosts)
    {
        Remove-AzWvdSessionHost -HostPoolName $vms -ResourceGroupName $hostpoolResourceGroup -Name $sessionHost.Split("/")[1]
    }
    return $hosts
}
Connect-AzAccount -Identity -Subscription $subscription
$DeploymentScriptOutputs = @{};
$DeploymentScriptOutputs['sessionHosts']= Remove-VMsFromHostPool -vms $vms -hostpoolName $hostpoolName -hostpoolResourceGroup $hostpoolResourceGroup