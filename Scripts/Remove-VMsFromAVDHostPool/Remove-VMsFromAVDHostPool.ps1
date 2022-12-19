param(
    [string] $vms,
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
        if($sessionHost -ne $null)
        {
            $rm = Remove-AzWvdSessionHost -HostPoolName $hostpoolName -ResourceGroupName $hostpoolResourceGroup -Name $sessionHost.Split("/")[1]
        }
    }
    return $hosts
}
$con = Connect-AzAccount -Identity -Subscription $subscription;
$sessionHosts = Remove-VMsFromHostPool -vms $vms.Replace("'","").Replace("[","").Replace("]","").Split(",") -hostpoolName $hostpoolName -hostpoolResourceGroup $hostpoolResourceGroup
$DeploymentScriptOutputs = @{};
$DeploymentScriptOutputs['sessionHosts'] = $sessionHosts