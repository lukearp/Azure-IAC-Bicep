
<#
.SYNOPSIS
	v0.1.22
.DESCRIPTION
	# //todo add stuff from https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help?view=powershell-5.1
#>
[CmdletBinding(SupportsShouldProcess)]
param(
	[Parameter(mandatory = $false)]
	$WebHookData,

	# Note: optional for simulating user sessions
	[System.Nullable[int]]$OverrideNUserSessions
)
try {
	#region set err action preference, extract & validate input rqt params, set exec policies, set TLS 1.2 security protocol

	# Setting ErrorActionPreference to stop script execution when error occurs
	$ErrorActionPreference = 'Stop'
	$WebHookData = [PSCustomObject]$WebHookData

	function Get-PSObjectPropVal {
		param (
			[PSCustomObject]$Obj,
			[string]$Key,
			$DefaultVal = $null
		)
		$Prop = $Obj.PSObject.Properties[$Key]
		if ($Prop) {
			return $Prop.Value
		}
		return $DefaultVal
	}

	# If runbook was called from Webhook, WebhookData and its RequestBody will not be null
	if (!$WebHookData -or [string]::IsNullOrWhiteSpace((Get-PSObjectPropVal -Obj $WebHookData -Key 'RequestBody'))) {
		throw 'Runbook was not started from Webhook (WebHookData or its RequestBody is empty)'
	}

	# Collect Input converted from JSON request body of Webhook
	$RqtParams = ConvertFrom-Json -InputObject $WebHookData.RequestBody

	if (!$RqtParams) {
		throw 'RequestBody of WebHookData is empty'
	}

	[string[]]$RequiredStrParams = @(
		'ResourceGroupName'
		'HostPoolName'
		'TimeZoneId'
		'BeginPeakTime'
		'EndPeakTime'
		'LogOffMessageTitle'
		'LogOffMessageBody'
	)
	[string[]]$RequiredParams = @('SessionThresholdPerCPU', 'MinimumNumberOfRDSH', 'LimitSecondsToForceLogOffUser')
	[string[]]$InvalidParams = @($RequiredStrParams | Where-Object { [string]::IsNullOrWhiteSpace((Get-PSObjectPropVal -Obj $RqtParams -Key $_)) })
	[string[]]$InvalidParams += @($RequiredParams | Where-Object { $null -eq (Get-PSObjectPropVal -Obj $RqtParams -Key $_) })

	if ($InvalidParams) {
		throw "Invalid values for the following $($InvalidParams.Count) params: $($InvalidParams -join ', ')"
	}
	
	[string]$LogAnalyticsWorkspaceId = Get-PSObjectPropVal -Obj $RqtParams -Key 'LogAnalyticsWorkspaceId'
	[string]$LogAnalyticsPrimaryKey = Get-PSObjectPropVal -Obj $RqtParams -Key 'LogAnalyticsPrimaryKey'
	#[string]$ConnectionAssetName = Get-PSObjectPropVal -Obj $RqtParams -Key 'ConnectionAssetName'
	[string]$WVDConnectionAssetName = Get-PSObjectPropVal -Obj $RqtParams -Key 'WVDConnectionAssetName'
	[string]$ResourceGroupName = $RqtParams.ResourceGroupName
	[string]$HostPoolName = $RqtParams.HostPoolName
	[string]$MaintenanceTagName = Get-PSObjectPropVal -Obj $RqtParams -Key 'MaintenanceTagName'
	[string]$TimeZoneId = $RqtParams.TimeZoneId
	[string]$BeginPeakTime = $RqtParams.BeginPeakTime
	[int]$FullPeakHrOffset = $RqtParams.FullPeakHrOffset
	[int]$UserOffset = $RqtParams.UserOffset
	[int]$RampDownOffSet = $RqtParams.RampDownOffSet
	[string]$EndPeakTime = $RqtParams.EndPeakTime
	[double]$SessionThresholdPerCPU = $RqtParams.SessionThresholdPerCPU
	[int]$MinRunningVMs = $RqtParams.MinimumNumberOfRDSH
	[int]$LimitSecondsToForceLogOffUser = $RqtParams.LimitSecondsToForceLogOffUser
	[string]$LogOffMessageTitle = $RqtParams.LogOffMessageTitle
	[string]$LogOffMessageBody = $RqtParams.LogOffMessageBody

	# Note: if this is enabled, the script will assume that all the authentication is already done in current or parent scope before calling this script
	[bool]$SkipAuth = $false
	[bool]$SkipUpdateLoadBalancerType = !!(Get-PSObjectPropVal -Obj $RqtParams -Key 'SkipUpdateLoadBalancerType')

	if ([string]::IsNullOrWhiteSpace($ConnectionAssetName)) {
		$ConnectionAssetName = 'AzureRunAsConnection'
	}

	[int]$StatusCheckTimeOut = 60 * 60 # 1 hr
	[int]$SessionHostStatusCheckSleepSecs = 30
	[string[]]$DesiredRunningStates = @('Available', 'NeedsAssistance')
	# Note: time diff can be '#' or '#:#', so it is appended with ':0' in case its just '#' and so the result will have at least 2 items (hrs and min)
	[string[]]$TimeDiffHrsMin = "$($TimeDifference):0".Split(':')

	Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope Process -Force -Confirm:$false
	if (!$SkipAuth) {
		# Note: this requires admin priviledges
		Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force -Confirm:$false
	}

	# Note: https://stackoverflow.com/questions/41674518/powershell-setting-security-protocol-to-tls-1-2
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

	#endregion


	#region helper/common functions, log rqt params

	# Function to return local time converted from UTC
	function Get-LocalDateTime {
		$timezoneInfo = Get-TimeZone -Id $TimeZoneId    
		$inputDateTime = Get-Date -Date (Get-Date).ToUniversalTime() -f s
		$time = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($inputDateTime, "UTC", $timezoneInfo.StandardName)
    
		return Get-Date -Date $time # -Format "HH:mm"
	}

	function Write-Log {
		[CmdletBinding()]
		param(
			[Parameter(Mandatory = $true)]
			[string]$Message,

			[switch]$Err,

			[switch]$Warn
		)

		$MessageTimeStamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
		$Message = "[$($MyInvocation.ScriptLineNumber)] $Message"
		$WriteMessage = "$MessageTimeStamp $Message"

		if ($Err) {
			Write-Error $WriteMessage
		}
		elseif ($Warn) {
			Write-Warning $WriteMessage
		}
		else {
			Write-Output $WriteMessage
		}
			
		if (!$LogAnalyticsWorkspaceId -or !$LogAnalyticsPrimaryKey) {
			return
		}

		try {
			$body_obj = @{
				'hostpoolName' = $HostPoolName
				'logmessage'   = $Message
				'TimeStamp'    = $MessageTimeStamp
			}
			$json_body = ConvertTo-Json -Compress $body_obj
			
			$PostResult = Send-OMSAPIIngestionFile -customerId $LogAnalyticsWorkspaceId -sharedKey $LogAnalyticsPrimaryKey -Body $json_body -logType 'WVDTenantScale_CL' -TimeStampField 'TimeStamp'
			if ($PostResult -ne 'Accepted') {
				throw "Error posting to OMS: $PostResult"
			}
		}
		catch {
			Write-Warning "$MessageTimeStamp Some error occurred while logging to log analytics workspace: $($PSItem | Format-List -Force | Out-String)"
		}
	}

	# Function to wait for background jobs
	function Wait-ForJobs {
		param ([array]$Jobs = @())

		Write-Log "Wait for $($Jobs.Count) jobs"
		$StartTime = Get-Date
		while ($true) {
			if ((Get-Date).Subtract($StartTime).TotalSeconds -ge $StatusCheckTimeOut) {
				throw "Status check timed out. Taking more than $StatusCheckTimeOut seconds"
			}
			Write-Log "[Check jobs status] Total: $($Jobs.Count), $(($Jobs | Group-Object State | ForEach-Object { "$($_.Name): $($_.Count)" }) -join ', ')"
			if (!($Jobs | Where-Object { $_.State -eq 'Running' })) {
				break
			}
			Start-Sleep -Seconds 30
		}

		$IncompleteJobs = @($Jobs | Where-Object { $_.State -ne 'Completed' })
		if ($IncompleteJobs) {
			throw "$($IncompleteJobs.Count) jobs did not complete successfully: $($IncompleteJobs | Format-List -Force | Out-String)"
		}
	}

	function Update-SessionHostToAllowNewSession {
		[CmdletBinding(SupportsShouldProcess)]
		param (
			[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
			$SessionHost
		)
		Begin { }
		Process {
			if (!$SessionHost.AllowNewSession) {
				$SessionHostName = $SessionHost.Name.Split('/')[-1].ToLower()
				Write-Log "Update session host '$($SessionHostName)' to allow new sessions"
				if ($PSCmdlet.ShouldProcess($SessionHostName, 'Update session host to allow new sessions')) {
					Update-AzWvdSessionHost -HostPoolName $HostPoolName -ResourceGroupName $ResourceGroupName -Name $SessionHostName -AllowNewSession:$true | Write-Verbose
				}
			}
		}
		End { }
	}

	Write-Log "Request params: $($RqtParams | Format-List -Force | Out-String)"

	if ($LogAnalyticsWorkspaceId -and $LogAnalyticsPrimaryKey) {
		Write-Log "Log ananlytics is enabled"
	}

	#endregion


	#region azure auth, ctx

	# Azure auth
	$AzContext = $null
	if (!$SkipAuth) {
		# Collect the credentials from Azure Automation Account Assets
		Write-Log "Get auto connection from asset: $($WVDConnectionAssetName)"
		#$Connection = Get-AutomationConnection -Name $ConnectionAssetName
		$WVDConnection = Get-AutomationConnection -Name $WVDConnectionAssetName
		$Connection = New-Object -TypeName psobject -Property @{
			TenantId       = "bedd5d6f-bcfc-46d4-918d-7fb210e57897"
			SubscriptionId = "cfaf9ba2-223d-42e6-ac55-03daf3f7cd87"
		}
		#try {
		#$AzAuth = Connect-AzAccount -Identity #-SubscriptionId cfaf9ba2-223d-42e6-ac55-03daf3f7cd87 # -ApplicationId $Connection.ApplicationId -CertificateThumbprint $Connection.CertificateThumbprint -TenantId $Connection.TenantId -SubscriptionId $Connection.SubscriptionId -ServicePrincipal
		#Connect-AzAccount -ApplicationId $WVDConnection.ApplicationId -CertificateThumbprint $WVDConnection.CertificateThumbprint -TenantId $WVDConnection.TenantId -SubscriptionId $WVDConnection.SubscriptionId -ServicePrincipal
		$WvdAuth = Connect-AzAccount -ApplicationId "5fa8b6bd-3a2e-4013-be2f-4b75c9bfa2c8" -CertificateThumbprint "6CA6FE92B16EA690BA51770AA17007DBACD6D9A1" -TenantId "f1b15770-c72f-44d1-ac7f-e65ecb4d0c54" -SubscriptionId "6fb24f41-2cb9-4242-861c-413a3775d97b" -ServicePrincipal
			
		$AzContext = $WvdAuth.Context
		Write-Log "$($AzContext)" 
		$WvdContext = (Connect-AzAccount -Identity).context
		Write-Log "$($WvdContext)"
		#}
		#catch {
		#throw [System.Exception]::new("Failed to authenticate Azure with application ID: '$($Connection.ApplicationId)', tenant ID: '$($Connection.TenantId)', subscription ID: '$($Connection.SubscriptionId)'", $PSItem.Exception)
		#}
		#	Write-Log "Successfully authenticated with Azure using service principal: $($AzContext | Format-List -Force | Out-String)"
	}
	else {
		$AzContext = Get-AzContext
	}

	#Set Azure context with subscription, tenant
	#if ($WvdContext.Tenant.Id -ne $Connection.TenantId -or $AzContext.Subscription.Id -ne $Connection.SubscriptionId) {
	#if ($PSCmdlet.ShouldProcess((@($Connection.TenantId, $Connection.SubscriptionId) -join ', '), 'Set Azure context with tenant ID, subscription ID')) {
	#try {
	#$WvdContext = Set-AzContext -TenantId $Connection.TenantId -SubscriptionId $Connection.SubscriptionId
	#if (!$WvdContext -or $WvdContext.Tenant.Id -ne $Connection.TenantId -or $AzContext.Subscription.Id -ne $Connection.SubscriptionId) {
	#	throw $WvdContext
	#}
	#}
	#catch {
	#throw [System.Exception]::new("Failed to set Azure context with tenant ID: '$($Connection.TenantId)', subscription ID: '$($Connection.SubscriptionId)'", $PSItem.Exception)
	#}
	#Write-Log "Successfully set the Azure context with the tenant ID, subscription ID: $($AzContext | Format-List -Force | Out-String)"
	#}
	#}

	#endregion


	#region validate host pool, validate / update HostPool load balancer type, ensure there is at least 1 session host, get num of user sessions

	# Validate and get HostPool info
	$HostPool = $null
	Set-AzContext -Context $WvdContext
	try {
		Write-Log "Get Hostpool info of '$HostPoolName' in resource group '$ResourceGroupName'"
		$HostPool = Get-AzWvdHostPool -Name $HostPoolName -ResourceGroupName $ResourceGroupName
		if (!$HostPool) {
			throw $HostPool
		}
	}
	catch {
		throw [System.Exception]::new("Failed to get Hostpool info of '$HostPoolName' in resource group '$ResourceGroupName'. Ensure that you have entered the correct values", $PSItem.Exception)
	}

	# Ensure HostPool load balancer type is not persistent
	if ($HostPool.LoadBalancerType -eq 'Persistent') {
		throw "HostPool '$HostPoolName' is configured with 'Persistent' load balancer type. Scaling tool only supports these load balancer types: BreadthFirst, DepthFirst"
	}

	Write-Log 'Get all session hosts'
	$SessionHosts = @(Get-AzWvdSessionHost -HostPoolName $HostPoolName -ResourceGroupName $ResourceGroupName)
	if (!$SessionHosts) {
		Write-Log "There are no session hosts in the Hostpool '$HostPoolName'. Ensure that hostpool has session hosts"
		Write-Log 'End'
		return
	}

	Write-Log 'Get number of user sessions in Hostpool'
	[int]$nUserSessions = @(Get-AzWvdUserSession -HostPoolName $HostPoolName -ResourceGroupName $ResourceGroupName).Count

	# Set up breadth 1st load balacing type
	# Note: breadth 1st is enforced on AND off peak hours to simplify the things with scaling in the start/end of peak hours
	<#
	if (!$SkipUpdateLoadBalancerType -and $HostPool.LoadBalancerType -ne 'BreadthFirst') {
		Write-Log "Update HostPool with 'BreadthFirst' load balancer type (current: '$($HostPool.LoadBalancerType)')"
		if ($PSCmdlet.ShouldProcess($HostPoolName, "Update HostPool with BreadthFirstLoadBalancer type (current: '$($HostPool.LoadBalancerType)')")) {
			$HostPool = Update-AzWvdHostPool -Name $HostPoolName -ResourceGroupName $ResourceGroupName -LoadBalancerType 'BreadthFirst'
		}
	}
	#>
	Write-Log "HostPool info: $($HostPool | Format-List -Force | Out-String)"
	Write-Log "Number of session hosts in the HostPool: $($SessionHosts.Count)"

	#endregion
	

	#region determine if on/off peak hours

	# Convert local time, begin peak time & end peak time from UTC to local time
	$CurrentDateTime = Get-LocalDateTime
	$BeginPeakDateTime = [datetime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $BeginPeakTime)
	$FullPeakDateTime = [datetime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $BeginPeakTime).AddHours($FullPeakHrOffset)
	$RampDownDateTime = [datetime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $EndPeakTime).AddHours($(-1 * $RampDownOffSet))
	$EndPeakDateTime = [datetime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $EndPeakTime)
	$fullPeak = $false
	$peak = $false
	$rampDown = $false
	$offPeak = $false
	# Adjust peak times to make sure begin peak time is always before end peak time
	if ($EndPeakDateTime -lt $BeginPeakDateTime) {
		if ($CurrentDateTime -lt $EndPeakDateTime) {
			$BeginPeakDateTime = $BeginPeakDateTime.AddDays(-1)
		}
		else {
			$EndPeakDateTime = $EndPeakDateTime.AddDays(1)
		}
	}

	Write-Log "Using current time: $($CurrentDateTime.ToString('yyyy-MM-dd HH:mm:ss')), begin peak time: $($BeginPeakDateTime.ToString('yyyy-MM-dd HH:mm:ss')), end peak time: $($EndPeakDateTime.ToString('yyyy-MM-dd HH:mm:ss'))"
	if ($BeginPeakDateTime -le $CurrentDateTime -and $CurrentDateTime -le $FullPeakDateTime) {
		Write-Log "In full peek hours"
		$fullPeak = $true
		$peak = $false
		$offPeak = $false
		$rampDown = $false
	}
	elseif ($RampDownDateTime -le $CurrentDateTime -and $CurrentDateTime -le $EndPeakDateTime) {
		Write-Log "In Ramp Down"
		$fullPeak = $false
		$peak = $false
		$offPeak = $false
		$rampDown = $true
	}
	elseif ($BeginPeakDateTime -le $CurrentDateTime -and $CurrentDateTime -le $EndPeakDateTime) {
		Write-Log "In peak hours"
		$fullPeak = $false
		$peak = $true
		$offPeak = $false
		$rampDown = $false
	}
	else {
		Write-Log "Off peak hours"
		$fullPeak = $false
		$peak = $false
		$offPeak = $true
		$rampDown = $false
	}

	#endregion


	#region get all session hosts, VMs & user sessions info and compute workload

	# Number of session hosts that are running
	[int]$nRunningVMs = 0
	# Number of cores that are running
	[int]$nRunningCores = 0
	[int]$totalCores = 0
	# Object that contains all session host objects, VM instance objects except the ones that are under maintenance
	$VMs = @{ }
	# Object that contains the number of cores for each VM size SKU
	$VMSizeCores = @{ }
	# Number of cores to start
	[int]$nCoresToStart = 0
	# Number of VMs to start
	[int]$nVMsToStart = 0
	# Number of user sessions reported by each session host that is running
	[int]$nUserSessionsFromAllRunningVMs = 0

	# Popoluate all session hosts objects
	foreach ($SessionHost in $SessionHosts) {
		$SessionHostName = $SessionHost.Name.Split('/')[-1].ToLower()
		$VMs.Add($SessionHostName.Split('.')[0], @{ 'SessionHostName' = $SessionHostName; 'SessionHost' = $SessionHost; 'Instance' = $null })
	}
	Set-AzContext -Context $AzContext
	Write-Log 'Get all VMs, check session host status and get usage info'
	foreach ($VMInstance in (Get-AzVM -Status)) {
		if (!$VMs.ContainsKey($VMInstance.Name.ToLower())) {
			# This VM is not a WVD session host
			continue
		}
		$VMName = $VMInstance.Name.ToLower()
		if ($VMInstance.Tags.Keys -contains $MaintenanceTagName) {
			Write-Log "VM '$VMName' is in maintenance and will be ignored"
			$VMs.Remove($VMName)
			continue
		}

		$VM = $VMs[$VMName]
		$SessionHost = $VM.SessionHost
		if ($VM.Instance) {
			throw "More than 1 VM found in Azure with same session host name '$($VM.SessionHostName)' (This is not supported): $($VMInstance | Format-List -Force | Out-String)$($VM.Instance | Format-List -Force | Out-String)"
		}

		$VM.Instance = $VMInstance

		Write-Log "Session host: '$($VM.SessionHostName)', power state: '$($VMInstance.PowerState)', status: '$($SessionHost.Status)', update state: '$($SessionHost.UpdateState)', sessions: $($SessionHost.Session), allow new session: $($SessionHost.AllowNewSession)"
		# Check if we know how many cores are in this VM
		if (!$VMSizeCores.ContainsKey($VMInstance.HardwareProfile.VmSize)) {
			Write-Log "Get all VM sizes in location: $($VMInstance.Location)"
			foreach ($VMSize in (Get-AzVMSize -Location $VMInstance.Location)) {
				$VMSizeCores.Add($VMSize.Name, $VMSize.NumberOfCores)
			}
		}

		if ($VMInstance.PowerState -eq 'VM running') {
			if ($SessionHost.Status -notin $DesiredRunningStates) {
				Write-Log -Warn 'VM is in running state but session host is not (this could be because the VM was just started and has not connected to broker yet)'
			}

			++$nRunningVMs
			$nRunningCores += $VMSizeCores[$VMInstance.HardwareProfile.VmSize]
			$nUserSessionsFromAllRunningVMs += $SessionHost.Session
		}
		else {
			if ($SessionHost.Status -in $DesiredRunningStates) {
				Write-Log -Warn "VM is not in running state but session host is (this could be because the VM was just stopped and broker doesn't know that yet)"
			}
		}
		$totalCores += $VMSizeCores[$VMInstance.HardwareProfile.VmSize]
	}

	if ($nUserSessionsFromAllRunningVMs -ne $nUserSessions) {
		Write-Log -Warn "Sum of user sessions reported by every running session host ($nUserSessionsFromAllRunningVMs) is not equal to the total number of user sessions reported by the host pool ($nUserSessions)"
	}

	$nUserSessions = $nUserSessionsFromAllRunningVMs
	# Check if we need to override the number of user sessions for simulation / testing purpose
	if ($null -ne $OverrideNUserSessions) {
		$nUserSessions = $OverrideNUserSessions
	}

	# Make sure VM instance was found in Azure for every session host
	$nVMsWithoutInstance = @($VMs.Values | Where-Object { !$_.Instance }).Count
	if ($nVMsWithoutInstance) {
		throw "There are $nVMsWithoutInstance session hosts whose VM instance was not found in Azure"
	}

	# Calculate available capacity of sessions on running VMs
	$SessionThresholdCapacity = $nRunningCores * $SessionThresholdPerCPU

	Write-Log "Number of running session hosts: $nRunningVMs of total $($VMs.Count)"
	Write-Log "Number of user sessions: $nUserSessions, total threshold capacity: $SessionThresholdCapacity"

	#endregion


	#region determine number of session hosts to start if any

	# Now that we have all the info about the session hosts & their usage, figure how many session hosts to start/stop depending on in/off peak hours and the demand
	if ($fullPeak) {
		$nCoresToStart = $totalCores
		if ($HostPool.LoadBalancerType -ne 'DepthFirst') {
			$HostPool = Update-AzWvdHostPool -Name $HostPoolName -ResourceGroupName $ResourceGroupName -LoadBalancerType 'DepthFirst'
		}
	}
	elseif ($peak) {
		# In peak hours: check if current capacity is meeting the user demands
		if ($nUserSessions -gt $SessionThresholdCapacity) {
			$nCoresToStart = [math]::Ceiling((($nUserSessions + $userOffset) - $SessionThresholdCapacity) / $SessionThresholdPerCPU)
			Write-Log "[In peak hours] Number of user sessions is more than the threshold capacity. Need to start $nCoresToStart cores"
		}
		elseif ($nUserSessions -lt $SessionThresholdCapacity) {
			[double]$MaxSessionsThreshold = 0.9
			[int]$MaxSessionsThresholdCapacity = [math]::Floor($MinRunningVMs * $HostPool.MaxSessionLimit * $MaxSessionsThreshold)
			if ($nUserSessions -ge $MaxSessionsThresholdCapacity) {
				$MinRunningVMs = [math]::Ceiling(($nUserSessions + $userOffset) / ($HostPool.MaxSessionLimit * $MaxSessionsThreshold))
				Write-Log "[Peak] Number of user sessions is more than $($MaxSessionsThreshold * 100) % of the max number of sessions allowed with minimum number of session hosts ($MaxSessionsThresholdCapacity). Adjusting minimum number of session hosts required to $MinRunningVMs"
			}
		}
		if ($HostPool.LoadBalancerType -eq 'DepthFirst') {
			$HostPool = Update-AzWvdHostPool -Name $HostPoolName -ResourceGroupName $ResourceGroupName -LoadBalancerType 'BreadthFirst'
		}
		[double]$MaxSessionsThreshold = 0.9
		$MinRunningVMs = [math]::Ceiling(($nUserSessions + $userOffset) / ($HostPool.MaxSessionLimit * $MaxSessionsThreshold))
	}
	elseif ($rampDown) {
		#Logoff all users mpDown
		if ($HostPool.LoadBalancerType -ne 'DepthFirst') {
			[double]$MaxSessionsThreshold = 0.9
			[int]$MaxSessionsThresholdCapacity = [math]::Floor($MinRunningVMs * $HostPool.MaxSessionLimit * $MaxSessionsThreshold)
			if ($nUserSessions -ge $MaxSessionsThresholdCapacity) {
				$MinRunningVMs = [math]::Ceiling(($nUserSessions + $userOffset) / ($HostPool.MaxSessionLimit * $MaxSessionsThreshold))
				Write-Log "[Ramp-Down] Number of user sessions is more than $($MaxSessionsThreshold * 100) % of the max number of sessions allowed with minimum number of session hosts ($MaxSessionsThresholdCapacity). Adjusting minimum number of session hosts required to $MinRunningVMs"
			}
			$HostPool = Update-AzWvdHostPool -Name $HostPoolName -ResourceGroupName $ResourceGroupName -LoadBalancerType 'DepthFirst'
		}
	}
	else {
		# Off peak hours: check if need to adjust minimum number of session hosts running if the number of user sessions is close to the max allowed
		[double]$MaxSessionsThreshold = 0.9
		[int]$MaxSessionsThresholdCapacity = [math]::Floor($MinRunningVMs * $HostPool.MaxSessionLimit * $MaxSessionsThreshold)
		if ($nUserSessions -ge $MaxSessionsThresholdCapacity) {
			$MinRunningVMs = [math]::Ceiling(($nUserSessions + $userOffset) / ($HostPool.MaxSessionLimit * $MaxSessionsThreshold))
			Write-Log "[Off peak hours] Number of user sessions is more than $($MaxSessionsThreshold * 100) % of the max number of sessions allowed with minimum number of session hosts ($MaxSessionsThresholdCapacity). Adjusting minimum number of session hosts required to $MinRunningVMs"
		}
		if ($HostPool.LoadBalancerType -ne 'DepthFirst') {
			$HostPool = Update-AzWvdHostPool -Name $HostPoolName -ResourceGroupName $ResourceGroupName -LoadBalancerType 'DepthFirst'
		}
	}

	Write-Log "Minimum number of session hosts required: $MinRunningVMs"
	# Check if minimum number of session hosts running is higher than max allowed
	if ($VMs.Count -le $MinRunningVMs) {
		Write-Log -Warn 'Minimum number of RDSH is set higher than total number of session hosts'
		if ($nRunningVMs -eq $VMs.Count) {
			Write-Log 'All session hosts are running'
			Write-Log 'End'
			return
		}
	}

	# Check if minimum number of session hosts are running
	if ($nRunningVMs -lt $MinRunningVMs) {
		$nVMsToStart = $MinRunningVMs - $nRunningVMs
		Write-Log "Number of running session host is less than minimum required. Need to start $nVMsToStart VMs"
	}

	#endregion


	#region start any session hosts if need to

	# Check if we have any session hosts to start
	if ($nVMsToStart -or $nCoresToStart) {
		# Object that contains names of session hosts that will be started
		$StartSessionHostFullNames = @{ }
		# Array that contains jobs of starting the session hosts
		[array]$StartVMjobs = @()

		Write-Log 'Find session hosts that are stopped and healthy'
		foreach ($VM in $VMs.Values) {
			if (!$nVMsToStart -and !$nCoresToStart) {
				# Done with starting session hosts that needed to be
				break
			}
			if ($VM.Instance.PowerState -eq 'VM running') {
				continue
			}
			if ($VM.SessionHost.UpdateState -ne 'Succeeded') {
				Write-Log -Warn "Session host '$($VM.SessionHostName)' is not healthy to start"
				continue
			}

			# Make sure session host is allowing new user sessions
			Set-AzContext -Context $WvdContext
			Update-SessionHostToAllowNewSession -SessionHost $VM.SessionHost

			Write-Log "Start session host '$($VM.SessionHostName)' as a background job"
			if ($PSCmdlet.ShouldProcess($VM.SessionHostName, 'Start session host as a background job')) {
				Set-AzContext -Context $AzContext
				$StartSessionHostFullNames.Add($VM.SessionHost.Name, $null)
				$StartVMjobs += ($VM.Instance | Start-AzVM -AsJob)
			}

			--$nVMsToStart
			if ($nVMsToStart -lt 0) {
				$nVMsToStart = 0
			}
			$nCoresToStart -= $VMSizeCores[$VM.Instance.HardwareProfile.VmSize]
			if ($nCoresToStart -lt 0) {
				$nCoresToStart = 0
			}
		}

		# Check if there were enough number of session hosts to start
		if ($nVMsToStart -or $nCoresToStart) {
			Write-Log -Warn "Not enough session hosts to start. Still need to start maximum of either $nVMsToStart VMs or $nCoresToStart cores"
		}

		# Wait for those jobs to start the session hosts
		Wait-ForJobs $StartVMjobs

		Write-Log 'All jobs completed'
		Write-Log 'End'
		return

		# //todo if not going to poll for status here, then no need to keep track of the list of session hosts that were started
		Write-Log "Wait for $($StartSessionHostFullNames.Count) session hosts to be available"
		$StartTime = Get-Date
		while ($true) {
			if ((Get-Date).Subtract($StartTime).TotalSeconds -ge $StatusCheckTimeOut) {
				throw "Status check timed out. Taking more than $StatusCheckTimeOut seconds"
			}
			Set-AzContext -Context $WvdContext
			$SessionHostsToCheck = @(Get-AzWvdSessionHost -HostPoolName $HostPoolName -ResourceGroupName $ResourceGroupName | Where-Object { $StartSessionHostFullNames.ContainsKey($_.Name) })
			Write-Log "[Check session hosts status] Total: $($SessionHostsToCheck.Count), $(($SessionHostsToCheck | Group-Object Status | ForEach-Object { "$($_.Name): $($_.Count)" }) -join ', ')"
			if (!($SessionHostsToCheck | Where-Object { $_.Status -notin $DesiredRunningStates })) {
				break
			}
			Start-Sleep -Seconds $SessionHostStatusCheckSleepSecs
		}
		return
	}

	#endregion


	#region determine number of session hosts to stop if any

	# If in peak hours, exit because no session hosts will need to be stopped
	if ($fullPeak) {
		Write-Log '[In full peak hours] no need to start any session hosts'
		Write-Log 'End'
		return
	}

	# Off peak hours, already running minimum number of session hosts, exit
	if ($nRunningVMs -le $MinRunningVMs) {
		Write-Log 'No need to start/stop any session hosts'
		Write-Log 'End'
		return
	}
	
	# Calculate the number of session hosts to stop
	[int]$nVMsToStop = $nRunningVMs - $MinRunningVMs
	Write-Log "Number of running session host is greater than minimum required. Need to stop $nVMsToStop VMs"

	#endregion


	#region stop any session hosts if need to

	# Object that contains names of session hosts that will be stopped
	$StopSessionHostFullNames = @{ }
	# Array that contains jobs of stopping the session hosts
	[array]$StopVMjobs = @()
	[array]$VMsToStopAfterLogOffTimeOut = @()

	Write-Log 'Find session hosts that are running, sort them by number of user sessions'
	if ($peak) {
		foreach ($VM in ($VMs.Values | Where-Object { $_.Instance.PowerState -eq 'VM running' -and $_.SessionHost.Session -eq 0 })) {
			if (!$nVMsToStop) {
				# Done with stopping session hosts that needed to be
				break
			}
			$SessionHost = $VM.SessionHost
			$SessionHostName = $VM.SessionHostName
			
			if ($SessionHost.Session -and !$LimitSecondsToForceLogOffUser) {
				Write-Log -Warn "Session host '$SessionHostName' has $($SessionHost.Session) sessions but limit seconds to force log off user is set to 0, so will not stop any more session hosts (https://aka.ms/wvdscale#how-the-scaling-tool-works)"
				# Note: why break ? Because the list this loop iterates through is sorted by number of sessions, if it hits this, the rest of items in the loop will also hit this
				break
			}
			
			Set-AzContext -Context $WvdContext
			if ($SessionHost.AllowNewSession) {
				Write-Log "Session host '$SessionHostName' has $($SessionHost.Session) sessions. Set it to disallow new sessions"
				if ($PSCmdlet.ShouldProcess($SessionHostName, 'Set session host to disallow new sessions')) {
					try {
						$VM.SessionHost = $SessionHost = Update-AzWvdSessionHost -HostPoolName $HostPoolName -ResourceGroupName $ResourceGroupName -Name $SessionHostName -AllowNewSession:$false
					}
					catch {
						throw [System.Exception]::new("Failed to set it to disallow new sessions on session host: '$SessionHostName'", $PSItem.Exception)
					}
	
					if ($SessionHost.Session -and !$LimitSecondsToForceLogOffUser) {
						Write-Log -Warn "Session host '$SessionHostName' has $($SessionHost.Session) sessions but limit seconds to force log off user is set to 0, so will not stop any more session hosts (https://aka.ms/wvdscale#how-the-scaling-tool-works)"
						Update-SessionHostToAllowNewSession -SessionHost $SessionHost
						continue
					}
				}
			}
	
			if ($SessionHost.Session) {
				[array]$VM.UserSessions = @()
				Write-Log "Get all user sessions from session host '$SessionHostName'"
				try {
					$VM.UserSessions = @(Get-AzWvdUserSession -HostPoolName $HostPoolName -ResourceGroupName $ResourceGroupName -SessionHostName $SessionHostName)
				}
				catch {
					throw [System.Exception]::new("Failed to retrieve user sessions of session host: '$SessionHostName'", $PSItem.Exception)
				}
	
				Write-Log "Send log off message to active user sessions on session host: '$SessionHostName'"
				foreach ($Session in $VM.UserSessions) {
					if ($Session.SessionState -ne "Active") {
						continue
					}
					$SessionID = $Session.Name.Split('/')[-1]
					try {
						Write-Log "Send a log off message to user: '$($Session.ActiveDirectoryUserName)', session ID: $SessionID"
						if ($PSCmdlet.ShouldProcess($Session.ActiveDirectoryUserName, 'Send a log off message to user')) {
							# //todo what if user logged off by this time
							Send-AzWvdUserSessionMessage -HostPoolName $HostPoolName -ResourceGroupName $ResourceGroupName -SessionHostName $SessionHostName -UserSessionId $SessionID -MessageTitle $LogOffMessageTitle -MessageBody "$LogOffMessageBody You will be logged off in $LimitSecondsToForceLogOffUser seconds"
						}
					}
					catch {
						throw [System.Exception]::new("Failed to send a log off message to user: '$($Session.ActiveDirectoryUserName)', session ID: $SessionID", $PSItem.Exception)
					}
				}
				$VMsToStopAfterLogOffTimeOut += $VM
			}
			else {
				Set-AzContext -Context $AzContext
				Write-Log "Stop session host '$SessionHostName' as a background job"
				if ($PSCmdlet.ShouldProcess($SessionHostName, 'Stop session host as a background job')) {
					$StopSessionHostFullNames.Add($SessionHost.Name, $null)
					$StopVMjobs += ($VM.Instance | Stop-AzVM -Force -AsJob)
				}
			}
	
			--$nVMsToStop
			if ($nVMsToStop -lt 0) {
				$nVMsToStop = 0
			}
		}
	}
	else {
		foreach ($VM in ($VMs.Values | Where-Object { $_.Instance.PowerState -eq 'VM running' } | Sort-Object { $_.SessionHost.Session })) {
			if (!$nVMsToStop) {
				# Done with stopping session hosts that needed to be
				break
			}
			$SessionHost = $VM.SessionHost
			$SessionHostName = $VM.SessionHostName
		
			if ($SessionHost.Session -and !$LimitSecondsToForceLogOffUser) {
				Write-Log -Warn "Session host '$SessionHostName' has $($SessionHost.Session) sessions but limit seconds to force log off user is set to 0, so will not stop any more session hosts (https://aka.ms/wvdscale#how-the-scaling-tool-works)"
				# Note: why break ? Because the list this loop iterates through is sorted by number of sessions, if it hits this, the rest of items in the loop will also hit this
				break
			}
		
			Set-AzContext -Context $WvdContext
			if ($SessionHost.AllowNewSession) {
				Write-Log "Session host '$SessionHostName' has $($SessionHost.Session) sessions. Set it to disallow new sessions"
				if ($PSCmdlet.ShouldProcess($SessionHostName, 'Set session host to disallow new sessions')) {
					try {
						$VM.SessionHost = $SessionHost = Update-AzWvdSessionHost -HostPoolName $HostPoolName -ResourceGroupName $ResourceGroupName -Name $SessionHostName -AllowNewSession:$false
					}
					catch {
						throw [System.Exception]::new("Failed to set it to disallow new sessions on session host: '$SessionHostName'", $PSItem.Exception)
					}

					if ($SessionHost.Session -and !$LimitSecondsToForceLogOffUser) {
						Write-Log -Warn "Session host '$SessionHostName' has $($SessionHost.Session) sessions but limit seconds to force log off user is set to 0, so will not stop any more session hosts (https://aka.ms/wvdscale#how-the-scaling-tool-works)"
						Update-SessionHostToAllowNewSession -SessionHost $SessionHost
						continue
					}
				}
			}

			if ($SessionHost.Session) {
				[array]$VM.UserSessions = @()
				Write-Log "Get all user sessions from session host '$SessionHostName'"
				try {
					$VM.UserSessions = @(Get-AzWvdUserSession -HostPoolName $HostPoolName -ResourceGroupName $ResourceGroupName -SessionHostName $SessionHostName)
				}
				catch {
					throw [System.Exception]::new("Failed to retrieve user sessions of session host: '$SessionHostName'", $PSItem.Exception)
				}

				Write-Log "Send log off message to active user sessions on session host: '$SessionHostName'"
				foreach ($Session in $VM.UserSessions) {
					if ($Session.SessionState -ne "Active") {
						continue
					}
					$SessionID = $Session.Name.Split('/')[-1]
					try {
						Write-Log "Send a log off message to user: '$($Session.ActiveDirectoryUserName)', session ID: $SessionID"
						if ($PSCmdlet.ShouldProcess($Session.ActiveDirectoryUserName, 'Send a log off message to user')) {
							# //todo what if user logged off by this time
							Send-AzWvdUserSessionMessage -HostPoolName $HostPoolName -ResourceGroupName $ResourceGroupName -SessionHostName $SessionHostName -UserSessionId $SessionID -MessageTitle $LogOffMessageTitle -MessageBody "$LogOffMessageBody You will be logged off in $LimitSecondsToForceLogOffUser seconds"
						}
					}
					catch {
						throw [System.Exception]::new("Failed to send a log off message to user: '$($Session.ActiveDirectoryUserName)', session ID: $SessionID", $PSItem.Exception)
					}
				}
				$VMsToStopAfterLogOffTimeOut += $VM
			}
			else {
				Set-AzContext -Context $AzContext
				Write-Log "Stop session host '$SessionHostName' as a background job"
				if ($PSCmdlet.ShouldProcess($SessionHostName, 'Stop session host as a background job')) {
					$StopSessionHostFullNames.Add($SessionHost.Name, $null)
					$StopVMjobs += ($VM.Instance | Stop-AzVM -Force -AsJob)
				}
			}

			--$nVMsToStop
			if ($nVMsToStop -lt 0) {
				$nVMsToStop = 0
			}
		}
	}

	if ($VMsToStopAfterLogOffTimeOut) {
		Write-Log "Wait $LimitSecondsToForceLogOffUser seconds for users to log off"
		if ($PSCmdlet.ShouldProcess("for $LimitSecondsToForceLogOffUser seconds", 'Wait for users to log off')) {
			Start-Sleep -Seconds $LimitSecondsToForceLogOffUser
		}

		Write-Log "Force log off users and stop remaining $($VMsToStopAfterLogOffTimeOut.Count) session hosts"
		foreach ($VM in $VMsToStopAfterLogOffTimeOut) {
			$SessionHostName = $VM.SessionHostName

			Write-Log "Force log off $($VM.UserSessions.Count) users on session host: '$SessionHostName'"
			foreach ($Session in $VM.UserSessions) {
				$SessionID = $Session.Name.Split('/')[-1]
				try {
					Write-Log "Force log off user: '$($Session.ActiveDirectoryUserName)', session ID: $SessionID"
					if ($PSCmdlet.ShouldProcess($Session.Id, 'Force log off user with session ID')) {
						# //todo what if user logged off by this time
						Set-AzContext -Context $WvdContext
						Remove-AzWvdUserSession -HostPoolName $HostPoolName -ResourceGroupName $ResourceGroupName -SessionHostName $SessionHostName -Id $SessionID -Force
					}
				}
				catch {
					throw [System.Exception]::new("Failed to force log off user: '$($Session.ActiveDirectoryUserName)', session ID: $SessionID", $PSItem.Exception)
				}
			}
			
			Write-Log "Stop session host '$SessionHostName' as a background job"
			if ($PSCmdlet.ShouldProcess($SessionHostName, 'Stop session host as a background job')) {
				$StopSessionHostFullNames.Add($VM.SessionHost.Name, $null)
				Set-AzContext -Context $AzContext
				$StopVMjobs += ($VM.Instance | Stop-AzVM -Force -AsJob)
			}
		}
	}

	# Check if there were enough number of session hosts to stop
	if ($nVMsToStop) {
		Write-Log -Warn "Not enough session hosts to stop. Still need to stop $nVMsToStop VMs"
	}

	# Wait for those jobs to stop the session hosts
	Wait-ForJobs $StopVMjobs

	Write-Log 'All jobs completed'
	Write-Log 'End'
	return

	# //todo if not going to poll for status here, then no need to keep track of the list of session hosts that were stopped
	Write-Log "Wait for $($StopSessionHostFullNames.Count) session hosts to be unavailable"
	[array]$SessionHostsToCheck = @()
	$StartTime = Get-Date
	Set-AzContext -Context $WvdContext
	while ($true) {
		if ((Get-Date).Subtract($StartTime).TotalSeconds -ge $StatusCheckTimeOut) {
			throw "Status check timed out. Taking more than $StatusCheckTimeOut seconds"
		}
		$SessionHostsToCheck = @(Get-AzWvdSessionHost -HostPoolName $HostPoolName -ResourceGroupName $ResourceGroupName | Where-Object { $StopSessionHostFullNames.ContainsKey($_.Name) })
		Write-Log "[Check session hosts status] Total: $($SessionHostsToCheck.Count), $(($SessionHostsToCheck | Group-Object Status | ForEach-Object { "$($_.Name): $($_.Count)" }) -join ', ')"
		if (!($SessionHostsToCheck | Where-Object { $_.Status -in $DesiredRunningStates })) {
			break
		}
		Start-Sleep -Seconds $SessionHostStatusCheckSleepSecs
	}

	# Make sure session hosts are allowing new user sessions & update them to allow if not
	$SessionHostsToCheck | Update-SessionHostToAllowNewSession

	#endregion 
}
catch {
	$ErrContainer = $PSItem
	# $ErrContainer = $_

	$ErrMsg = $ErrContainer | Format-List -Force | Out-String
	if (Get-Command 'Write-Log' -ErrorAction:SilentlyContinue) {
		Write-Log -Err $ErrMsg -ErrorAction:Continue
	}
	else {
		Write-Error $ErrMsg -ErrorAction:Continue
	}

	throw
	# throw [System.Exception]::new($ErrMsg, $ErrContainer.Exception)
}