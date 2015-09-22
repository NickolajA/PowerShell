<#
.SYNOPSIS
    Removes packages in Configuration Manager 2012, specified from a text file.
.DESCRIPTION
    This script will remove all packages matched by name specified in a text file.
.PARAMETER SiteServer
    Primary Site server name
.PARAMETER FilePath
    Path to a text file containing package names
.EXAMPLE
    Remove all packages that matches the name specified in a text file located at 'C:\Temp\Packages.txt' at the Primary Site server called 'CM01':

    .\Remove-PackagesFromList.ps1 -SiteServer CM01 -FilePath "C:\Temp\Packages.txt"
.EXAMPLE 
    Check what packages are to be removed specified in a text file located at 'C:\Temp\Packages.txt' at the Primary Site server called 'CM01':

    .\Remove-PackagesFromList.ps1 -SiteServer CM01 -FilePath "C:\Temp\Packages.txt" -WhatIf
.NOTES
    Script name: Remove-PackagesFromList.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    DateCreated: 2014-09-22
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Specify Primary Site server")]
    [string]$SiteServer = "$($env:COMPUTERNAME)",
    [parameter(Mandatory=$true, HelpMessage="Path to text file")]
    [ValidateScript({Test-Path -Path $_ -Include *.txt})]
    [string]$FilePath
)
Begin {
    # Determine SiteCode from WMI
    try {
        Write-Verbose "Determining SiteCode for Site Server: '$($SiteServer)'"
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
                Write-Debug "SiteCode: $($SiteCode)"
            }
        }
    }
    catch [Exception] {
        Throw "Unable to determine SiteCode"
    }
    # Load the Configuration Manager 2012 PowerShell module
    try {
        Write-Verbose "Importing Configuration Manager module"
        Write-Debug ((($env:SMS_ADMIN_UI_PATH).Substring(0,$env:SMS_ADMIN_UI_PATH.Length-5)) + "\ConfigurationManager.psd1")
        Import-Module ((($env:SMS_ADMIN_UI_PATH).Substring(0,$env:SMS_ADMIN_UI_PATH.Length-5)) + "\ConfigurationManager.psd1") -Force
        if ((Get-PSDrive $SiteCode -ErrorAction SilentlyContinue | Measure-Object).Count -ne 1) {
            New-PSDrive -Name $SiteCode -PSProvider "AdminUI.PS.Provider\CMSite" -Root $SiteServer
        }
        # Set the location to the Configuration Manager drive
        Set-Location ($SiteCode + ":")
    }
    catch [Exception] {
        Throw $_.Exception.Message
    }
}
Process {
    try {
        # Get application names to look for
        $ApplicationNames = Get-Content -Path $FilePath
        #Write-Debug $ApplicationNames[0]
        foreach ($ApplicationName in $ApplicationNames) {
            $Package = Get-CMPackage -Name "$($ApplicationName)"
            if ($Package) {
                if ($Package.Count -ge 2) {
                    Write-Debug "Current Package:`n$($Package[0].Name)"
                    if ($Package[0].Name -like $ApplicationName) {
                        if ($PSCmdlet.ShouldProcess($Package[0].Name, "Remove")) {
                            Write-Verbose "Removing package: $($Package[0].Name)"
                            Remove-CMPackage -Name "$($Package[0].Name)" -Force -Verbose
                        }
                    }
                }
                else {
                    if ($Package.Name -like $ApplicationName) {
                        if ($PSCmdlet.ShouldProcess($Package.Name, "Remove")) {
                            Write-Verbose "Removing package: $($Package.Name)"
                            Remove-CMPackage -Name "$($Package.Name)" -Force -Verbose
                        }
                    }
                }
            }
            else {
                Write-Verbose "Unable to find '$($ApplicationName)'"
            }
        }
        Set-Location -Path C:
    }
    catch [Exception] {
        Write-Error $_.Exception.Message
    }
}