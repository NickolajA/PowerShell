<#
.SYNOPSIS
    Get Offline Servicing schedules for Operating Systems Images in ConfigMgr 2012
.DESCRIPTION
    This script will output an object for each schedule found for Operating System Images in ConfigMgr 2012
.PARAMETER SiteServer
    Site server name with SMS Provider installed
.EXAMPLE
    .\Get-CMOSImageOfflineServicingSchedule.ps1 -SiteServer CM01
.NOTES
    Script name: Get-CMOSImageOfflineServicingSchedule.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    DateCreated: 2015-11-09
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer
)
Begin {
    # Determine SiteCode from WMI
    try {
        Write-Verbose -Message "Determining SiteCode for Site Server: '$($SiteServer)'"
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
                Write-Debug -Message "SiteCode: $($SiteCode)"
            }
        }
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to determine SiteCode" ; break
    }
}
Process {
    # Functions
    function Get-ActionStatus {
        param(
            [parameter(Mandatory=$true)]
            $Action
        )
        switch ($Action) {
            0 { return "None" }
            1 { return "Install software update immediately" }
            2 { return "Cancel software update installation" }
        }
    }

    # Get Offline Servicing schedules
    $Schedules = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_ImageServicingSchedule -ComputerName $SiteServer
    foreach ($Schedule in $Schedules) {
        $TokenData = Invoke-WmiMethod -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_ScheduleMethods -Name ReadFromString "$($Schedule.Schedule)" -ComputerName $SiteServer | Select-Object -Property TokenData
        $StartTime = [System.Management.ManagementDateTimeConverter]::ToDateTime($TokenData.TokenData.StartTime)
        if ($StartTime -ge (Get-Date)) {
            $ImagePackageID = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_ImageServicingScheduledImage -ComputerName $SiteServer -Filter "ScheduleID like '$($Schedule.ScheduleID)'" | Select-Object -ExpandProperty ImagePackageID
            $ImageName = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_ImagePackage -ComputerName $SiteServer -Filter "PackageID like '$($ImagePackageID)'" | Select-Object -ExpandProperty Name
            $PSObject = [PSCustomObject]@{
                ImageName = $ImageName
                ImagePackageID = $ImagePackageID
                StartTime = $StartTime
                Action = (Get-ActionStatus -Action $Schedule.Action)
            }
            Write-Output -InputObject $PSObject
        }
    }
}

