<#
.SYNOPSIS
    Connect to an active Operating System Deployment with DaRT Remote Viewer
.DESCRIPTION
    This script will connect to an active Operating System Deployment using the DaRT Remote Viewer.
    For this script to work properly, MDT 2013 (with monitoring enabled) and DaRT 8.1 needs to be installed on the Primary Site server.
    You should run this script from your Primary Site server, since it has not been built with remoting capabilities.
.PARAMETER ComputerName
    Computer name of the system being deployed
.PARAMETER DeploymentShare
    Path to the MDT Deployment Share with monitoring enabled
.PARAMETER DaRTRemoteViewier
    Path to DartRemoteViewer.exe
.EXAMPLE
    .\Start-DaRTRemoteViewer.ps1 -ComputerName CL001 -DeploymentShare "D:\DeploymentShare" -DaRTRemoteViewer "D:\Microsoft DaRT\v8.1\DartRemoteViewer.exe"
    Connect to an active OSD running on a client called 'CL001':
.NOTES
    Script name: Start-DaRTRemoteViewer.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    DateCreated: 2015-05-23
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Computer name of the system being deployed")]
    [ValidateNotNullorEmpty()]
    [string]$ComputerName,
    [parameter(Mandatory=$true, HelpMessage="Path to the MDT Deployment Share with monitoring enabled")]
    [ValidateNotNullorEmpty()]
    [string]$DeploymentShare,
    [parameter(Mandatory=$true, HelpMessage="Path to DartRemoteViewer.exe")]
    [ValidateNotNullorEmpty()]
    [ValidatePattern("^(?:[\w]\:|\\)(\\[a-z_\-\s0-9\.]+)+\.(exe)$")]
    [ValidateScript({
        # Check if path contains any invalid characters
        if ((Split-Path -Path $_ -Leaf).IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
            Write-Warning -Message "$(Split-Path -Path $_ -Leaf) contains invalid characters" ; break
        }
        else {
            # Check if the whole directory path exists
            if (-not(Test-Path -Path (Split-Path -Path $_) -PathType Container -ErrorAction SilentlyContinue)) {
                Write-Warning -Message "Unable to locate part of or the whole specified path" ; break
            }
            elseif (Test-Path -Path (Split-Path -Path $_) -PathType Container -ErrorAction SilentlyContinue) {
                return $true
            }
            else {
                Write-Warning -Message "Unhandled error" ; break
            }
        }
    })]
    [string]$DaRTRemoteViewer
)
Begin {
    # Load BDD SnapIn and attempt to create PSDrive
    if ([System.Environment]::Is64BitProcess) {
        try {
            Write-Verbose -Message "Attempting to load Microsoft.BDD.PSSnapIn"
            Add-PSSnapIn -Name Microsoft.BDD.PSSnapIn -ErrorAction Stop -Verbose:$false | Out-Null
            Write-Verbose -Message "Creating PSDrive 'DS001' with root: $($DeploymentShare)"
            if (-not(Get-PSDrive -Name "DS001" -ErrorAction SilentlyContinue -Verbose:$false)) {
                New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root "$($DeploymentShare)" -ErrorAction Stop -Verbose:$false | Out-Null
            }
        }
        catch [System.UnauthorizedAccessException] {
            Write-Warning -Message "Access denied" ; break
        }
        catch [System.Exception] {
            Write-Warning -Message $_.Exception.Message ; break
        }
        # Load assemblies
        try {
            Add-Type -AssemblyName "System.Windows.Forms" -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message $_.Exception.Message ; break
        }
    }
    else {
        Write-Warning -Message "Unable to load Microsoft.BDD.PSSnapIn. Point to SysNative instead of System32 path for PowerShell.exe" ; break
    }
}
Process {
    # Functions
    function Show-MessageBox {
        param(
            [Parameter(Mandatory=$true)]
            [string]$Message,
            [Parameter(Mandatory=$true)]
            [string]$WindowTitle,
            [Parameter(Mandatory=$true)]
            [System.Windows.Forms.MessageBoxButtons]$Button,
            [Parameter(Mandatory=$true)]
            [System.Windows.Forms.MessageBoxIcon]$Icon
        )
        return [System.Windows.Forms.MessageBox]::Show($Message, $WindowTitle, $Button, $Icon)
    }
    # Start DaRT Remote Viewer
    try {
        $MonitoringData = Get-MDTMonitorData -Path "DS001:" | Where-Object { ($_.Name -eq "$($ComputerName)") -and ($_.DeploymentStatus -eq 1) }
        if ($MonitoringData -ne $null) {
            Write-Verbose -Message "Located monitored deployment for computer: $($ComputerName)"
            $ArgmentList = "-ticket=$($MonitoringData.DartTicket) -ipaddress=$($MonitoringData.DartIP) -port=$($MonitoringData.DartPort)"
            Write-Verbose -Message "Launching DartRemoteViewer.exe with the following arguments: '$($ArgmentList)'"
            Start-Process -FilePath $DaRTRemoteViewer -ArgumentList $ArgmentList -ErrorAction Stop
        }
        else {
            $Prompt = Show-MessageBox -Message "Unable to find active Operating System Deployment for $($ComputerName)" -WindowTitle "No data found" -Button OK -Icon Information
        }
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        Write-Warning -Message $_.Exception.Message ; break
    }
}