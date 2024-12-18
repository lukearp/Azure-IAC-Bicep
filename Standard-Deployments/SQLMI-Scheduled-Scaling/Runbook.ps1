param (
    [string]$ResourceId,
    [ValidateSet(4, 8, 16)]
    [int]$numberOfCores
)

#$ResourceId = "/subscriptions/32eb88b4-4029-4094-85e3-ec8b7ce1fc00/resourceGroups/sqlmi/providers/Microsoft.Sql/managedInstances/lukemitest"
$SubscriptionId = $ResourceId.Split("/")[2]
$sendNotificationUri = "https://prod-70.eastus.logic.azure.com:443/workflows/7fc02955ed4e4e649d17eb5d2c77cc66/triggers/When_a_HTTP_request_is_received/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=rJ7Ln7XuoLn4KHDAhzTUSxIvY6Y8UAvXOEGWlp1JO5Q"
#$numberOfCores = 8
#update-azConfig -DefaultSubscriptionForLogin $SubscriptionId
Connect-AzAccount -Identity -Subscription $SubscriptionId -Environment "AzureCloud"

$noticiationBody = @'
{{
    "start": {0},
    "managedInstanceName": "{1}",
    "originalCores": {2},
    "scaledCores": {3},
    "currentStep": "{4}",
    "previousStep": "{5}",
    "failed": {6}
}}
'@
$failed = "false"
$managedInstance = (Invoke-AzRestMethod -Method Get -Uri "https://management.azure.com$($ResourceId)?api-version=2021-11-01").Content
$new = ConvertFrom-Json -Input $managedInstance -Depth 100
$originalCores = $new.properties.vCores
Invoke-RestMethod -Method Post -Uri $sendNotificationUri -Body $($noticiationBody -f "true",$new.name, $originalCores, $numberOfCores, "Starting Step 1", "",$failed) -ContentType "application/json"
$new.sku.capacity = $numberOfCores
$new.properties.vCores = $numberOfCores

$updated = Invoke-AzRestMethod -Method PATCH -Uri "https://management.azure.com$($ResourceId)?api-version=2021-11-01" -Payload $(ConvertTo-Json -InputObject $new -Depth 100)
$operations = (Invoke-AzRestMethod -Method Get -Uri "https://management.azure.com$($ResourceId)/operations?api-version=2021-11-01").Content
$job = ($operations | ConvertFrom-Json).value.properties | ?{$_.operation -eq "UpsertManagedServer" -and $_.state -eq "InProgress"}
$startTime = $job.startTime
[string]$updateUri = $updated.Headers.GetValues("Azure-AsyncOperation")

$currentStep = 1
$notifiedStep = 1
while($job.state -eq "InProgress")
{
    sleep 120
    $operations = (Invoke-AzRestMethod -Method Get -Uri "https://management.azure.com$($ResourceId)/operations?api-version=2021-11-01").Content
    $job = ($operations | ConvertFrom-Json).value.properties | ?{$_.startTime -eq $startTime}
    $currentStep = $job.operationSteps.currentStep
    if($currentStep -ne $notifiedStep)
    {
        $notifiedStep = $currentStep
        Invoke-RestMethod -Method Post -Uri $sendNotificationUri -Body $($noticiationBody -f "false",$new.name, $originalCores, $numberOfCores, "Starting Step $($currentStep)","step $($currentStep - 1)",$failed) -ContentType "application/json"
    }
}

$managedInstance = (Invoke-AzRestMethod -Method Get -Uri "https://management.azure.com$($ResourceId)?api-version=2021-11-01").Content | Convert-FromJson -Depth 100

if($managedInstance.properties.vCores -ne $numberOfCores)
{
    $failed = "true"
}

Invoke-RestMethod -Method Post -Uri $sendNotificationUri -Body $($noticiationBody -f "false",$ManagedInstanceName, $managedInstance.VCores, $numberOfCores,"Complete","all steps",$failed) -ContentType "application/json"