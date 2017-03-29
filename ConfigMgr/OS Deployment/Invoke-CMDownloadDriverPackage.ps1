<#
.SYNOPSIS
    Download driver package (regular package) matching computer model.

.DESCRIPTION
    This script will determine the model of the computer, query the specified endpoint for ConfigMgr WebService for a list of Packages and set 
    OSDDownloadDownloadPackages variable to include the PackageID property of packages matching the computer model.

.PARAMETER URI
    Set the URI for the ConfigMgr WebService.

.PARAMETER SecretKey
    Specify the known secret key for the ConfigMgr WebService.

.PARAMETER Filter
    Define a filter used when calling ConfigMgr WebService to only return objects matching the filter.

.EXAMPLE
    .\Invoke-CMDownloadDriverPackage.ps1 -SecretKey "12345" -Filter "Drivers"

.NOTES
    FileName:    Invoke-CMDownloadDriverPackage.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    Created:     2017-03-27
    Updated:     2017-03-27
    
    Version history:
    1.0.0 - (2017-03-27) Script created
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Set the URI for the ConfigMgr WebService.")]
    [ValidateNotNullOrEmpty()]
    [string]$URI,

    [parameter(Mandatory=$true, HelpMessage="Specify the known secret key for the ConfigMgr WebService.")]
    [ValidateNotNullOrEmpty()]
    [string]$SecretKey,

    [parameter(Mandatory=$false, HelpMessage="Define a filter used when calling ConfigMgr WebService to only return objects matching the filter.")]
    [ValidateNotNullOrEmpty()]
    [string]$Filter = [System.String]::Empty
)
Begin {
    # Load Microsoft.SMS.TSEnvironment COM object
    try {
        $TSEnvironment = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to construct Microsoft.SMS.TSEnvironment object" ; exit 1
    }
}
Process {
    # Functions
    function Write-CMLogEntry {
	    param(
		    [parameter(Mandatory=$true, HelpMessage="Value added to the log file.")]
		    [ValidateNotNullOrEmpty()]
		    [string]$Value,

		    [parameter(Mandatory=$true, HelpMessage="Severity for the log entry. 1 for Informational, 2 for Warning and 3 for Error.")]
		    [ValidateNotNullOrEmpty()]
            [ValidateSet("1", "2", "3")]
		    [string]$Severity,

		    [parameter(Mandatory=$false, HelpMessage="Name of the log file that the entry will written to.")]
		    [ValidateNotNullOrEmpty()]
		    [string]$FileName = "DriverPackageDownload.log"
	    )
	    # Determine log file location
        $LogFilePath = Join-Path -Path $Script:TSEnvironment.Value("_SMSTSLogPath") -ChildPath $FileName

        # Construct time stamp for log entry
        $Time = -join @((Get-Date -Format "HH:mm:ss.fff"), "+", (Get-WmiObject -Class Win32_TimeZone | Select-Object -ExpandProperty Bias))

        # Construct date for log entry
        $Date = (Get-Date -Format "MM-dd-yyyy")

        # Construct context for log entry
        $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

        # Construct final log entry
        $LogText = "<![LOG[$($Value)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""DriverPackageDownloader"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
	
	    # Add value to log file
        try {
	        Add-Content -Value $LogText -LiteralPath $LogFilePath -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message "Unable to append log entry to DriverPackageDownload.log file. Error message: $($_.Exception.Message)"
        }
    }

    # Write log file for script execution
    Write-CMLogEntry -Value "Driver download package process initiated" -Severity 1

    # Determine computer model and manufacturer
    $ComputerManufacturer = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Manufacturer
    Write-CMLogEntry -Value "Manufacturer determined as: $($ComputerManufacturer)" -Severity 1
    $ComputerModel = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Model
    Write-CMLogEntry -Value "Computer model determined as: $($ComputerModel)" -Severity 1

    # Construct new web service proxy
    try {
        $WebService = New-WebServiceProxy -Uri $URI -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-CMLogEntry -Value "Unable to establish a connection to ConfigMgr WebService. Error message: $($_.Exception.Message)" -Severity 3 ; exit 1
    }

    # Call web service for a list of packages
    try {
        $Packages = $WebService.GetCMPackage($SecretKey, $Filter) #| Sort-Object -Property PackageCreated -Descending
        Write-CMLogEntry -Value "Retrieved a total of $(($Packages | Measure-Object).Count) driver packages from web service" -Severity 1
    }
    catch [System.Exception] {
        Write-CMLogEntry -Value "An error occured while calling ConfigMgr WebService for a list of available packages. Error message: $($_.Exception.Message)" -Severity 3 ; exit 1
    }

    # Construct array list for matching packages
    $PackageList = New-Object -TypeName System.Collections.ArrayList


    # Add check for VM's - what should happen
    $ComputerSystemType = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty "Model"
    if ($ComputerSystemType -notin @("Virtual Machine", "VMware Virtual Platform", "VirtualBox", "HVM domU", "KVM")) {
        # Set script error preference variable
        $ErrorActionPreference = "Stop"

        # Process packages returned from web service
        if ($Packages -ne $null) {
            # Add packages matching computer model and manufacturer to list
            foreach ($Package in $Packages) {
                if (($Package.PackageName -match $ComputerModel) -and ($ComputerManufacturer -match $Package.PackageManufacturer)) {
                    Write-CMLogEntry -Value "Match found for computer model and manufacturer: $($Package.PackageID)" -Severity 1
                    $PackageList.Add($Package) | Out-Null
                }
            }

            # Process matching items in package list and set task sequence variable
            if ($PackageList -ne $null) {
                # Determine the most current package from list
                if ($PackageList.Count -eq 1) {
                    Write-CMLogEntry -Value "Driver package list contains a single match, attempting to set task sequence variable" -Severity 1

                    # Attempt to set task sequence variable
                    try {
                        $TSEnvironment.Value("OSDDownloadDownloadPackages") = $($PackageList[0].PackageID)
                        Write-CMLogEntry -Value "Successfully set OSDDownloadDownloadPackages variable with PackageID: $($PackageList[0].PackageID)" -Severity 1
                    }
                    catch [System.Exception] {
                        Write-CMLogEntry -Value "An error occured while setting OSDDownloadDownloadPackages variable. Error message: $($_.Exception.Message)" -Severity 3 ; exit 1
                    }
                }
                elseif ($PackageList.Count -ge 2) {
                    Write-CMLogEntry -Value "Driver package list contains multiple matches, attempting to set task sequence variable" -Severity 1

                    # Attempt to set task sequence variable
                    try {
                        $Package = $PackageList | Sort-Object -Property PackageCreated -Descending | Select-Object -First
                        $TSEnvironment.Value("OSDDownloadDownloadPackages") = $($Package[0].PackageID)
                        Write-CMLogEntry -Value "Successfully set OSDDownloadDownloadPackages variable with PackageID: $($Package[0].PackageID)" -Severity 1
                    }
                    catch [System.Exception] {
                        Write-CMLogEntry -Value "An error occured while setting OSDDownloadDownloadPackages variable. Error message: $($_.Exception.Message)" -Severity 3 ; exit 1
                    }
                }
                else {
                    Write-CMLogEntry -Value "Unable to determine a matching driver package from list, since an unsupported count was returned from package list" -Severity 2 ; exit 1
                }
            }
            else {
                Write-CMLogEntry -Value "Empty driver package list detected, bailing out" -Severity 2 ; exit 1
            }
        }
        else {
            Write-CMLogEntry -Value "Driver package list returned from web service did not contain any objects matching the computer model and manufacturer" -Severity 2 ; exit 1
        }
    }
    else {
        Write-CMLogEntry -Value "Unsupported computer platform detected, bailing out" -Severity 2
    }
}