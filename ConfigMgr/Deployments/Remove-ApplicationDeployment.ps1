#========================================================================
# Created on:   2013-09-13 16:43
# Created by:   Nickolaj Andersen
# Filename:     Remove-ApplicationDeployment.ps1
#========================================================================

param(
[parameter(Mandatory=$true)]
$SiteServer,
[parameter(Mandatory=$true)]
$SiteCode,
[parameter(Mandatory=$true)]
$ApplicationName
)

if (Get-WmiObject -Namespace "root\sms\site_$($SiteCode)" -Class "SMS_Application" -ComputerName $SiteServer -ErrorAction SilentlyContinue | Where-Object { $_.LocalizedDisplayName -like "$($ApplicationName)"}) {
	$Deployment = (Get-WmiObject -Namespace "root\sms\site_$($SiteCode)" -Class "SMS_ApplicationAssignment" -ComputerName $SiteServer | Where-Object { $_.ApplicationName -like "$($ApplicationName)"}).__PATH
	$i = 0
	if (($Deployment -eq $null) -or ($Deployment -eq "")) {
		Write-Warning "No deployments was found for application $($ApplicationName)"
	}
	else {
		$Deployment | ForEach-Object {
		$i++
        Write-Output ""
		Write-Output "Deleting deployment $($i) of $($Deployment.Count): $($_)`n"
		Remove-WmiObject -InputObject $_ | Out-Null
        Write-Output "Successfully deleted $($i) deployments for $($ApplicationName)`n"
		}
	}
}
else {
	Write-Warning "Application '$($ApplicationName)' was not found"
}