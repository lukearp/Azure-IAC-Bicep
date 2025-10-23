# Resource Graph, get all app services
# Backup App Plans and App Services
param($eventGridEvent, $TriggerMetadata)

$templateResourceSubscription = "456beea5-e9a5-4fde-aa3e-f136cf384213" #"25e4426f-86da-474c-bc01-effa647780b1"
$templateResourceGroup = "appservice-rg"
#$appServiceId = $(($eventGridEvent.data.resourceUri.split("/")[0..8]) -join "/")
$drRegion = "centralus"
$appServiceName = $appServiceId.split("/")[8]
$appServiceSubscription = $appServiceId.split("/")[2]
$appServiceResourceGroup = $appServiceId.split("/")[4]
$tempFile = New-TemporaryFile 
Select-AzSubscription $appServiceSubscription
Export-AzResourceGroup -ResourceGroupName $appServiceResourceGroup -Path $tempFile.FullName -Resource $appServiceId -IncludeParameterDefaultValue
$template = ConvertFrom-Json -InputObject $((Get-Content -Path "$($tempFile.FullName).json") -join "")
Select-AzSubscription -Subscription $templateResourceSubscription
$currentTemplateSpec = Get-AzTemplateSpec -ResourceGroupName $templateResourceGroup -Name $($appServiceName + "-DR-Template")
if ($null -eq $currentTemplateSpec) {
    $newTemplateSpec = New-AzTemplateSpec -ResourceGroupName $templateResourceGroup -Name $($appServiceName + "-DR-Template") -Location $drRegion -TemplateJson $(ConvertTo-Json -InputObject $template -Depth 20) -Version "1"
    if ($null -eq $newTemplateSpec) {
        throw "Failed to Update Template Spec"
    }
}
else {
    $currentMainTemplate = ConvertFrom-Json -InputObject $currentTemplateSpec.Versions[-1].MainTemplate
    if ((Compare-Object -ReferenceObject $currentMainTemplate -DifferenceObject $template) -eq $null) {
        Write-Output "No changes"
    }
    else {
        $version = $currentTemplateSpec.Versions.Count + 1
        $newTemplateSpec = New-AzTemplateSpec -ResourceGroupName $templateResourceGroup -Name $($appServiceName + "-DR-Template") -Location $drRegion -TemplateJson $(ConvertTo-Json -InputObject $template -Depth 20) -Version $version 
        if ($null -eq $newTemplateSpec) {
            throw "Failed to Update Template Spec"
        }
    }
}
