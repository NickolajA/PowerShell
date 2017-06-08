<#
.SYNOPSIS
    Invoke Dell BIOS Update process.

.DESCRIPTION
    This script will invoke the Dell BIOS update process for the executable residing in the path specified for the Path parameter.

.PARAMETER Path
    Specify the path containing the Flash64W.exe and BIOS executable.

.PARAMETER Password
    Specify the BIOS password if necessary.

.PARAMETER LogFileName
    Set the name of the log file produced by the flash utility.

.EXAMPLE
    .\Invoke-DellBIOSUpdate.ps1 -Path %DellBIOSFiles% -Password "BIOSPassword" -LogFileName "LogFileName.log"

.NOTES
    FileName:    Invoke-DellBIOSUpdate.ps1
    Author:      Maurice Daly
    Contact:     @modaly_it
    Created:     2017-05-30
    Updated:     2017-06-07
    
    Version history:
    1.0.0 - (2017-05-30) Script created
	1.0.1 - (2017-06-01) Additional checks for both in OSD and normal OS environments
    1.0.2 - (2017-06-07) Fixed bug in legacy update method
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Specify the path containing the Flash64W.exe and BIOS executable.")]
    [ValidateNotNullOrEmpty()]
    [string]$Path,

    [parameter(Mandatory=$false, HelpMessage="Specify the BIOS password if necessary.")]
    [ValidateNotNullOrEmpty()]
    [string]$Password,

    [parameter(Mandatory=$false, HelpMessage="Set the name of the log file produced by the flash utility.")]
    [ValidateNotNullOrEmpty()]
    [string]$LogFileName = "DellFlashBiosUpdate.log"
)
Begin {
	# Load Microsoft.SMS.TSEnvironment COM object
	try {
		$TSEnvironment = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop
	}
	catch [System.Exception] {
		Write-Warning -Message "Unable to construct Microsoft.SMS.TSEnvironment object"
	}
}
Process {

	# Flash bios upgrade utility file name
	$FlashUtility = Get-ChildItem -Path $Path -Filter "*.exe" -Recurse | Where-Object { $_.Name -like "Flash64W.exe" } | Select-Object -ExpandProperty FullName
	
    # Detect BIOS update executable
    $CurrentBiosFile = Get-ChildItem -Path $Path -Filter "*.exe" -Recurse | Where-Object { $_.Name -notlike ($FlashUtility | Split-Path -leaf) } | Select-Object -ExpandProperty FullName
	
	if (($TSEnvironment -ne $null) -and ($TSEnvironment.Value("_SMSTSinWinPE") -eq $true)) {
		# Set log file location
		$LogFilePath = Join-Path -Path $TSEnvironment.Value("_SMSTSLogPath") -ChildPath $LogFileName

		# Set required switches for silent upgrade of the bios and logging
		$FlashSwitches = "/b=$CurrentBIOSFile /s /f /l=$LogFilePath"

		if ($Password -ne $null) {
			# Add password to the flash bios switches
			$FlashSwitches = $FlashSwitches + " /p=$Password"
			Write-host $FlashSwitches
		}

		try {
			# Start flash update process
			$FlashProcess = Start-Process -FilePath $FlashUtility -ArgumentList "$FlashSwitches" -Passthru -Wait
			
            # Set reboot flag if restart required determined (exit code 2)
			if ($FlashProcess.ExitCode -eq 2) {
				# Set reboot required flag
				$TSEnvironment.Value("SMSTSBiosUpdateRebootRequired") = "True"
				$TSEnvironment.Value("SMSTSBiosInOSUpdateRequired") = "False"
			}
			else {
				$TSEnvironment.Value("SMSTSBiosUpdateRebootRequired") = "False"
				$TSEnvironment.Value("SMSTSBiosInOSUpdateRequired") = "True"
			}
		}
		catch [System.Exception] {
			Write-Warning -Message "An error occured while updating the system bios. Error message: $($_.Exception.Message)"; exit 1
		}
	}
	else {
		# Used as a fall back for systems that do not support the Flash64w update tool
		# Used in a later section of the task sequence
		
		# Set log file location based for OSD and standard deployments
		if ($TSEnvironment -ne $null) {
		$LogFilePath = Join-Path -Path $TSEnvironment.Value("_SMSTSLogPath") -ChildPath $LogFileName
		}
		else {
		$LogFilePath = Join-Path -Path "$env:Temp\" -ChildPath $LogFileName
		}
		
		# Detect Bitlocker Status
		$OSVolumeEncypted = if ((Manage-Bde -Status C:) -match "Protection On"){Write-Output $True}else{Write-Output $False}
		
		# Supend Bitlocker if $OSVolumeEncypted is $true
		if ($OSVolumeEncypted -eq $true) {
		Manage-Bde -Protectors -Disable C:
		}

        # Detect BIOS update executable
        $CurrentBiosFile = Get-ChildItem -Path $Path -Filter "*.exe" | Where-Object { $_.Name -notlike ($FlashUtility | Split-Path -leaf) } | Select-Object -ExpandProperty FullName
		
		# Set required switches for silent upgrade of the bios
		$BIOSSwitches = " -noreboot -nopause"
		if ($Password -ne $null) {
			# Add password to the flash bios switches
			$BIOSSwitches = $BIOSSwitches + " /p=$Password"
		}

        # Set required switches for silent upgrade of the bios
		$BIOSSwitches = " /l=" + "$LogFileName" + " /s"
		if ($Password -ne $null)
		{
			# Add password to the flash bios switches
			$BIOSSwitches = $BIOSSwitches + " /p=" + "$Password"
		}
		
		# Start Bios update process
        try {
			$BiosUpdateProcess = Start-Process -FilePath $CurrentBIOSFile -ArgumentList $BIOSSwitches -PassThru -Wait
		}
		catch [System.Exception]
		{
			Write-Warning -Message "An error occured while updating the system bios. Error message: $($_.Exception.Message)"; exit 1
		}
	}
}