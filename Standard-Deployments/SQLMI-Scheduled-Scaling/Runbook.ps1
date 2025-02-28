param (
    [ValidateSet(4, 8, 16, 24, 32, 40, 64, 80)]
    [int]$numberOfCores
)

$ResourceId = ""
$SubscriptionId = $ResourceId.Split("/")[2]
$sendNotificationUri = ""
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
    "description": "{6}",
    "failed": {7}
}}
'@
$failed = "false"
$managedInstance = (Invoke-AzRestMethod -Method Get -Uri "https://management.azure.com$($ResourceId)?api-version=2021-11-01").Content
$new = ConvertFrom-Json -Input $managedInstance -Depth 100
$originalCores = $new.properties.vCores
Invoke-RestMethod -Method Post -Uri $sendNotificationUri -Body $($noticiationBody -f "true",$new.name, $originalCores, $numberOfCores, "Starting Step 1", "","Request validation",$failed) -ContentType "application/json"
$new.sku.capacity = $numberOfCores
$new.properties.vCores = $numberOfCores

$updated = Invoke-AzRestMethod -Method PATCH -Uri "https://management.azure.com$($ResourceId)?api-version=2021-11-01" -Payload $(ConvertTo-Json -InputObject $new -Depth 100)
$operations = (Invoke-AzRestMethod -Method Get -Uri "https://management.azure.com$($ResourceId)/operations?api-version=2021-11-01").Content
$job = ($operations | ConvertFrom-Json).value.properties | ?{$_.operation -eq "UpsertManagedServer" -and $_.state -eq "InProgress"}
$startTime = $job.startTime

$currentStep = 1
$notifiedStep = 1
while($job.state -eq "InProgress")
{
    sleep 120
    $operations = (Invoke-AzRestMethod -Method Get -Uri "https://management.azure.com$($ResourceId)/operations?api-version=2021-11-01").Content
    $job = ($operations | ConvertFrom-Json).value.properties | ?{$_.startTime -eq $startTime}
    $currentStep = ($job.operationSteps.stepsList | ?{$_.status -eq "InProgress"}).order
    if($currentStep -ne $notifiedStep -and $currentStep -ne $null)
    {
        $notifiedStep = $currentStep
        Invoke-RestMethod -Method Post -Uri $sendNotificationUri -Body $($noticiationBody -f "false",$new.name, $originalCores, $numberOfCores, "Starting Step $($currentStep)","step $($currentStep - 1)",$job.operationSteps.stepsList[$($notifiedStep - 1)].name,$failed) -ContentType "application/json"
    }
}

$managedInstance = (Invoke-AzRestMethod -Method Get -Uri "https://management.azure.com$($ResourceId)?api-version=2021-11-01").Content | ConvertFrom-Json -Depth 100

if($managedInstance.properties.vCores -ne $numberOfCores)
{
    $failed = "true"
}

Invoke-RestMethod -Method Post -Uri $sendNotificationUri -Body $($noticiationBody -f "false",$new.name, $originalCores, $numberOfCores, "Completed","all steps","Completed",$failed) -ContentType "application/json"