$Settings = @{ SqlManagement = @{ IsEnabled = $true }; ExcludedSqlInstances = @(); LicenseType="Paid"}

$query = @'
resources
| where type == "microsoft.hybridcompute/machines"
| where properties.mssqlDiscovered == true
| project name, resourceGroup,location,subscriptionId
'@

$arcSqlVms = Search-AzGraph -Query $query

foreach($vm in $arcSqlVms)
{
    $arcVMExtension = Get-AzConnectedMachineExtension -MachineName $vm.name -ResourceGroupName $vm.resourceGroup -SubscriptionId $vm.subscriptionId -Name "WindowsAgent.SqlServer"
    if($null -eq $arcVMExtension)
    {
        Write-Host "Installing Extension on $($vm.name)"
        Add-Content -Path ".\SQL-Install-Extension.log" -Value $vm.name
        Select-AzSubscription $vm.subscriptionId
        New-AzConnectedMachineExtension -Name "WindowsAgent.SqlServer" -ResourceGroupName $vm.resourceGroup -MachineName $vm.name -Location $vm.location -Publisher "Microsoft.AzureData" -Settings $Settings -ExtensionType "WindowsAgent.SqlServer" -AsJob
    }
}
