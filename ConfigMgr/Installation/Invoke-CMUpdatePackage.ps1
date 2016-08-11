<#
.SYNOPSIS
    Start installation of a Configuration Manager Update Package (servicing model for Current Branch)

.DESCRIPTION
    This script will attempt to start the installation of a specific version of Configuration Manager Current Branch.
    If an Update Package is available for the specified version of Configuration Manager, the Update Package will be validated
    for availability before any installation is started. The script supports restarting SMS_EXECUTIVE in the event that the
    Update Package is stuck in the Downloading state. You can control the amount of availibility checks to be performed with the
    AvailibilityCheckCount parameter, before the service is restarted. Default is 120.

.PARAMETER SiteServer
    Site server name with SMS Provider installed.

.PARAMETER Version
    Specify a Configuration Manager version that should be installed. Valid format is e.g. 1602 or 1606.

.PARAMETER AvailabilityCheckCount
    Specify how many times the script will check if an UpdatePackage is available for installation.

.PARAMETER PrereqCheckCount
    Specify how many times the script will check if the prerequisite checks has completed for an UpdatePackage.

.EXAMPLE
    Attempt to start the installation of Configuration Manager 1606, on a Primary Site server called 'CM01':
    .\Invoke-CMUpdatePackage.ps1 -SiteServer CM01 -Version 1606

.NOTES
    FileName:    Invoke-CMUpdatePackage.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    Created:     2016-08-06
    Updated:     2016-08-06
    Version:     1.0.0
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,

    [parameter(Mandatory=$true, HelpMessage="Specify a Configuration Manager version that should be installed. Valid format is e.g. 1602 or 1606.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({$_.Length -eq 4})]
    [string]$Version,

    [parameter(Mandatory=$false, HelpMessage="Specify how many times the script will check if an UpdatePackage is available for installation.")]
    [ValidateNotNullOrEmpty()]
    [int]$AvailabilityCheckCount = 120,

    [parameter(Mandatory=$false, HelpMessage="Specify how many times the script will check if the prerequisite checks has completed for an UpdatePackage.")]
    [ValidateNotNullOrEmpty()]
    [int]$PrerequisiteCheckCount = 120
)
Begin {
    # Determine SiteCode from WMI
    try {
        Write-Verbose -Message "Determining Site Code for Site server: '$($SiteServer)'"
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
                Write-Verbose -Message "Site Code: $($SiteCode)"
            }
        }
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to determine Site Code" ; break
    }
}
Process {
    # Define update check variables
    $UpdateCheckCount = 0
    $PrereqCheckCount = 0
    $UpdatePackageAvailibility = $false

    # Check for an available UpdatePackage matching the specified version
    $CMUpdatePackage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_CM_UpdatePackages -ComputerName $SiteServer -Filter "(Name like 'Configuration Manager $($Version)%') AND (UpdateType = 0) AND (State != 196612)" -Verbose:$false
    if (($CMUpdatePackage | Measure-Object).Count -eq 1) {
        do {
            # Increment UpdateCheckCount
            $UpdateCheckCount++

            # Query SMS_CM_UpdatePackages WMI class for UpdatePackage instance
            Write-Verbose -Message "Configuration Manager Servicing: Attempting to locate Update Package in SMS_CM_UpdatePackages matching 'Configuration Manager $($Version)'"
            $CMUpdatePackage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_CM_UpdatePackages -ComputerName $SiteServer -Filter "(Name like 'Configuration Manager $($Version)%') AND (UpdateType = 0)" -Verbose:$false

            # Determine whether UpdatePackage is available for installation
            if ($CMUpdatePackage -eq $null) {
                Write-Verbose -Message "Configuration Manager Servicing ($($UpdateCheckCount) / $($AvailabilityCheckCount)): UpdatePackage was not found matching 'Configuration Manager $($Version)', sleeping for 30 seconds"
            }
            else {
                Write-Verbose -Message "Configuration Manager Servicing ($($UpdateCheckCount) / $($AvailabilityCheckCount)): UpdatePackage found, validating if $($CMUpdatePackage.Name.TrimEnd()) is ready for installation"
                switch ($CMUpdatePackage.State) {
                    327682 {
                        Write-Verbose -Message "Configuration Manager Servicing ($($UpdateCheckCount) / $($AvailabilityCheckCount)): UpdatePackage state is Downloading, sleeping for 30 seconds"
                        if ($UpdateCheckCount -eq $AvailabilityCheckCount) {
                            Write-Verbose -Message "Configuration Manager Servicing ($($UpdateCheckCount) / $($AvailabilityCheckCount)): Downloading state detected for longer than $($AvailabilityCheckCount * 30 / 60) minutes, restarting SMS_EXECUTIVE service"
                            if ($PSCmdlet.ShouldProcess("SMS_EXECUTIVE", "Restart")) {
                                Restart-Service -Name "SMS_EXECUTIVE" -Force -Verbose:$false
                            }
                            $UpdateCheckCount = 0
                        }                
                    }
                    262146 {
                        Write-Verbose -Message "Configuration Manager Servicing ($($UpdateCheckCount) / $($AvailabilityCheckCount)): UpdatePackage state is Available, attempting to initiate installation of $($CMUpdatePackage.Name.TrimEnd())"
                        $UpdatePackageAvailibility = $true
                    }
                }
            }

            # Wait until UpdatePackage is available
            if ($UpdatePackageAvailibility -eq $false) {
                Start-Sleep -Seconds 30
            }
        }
        while ($CMUpdatePackage.State -ne 262146)

        # Initiate UpdatePackage installation
        Write-Verbose -Message "Configuration Manager Servicing: Starting prerequisite checks for $($CMUpdatePackage.Name.TrimEnd())"
        $CMUpdatePackage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_CM_UpdatePackages -ComputerName $SiteServer -Filter "(Name like 'Configuration Manager $($Version)%') AND (UpdateType = 0)" -Verbose:$false
        if ($CMUpdatePackage -ne $null) {
            if ($PSCmdlet.ShouldProcess($CMUpdatePackage.Name.TrimEnd(), "Install")) {
                $CMUpdatePackage.UpdatePrereqAndStateFlags(0,2) | Out-Null
            }
        }

        # Wait for prerequisite checks to complete, state 196609 equals Installing
        do {
            # Increment PrereqCheckCount
            $PrereqCheckCount++

            # Query for UpdatePackage instance to get State for prerequisite checks
            if ($PrereqCheckCount -eq $PrerequisiteCheckCount) {
                Write-Verbose -Message "Configuration Manager Servicing ($($PrereqCheckCount) / $($PrerequisiteCheckCount)): Prerequisite checks has been in running state for $($PrerequisiteCheckCount * 30 / 60) min, restarting SMS_EXECUTIVE service"
                if ($PSCmdlet.ShouldProcess("SMS_EXECUTIVE", "Restart")) {
                    Restart-Service -Name "SMS_EXECUTIVE" -Force -Verbose:$false
                }
                $PrereqCheckCount = 0
            }
            else {
                Write-Verbose -Message "Configuration Manager Servicing ($($PrereqCheckCount) / $($PrerequisiteCheckCount)): Waiting for prerequisite checks to complete for $($CMUpdatePackage.Name.TrimEnd()), sleeping for 30 seconds"
                $CMUpdatePackage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_CM_UpdatePackages -ComputerName $SiteServer -Filter "(Name like 'Configuration Manager $($Version)%') AND (UpdateType = 0)" -Verbose:$false

                # Wait until UpdatePackage prerequisite checks has completed
                Start-Sleep -Seconds 30
            }
        }
        while ($CMUpdatePackage.State -ne 196609)

        # Output that Configuration Manager Servicing has begun
        Write-Verbose -Message "Configuration Manager Servicing: Installation was successfully initated for $($CMUpdatePackage.Name.TrimEnd()), for more details, review the CMUpdate.log"        
    }
    elseif (($CMUpdatePackage | Measure-Object).Count -gt 1) {
        Write-Warning -Message "Query for Update Packages returned more than 1 instance, please define your search with a specific version"
    }
    else {
        Write-Warning -Message "Query for Update Packages did not return any instances"
    }
}