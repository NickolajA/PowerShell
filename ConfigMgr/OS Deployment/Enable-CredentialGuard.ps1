<#
.SYNOPSIS
    Enable Credential Guard on Windows 10 during OS Deployment with ConfigMgr

.DESCRIPTION
    This script will enable a Windows 10 device being installed through OS Deployment with ConfigMgr to leverage Credential Guard
    in order to provent pass-the-hash attacks.

.EXAMPLE
    .\Enable-CredentialGuard.ps1

.NOTES
    FileName:    Enable-CredentialGuard.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    Created:     2016-06-08
    Updated:     2016-06-08
    Version:     1.0.0
#>
Begin {
    # Construct TSEnvironment object
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
		    [parameter(Mandatory=$true, HelpMessage="Value added to the smsts.log file.")]
		    [ValidateNotNullOrEmpty()]
		    [string]$Value,

		    [parameter(Mandatory=$true, HelpMessage="Severity for the log entry. 1 for Informational, 2 for Warning and 3 for Error.")]
		    [ValidateNotNullOrEmpty()]
            [ValidateSet("1", "2", "3")]
		    [string]$Severity,

		    [parameter(Mandatory=$false, HelpMessage="Name of the log file that the entry will written to.")]
		    [ValidateNotNullOrEmpty()]
		    [string]$FileName = "EnableCredentialGuard.log"
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
        $LogText = "<![LOG[$($Value)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""DynamicApplicationsList"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
	
	    # Add value to log file
        try {
	        Add-Content -Value $LogText -LiteralPath $LogFilePath -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message "Unable to append log entry to smsts.log file"
        }
    }

    function Invoke-Executable {
        param(
            [parameter(Mandatory=$true, HelpMessage="Specify the name of the executable to be invoked including the extension")]
            [ValidateNotNullOrEmpty()]
            [string]$Name,

            [parameter(Mandatory=$false, HelpMessage="Specify arguments that will be passed to the executable")]
            [ValidateNotNull()]
            [string]$Arguments
        )

        if ([System.String]::IsNullOrEmpty($Arguments)) {
            try {
                $ReturnValue = Start-Process -FilePath $Name -NoNewWindow -Passthru -Wait -ErrorAction Stop
            }
            catch [System.Exception] {
                Write-Warning -Message $_.Exception.Message ; break
            }
        }
        else {
            try {
                $ReturnValue = Start-Process -FilePath $Name -ArgumentList $Arguments -NoNewWindow -Passthru -Wait -ErrorAction Stop
            }
            catch [System.Exception] {
                Write-Warning -Message $_.Exception.Message ; break
            }
        }

        # Return exit code from executable
        return $ReturnValue.ExitCode
    }

    # Write beginning of log file
    Write-CMLogEntry -Value "Starting configuration for Credential Guard" -Severity 1

    # Enable required Windows Features for Credential Guard
    $FeatureHyperVisor = Invoke-Executable -Name dism.exe -Arguments "/Online /Enable-Feature /FeatureName:Microsoft-Hyper-V-HyperVisor /All /LimitAccess /NoRestart"
    if ($FeatureHyperVisor -in @(0, 3010)) {
        Write-CMLogEntry -Value "Successfully enabled Microsoft-Hyper-V-HyperVisor feature" -Severity 1    
    }
    else {
        Write-CMLogEntry -Value "When enabling Microsoft-Hyper-V-HyperVisor feature, an unexpected exit code of $($FeatureHyperVisor) was returned" -Severity 3
    }

    $FeatureIsolatedUserMode = Invoke-Executable -Name dism.exe -Arguments "/Online /Enable-Feature /FeatureName:IsolatedUserMode /LimitAccess /NoRestart"
    if ($FeatureIsolatedUserMode -in @(0, 3010)) {
        Write-CMLogEntry -Value "Successfully enabled IsolatedUserMode feature" -Severity 1    
    }
    else {
        Write-CMLogEntry -Value "When enabling IsolatedUserMode feature, an unexpected exit code of $($FeatureIsolatedUserMode) was returned" -Severity 3
    }
    
    # Add required registry key for Credential Guard
    $RegistryKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"
    if (-not(Test-Path -Path $RegistryKeyPath)) {
        Write-CMLogEntry -Value "Creating HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard registry key" -Severity 1
        New-Item -Path $RegistryKeyPath -ItemType Directory -Force
    }

    # Add registry value RequirePlatformSecurityFeatures - 1 for Secure Boot only, 3 for Secure Boot and DMA Protection
    Write-CMLogEntry -Value "Adding HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard\RequirePlatformSecurityFeatures value as DWORD with data 1" -Severity 1
    New-ItemProperty -Path $RegistryKeyPath -Name RequirePlatformSecurityFeatures -PropertyType DWORD -Value 1

    # Add registry value EnableVirtualizationBasedSecurity - 1 for Enabled, 0 for Disabled
    Write-CMLogEntry -Value "Adding HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard\EnableVirtualizationBasedSecurity value as DWORD with data 1" -Severity 1
    New-ItemProperty -Path $RegistryKeyPath -Name EnableVirtualizationBasedSecurity -PropertyType DWORD -Value 1

    # Add registry value LsaCfgFlags - 1 enables Credential Guard with UEFI lock, 2 enables Credential Guard without lock, 0 for Disabled
    Write-CMLogEntry -Value "Adding HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa\LsaCfgFlags value as DWORD with data 1" -Severity 1
    New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\Lsa -Name LsaCfgFlags -PropertyType DWORD -Value 1

    # Write end of log file
    Write-CMLogEntry -Value "Successfully enabled Credential Guard" -Severity 1
}