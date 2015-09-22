<#
.SYNOPSIS
    Import a repository containing driver source files into ConfigMgr 2012 R2
.DESCRIPTION
    This script will validate and import driver source files divided into folders named by OS, Make and Model.
    In order to run this script successfully, you need to have the ConfigMgr console installed on the machine 
    where you wish to execute the script.
.PARAMETER SiteServer
    Site server name with SMS Provider installed
.PARAMETER DriverSourcePath
    Path to where the Driver Source root directory is located
.PARAMETER DriverPackagePath
    Path to where the Driver Package root directory is located
.PARAMETER Model
    Specify the device model
.PARAMETER Make
    Specify the device manufacturer
.PARAMETER OperatingSystem
    Specify the operating system the drivers are supported on
.PARAMETER Categories
    Specify the additional driver categories to be associated with the drivers for this model
.PARAMETER DPGroupName
    Specify the name of the Distribution Point Group that new Driver Packages will be distributed to
.PARAMETER ShowProgress
    Show a progressbar displaying the current operation
.EXAMPLE
    .\Import-CMDriverModel.ps1 -SiteServer CM01 -DriverSourcePath "\\CM01\Sources\OSD\DriverSources\Windows Server 2012 R2\Dell\Precision M3800" -DriverPackagePath "\\CM01\Sources\OSD\DriverPackages" -DPGroupName "All DPs" -Model "Precision M3800" -Make "Dell" -OperatingSystem "Windows Server 2012 R2"
.NOTES
    Script name: Import-CMDriverModel.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    DateCreated: 2014-12-29
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server name with SMS Provider installed")]
    [string]$SiteServer,
    [parameter(Mandatory=$true, HelpMessage="Path to where the Driver Source root directory is located")]
    [ValidatePattern("^\\\\\w+\\\w+")]
    [ValidateScript({Test-Path -Path $_ -PathType Container})]
    [string]$DriverSourcePath,
    [parameter(Mandatory=$true, HelpMessage="Path to where the Driver Package root directory is located")]
    [ValidatePattern("^\\\\\w+\\\w+")]
    [ValidateScript({Test-Path -Path $_ -PathType Container})]
    [string]$DriverPackagePath,
    [parameter(Mandatory=$true, HelpMessage="Specify the device model")]
    [string]$Model,
    [parameter(Mandatory=$true, HelpMessage="Specify the device manufacturer")]
    [string]$Make,
    [parameter(Mandatory=$true, HelpMessage="Specify the operating system the drivers are supported on")]
    [string]$OperatingSystem,
    [parameter(Mandatory=$false, HelpMessage="Specify the additional driver categories to be associated with the drivers for this model")]
    [string[]]$Categories,
    [parameter(Mandatory=$true, HelpMessage="Specify the name of the Distribution Point Group that new Driver Packages will be distributed to")]
    [string]$DPGroupName,
    [parameter(Mandatory=$false, HelpMessage="Show a progressbar displaying the current operation")]
    [switch]$ShowProgress
)
Begin {
    # Get current location
    $CurrentLocation = Get-Location
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
    # Import Configuration Manager PowerShell module
    try {
        $SiteDrive = $SiteCode + ":"
        Import-Module (Join-Path -Path (($env:SMS_ADMIN_UI_PATH).Substring(0,$env:SMS_ADMIN_UI_PATH.Length-5)) -ChildPath "\ConfigurationManager.psd1") -Force -Verbose:$false
        if ((Get-PSDrive $SiteCode -ErrorAction SilentlyContinue | Measure-Object).Count -ne 1) {
            New-PSDrive -Name $SiteCode -PSProvider "AdminUI.PS.Provider\CMSite" -Root $SiteServer
        }
    }
    catch [Exception] {
        Throw "Unable to determine SiteCode"
    }
    if ($PSBoundParameters["ShowProgress"]) {
        $CurrentDriverCount = 0
    }
}
Process {
    # Get all driver files
    $DriverINFs = Get-ChildItem -Path $DriverSourcePath -Recurse -Include *.inf
    Set-Location $SiteDrive -Verbose:$false
    # Create Driver Categories if they do not exist
    $DriverCategories = New-Object -TypeName System.Collections.ArrayList
    $DriverCategories.AddRange(@($Model, $Make, $OperatingSystem))
    if ($PSBoundParameters["Categories"]) {
        $DriverCategories.AddRange(@($Categories))
    }
    foreach ($DriverCategory in $DriverCategories) {
        if ((Get-CMCategory -CategoryType DriverCategories -Name $DriverCategory -Verbose:$false) -eq $null) {
            Write-Verbose -Message "Creating new Driver Category: $($DriverCategory)"
            New-CMCategory -CategoryType DriverCategories -Name $DriverCategory -Verbose:$false | Out-Null
        }
    }
    # Create Driver Package
    $DriverPackageName = "$($Make) - $($Model) - $($OperatingSystem)"
    if ((Get-CMDriverPackage -Name $DriverPackageName -Verbose:$false) -eq $null) {
        if ($DriverPackagePath.EndsWith("\")) {
            $NewDriverPackagePath = "$($DriverPackagePath)$($OperatingSystem)\$($Make)\$($Model)"
        }
        else {
            $NewDriverPackagePath = "$($DriverPackagePath)\$($OperatingSystem)\$($Make)\$($Model)"
        }
        Write-Verbose -Message "Creating new Driver Package: $($DriverPackageName)"
        New-CMDriverPackage -Name $DriverPackageName -Path $NewDriverPackagePath -Verbose:$false | Out-Null
        if ($PSCmdlet.ShouldProcess("Package: $($DriverPackageName)","Distribute")) {
            Start-CMContentDistribution -DriverPackageName $DriverPackageName -DistributionPointGroupName $DPGroupName -Verbose:$false | Out-Null
        }
    }
    $DriverPackage = Get-CMDriverPackage -Name "$($DriverPackageName)" -Verbose:$false
    if (($DriverPackage | Measure-Object).Count -ge 1) {
        Write-Verbose -Message "Driver Package: $($DriverPackage.Name)"
    }
    # Construct Driver Category array
    $DriverCategoryArray = @()
    foreach ($DriverCategoryObject in $DriverCategories) {
        $DriverCategoryArray += (Get-CMCategory -CategoryType DriverCategories -Name $DriverCategoryObject -Verbose:$false)
    }
    foreach ($CategoryObject in $DriverCategoryArray) {
        Write-Verbose -Message "Categories: $($CategoryObject.LocalizedCategoryInstanceName)"
    }
    # Import Drivers
    $DriverCount = ($DriverINFs | Measure-Object).Count
    foreach ($DriverINF in $DriverINFs) {
        $CurrentDriverCount++
        if ($PSBoundParameters["ShowProgress"]) {
            $ProgressArguments = @{
                Id = 1
                Activity = "Importing Drivers"
                Status = "Processing driver $($CurrentDriverCount) of $($DriverCount)"
                CurrentOperation = "Current model: $($Model)"
                PercentComplete = (($CurrentDriverCount / $DriverCount) * 100)
            }
            Write-Progress @ProgressArguments
        }
        try {
            if ($PSCmdlet.ShouldProcess("Driver: $($DriverINF.Name)","Import Driver")) {
                $DriverArguments = @{
                    UncFileLocation = $DriverINF.FullName
                    DriverPackage = $DriverPackage
                    EnableAndAllowInstall = $true
                    AdministrativeCategory = $DriverCategoryArray
                    ImportDuplicateDriverOption = "AppendCategory"
                    ErrorAction = "SilentlyContinue"
                    Verbose = $false
                }
                Import-CMDriver @DriverArguments | Out-Null
            }
        }
        catch {
            Write-Warning "Failed to import: $($DriverINF.FullName). $($_.Exception.Message)"
        }
    }
    if ($PSBoundParameters["ShowProgress"]) {
        Write-Progress -Id 1 -Activity "Importing Drivers" -Completed
    }
    if ($PSCmdlet.ShouldProcess("Package: $($DriverPackageName)","Update")) {
        Update-CMDistributionPoint -DriverPackageName $DriverPackageName -Verbose:$false
    }
}
End {
    Set-Location $CurrentLocation -Verbose:$false
}