[CmdletBinding()]
param(
[parameter(Mandatory=$true)]
$SiteServer,
[parameter(Mandatory=$true)]
$SiteCode,
[parameter(Mandatory=$true)]
[int]$CreationTimeDays,
[parameter(Mandatory=$true)]
[int]$DeadlineDays,
[parameter(Mandatory=$true)]
[ValidateScript({$_.Length -eq 4})]
$DeadlineHours
)

$CurrentDate = (Get-Date).AddDays(-$CreationTimeDays).ToShortDateString()
$Deadline = ([System.Management.ManagementDateTimeConverter]::ToDmtfDateTime((Get-Date).AddDays($DeadlineDays))).Split(".").SubString(0,8)[0]
$Time = "$($DeadlineHours)00"

$ADRClientDeployment = Get-WmiObject -Namespace "root\sms\site_$($SiteCode)" -Class SMS_UpdateGroupAssignment -ComputerName $SiteServer
foreach ($Deployment in $ADRClientDeployment) {
    $CreationDate = $Deployment.ConvertToDateTime($Deployment.CreationTime).ToShortDateString()
    $DeploymentName = $Deployment.AssignmentName
    if ($CreationDate -gt $CurrentDate) {
        Write-Output "Deployment to be modified: `n$($DeploymentName)"
        try {
            $Deployment.EnforcementDeadline = "$($Deadline)$($Time).000000+***"
            $Deployment.Put() | Out-Null
            if ($?) {
                Write-Output "`nSuccessfully modified deployment`n"
            }
        }
        catch {
            Write-Output "`nERROR: $($_.Exception.Message)"
        }
    }
}