<#

SYNPOSIS, write it

#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true)]
    [string]$SiteServer,
    [parameter(Mandatory=$true)]
    [ValidateScript({Test-Path -Path $_ -PathType Container})]
    [string]$DriverSourcePath,
    [parameter(Mandatory=$true)]
    [ValidateScript({Test-Path -Path $_ -PathType Container})]
    [string]$DriverPackagePath,
    [parameter(Mandatory=$true)]
    [string]$DPGroupName
)
Begin {
    # Get current location
    $CurrentLocation = Get-Location
    # Determine SiteCode from WMI
    try {
        Write-Verbose "Determining SiteCode for Site Server: '$($SiteServer)'"
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer
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
        Import-Module (Join-Path -Path (($env:SMS_ADMIN_UI_PATH).Substring(0,$env:SMS_ADMIN_UI_PATH.Length-5)) -ChildPath "\ConfigurationManager.psd1") -Force
        if ((Get-PSDrive $SiteCode -ErrorAction SilentlyContinue | Measure-Object).Count -ne 1) {
            New-PSDrive -Name $SiteCode -PSProvider "AdminUI.PS.Provider\CMSite" -Root $SiteServer
        }
    }
    catch [Exception] {
        Throw "Unable to determine SiteCode"
    }
}
Process {
    # Validate Operating System folders in Driver Sources path
    $ValidOSList = New-Object -TypeName System.Collections.ArrayList
    $OSFolders = Get-ChildItem -Path $DriverSourcePath | Select-Object Name, FullName
    Write-Verbose -Message "<---- Starting validation of OS and Make folders ---->"
    foreach ($OSFolder in $OSFolders) {
        if ((Get-Item -Path $OSFolder.FullName).Attributes -like "Directory") {
            Write-Verbose -Message "Current OS item: $($OSFolder.FullName)"
            # Check to see if there's any child items in the current OS folder
            if (-not((Get-ChildItem -Path $OSFolder.FullName) -eq $null)) {
                foreach ($OSSubFolder in (Get-ChildItem -Path $OSFolder.FullName)) {
                    Write-Verbose -Message "Current OS Sub-item: $($OSSubFolder)"
                    # Throw an error if there's an unsupported item in the OS folder
                    if (-not((Get-Item -Path $OSSubFolder.FullName).Attributes -like "Directory")) {
                        Throw "ERROR: Unsupported files found"
                    }
                }
                Write-Verbose -Message "Validated Operating System folder: $($OSFolder.Name)"
                $ValidOSList.Add($OSFolder.FullName) | Out-Null
            }
            else {
                Write-Warning -Message "Unable to validate Operating System folder: $($OSFolder.Name)"
                Write-Warning -Message "REASON: Operating System folder is empty"
            }
        }
    }


    ##### Validate that the specified DriverPackages folder is empty




    Write-Verbose -Message "<---- Finished folder structure validation ---->"

    # Loop through the validated OS list
    Write-Verbose -Message "<---- Starting to process objects ---->"
    # Operating System
    foreach ($OS in $ValidOSList) {
        $CurrentOSName = Get-Item -Path $OS | Select-Object -ExpandProperty Name
        $CurrentOSPath = $OS
        $MakeObjects = Get-ChildItem -Path $CurrentOSPath | Select-Object -Property Name, FullName
        Write-Verbose -Message "Operating System: $($CurrentOSName)"
        Write-Verbose -Message "Path: $($OS)"
        Set-Location $SiteDrive -Verbose:$false
        # Create OS category if not exist
        if ((Get-CMCategory -CategoryType DriverCategories -Name $CurrentOSName -Verbose:$false) -eq $null) {
            Write-Verbose -Message "Creating new Driver Category: $($CurrentOSName)"
            New-CMCategory -CategoryType DriverCategories -Name $CurrentOSName | Out-Null
        }
        Set-Location $CurrentLocation -Verbose:$false
        # Make
        foreach ($Make in $MakeObjects) {
            $CurrentMakeName = $Make.Name
            $CurrentMakePath = $Make.FullName
            $ModelObjects = Get-ChildItem -Path $CurrentMakePath | Select-Object -Property Name, FullName
            Write-Verbose -Message "-- Make: $($CurrentMakeName)"
            Write-Verbose -Message "-- Path: $($CurrentMakePath)"
            Set-Location $SiteDrive -Verbose:$false
            # Create Make category if not exist
            if ((Get-CMCategory -CategoryType DriverCategories -Name $CurrentMakeName -Verbose:$false) -eq $null) {
                Write-Verbose -Message "---- Creating new Driver Category: $($CurrentMakeName)"
                New-CMCategory -CategoryType DriverCategories -Name $CurrentMakeName -Verbose:$false | Out-Null
            }
            Set-Location $CurrentLocation -Verbose:$false
            # Model
            foreach ($Model in $ModelObjects) {
                $CurrentModelName = $Model.Name
                $CurrentModelPath = $Model.FullName
                Write-Verbose -Message "---- Model: $($CurrentModelName)"
                Write-Verbose -Message "---- Path: $($CurrentModelPath)"
                $DriverINFs = Get-ChildItem -Path $CurrentModelPath -Recurse -Include *.inf
                Write-Verbose -Message "------ Drivers: $(($DriverINFs | Measure-Object).Count)"
                Set-Location $SiteDrive -Verbose:$false
                # Create Model category if not exist
                if ((Get-CMCategory -CategoryType DriverCategories -Name $CurrentModelName -Verbose:$false) -eq $null) {
                    Write-Verbose -Message "------ Creating new Driver Category: $($CurrentModelName)"
                    New-CMCategory -CategoryType DriverCategories -Name $CurrentModelName -Verbose:$false | Out-Null
                }
                # Create Driver Package
                $CurrentDriverPackageName = "$($CurrentMakeName) - $($CurrentModelName) - $($CurrentOSName)"
                if ((Get-CMDriverPackage -Name $CurrentDriverPackageName -Verbose:$false) -eq $null) {
                    if ($DriverPackagePath.EndsWith("\")) {
                        $NewDriverPackagePath = "$($DriverPackagePath)$($CurrentOSName)\$($CurrentMakeName)\$($CurrentModelName)"
                    }
                    else {
                        $NewDriverPackagePath = "$($DriverPackagePath)\$($CurrentOSName)\$($CurrentMakeName)\$($CurrentModelName)"
                    }
                    Write-Verbose -Message "------ Creating new Driver Package: $($CurrentDriverPackageName)"
                    New-CMDriverPackage -Name $CurrentDriverPackageName -Path $NewDriverPackagePath -Verbose:$false | Out-Null
                    Start-CMContentDistribution -DriverPackageName $CurrentDriverPackageName -DistributionPointGroupName $DPGroupName -Verbose:$false | Out-Null
                }
                $CurrentDriverPackage = Get-CMDriverPackage -Name "$($CurrentDriverPackageName)" -Verbose:$false
                if (($CurrentDriverPackage | Measure-Object).Count -ge 1) {
                    Write-Verbose -Message "------ Current Driver Package: $($CurrentDriverPackage.Name)"
                }
                # Construct Driver Category array
                $DriverCategoryArray = @()
                $DriverCategoryArray += (Get-CMCategory -CategoryType DriverCategories -Name $CurrentOSName -Verbose:$false)
                $DriverCategoryArray += (Get-CMCategory -CategoryType DriverCategories -Name $CurrentMakeName -Verbose:$false)
                $DriverCategoryArray += (Get-CMCategory -CategoryType DriverCategories -Name $CurrentModelName -Verbose:$false)
                foreach ($Category in $DriverCategoryArray) {
                    Write-Verbose -Message "------ Categories: $($Category.LocalizedCategoryInstanceName)"
                }
                # Import Drivers
                $DriverCount = ($DriverINFs | Measure-Object).Count
                $CurrentDriverCount = 0
                foreach ($DriverINF in $DriverINFs) {
                    $CurrentDriverCount++
                    Write-Progress -Id 1 -Activity "Importing Drivers" -Status "Processing driver $($CurrentDriverCount) of $($DriverCount)" -CurrentOperation "Current model: $($CurrentModelName)" -PercentComplete (($CurrentDriverCount / $DriverCount) * 100)
                    try {
                        Import-CMDriver -UncFileLocation $DriverINF.FullName -DriverPackage $CurrentDriverPackage -EnableAndAllowInstall $true -AdministrativeCategory $DriverCategoryArray -ImportDuplicateDriverOption AppendCategory -ErrorAction SilentlyContinue -Verbose:$false | Out-Null
                    }
                    catch {
                        Write-Warning "Failed to import: $($DriverINF.FullName)"
                    }
                }
                Write-Progress -Id 1 -Activity "Importing Drivers" -Completed
                Update-CMDistributionPoint -DriverPackageName $CurrentDriverPackageName -Verbose:$false
                Set-Location $CurrentLocation -Verbose:$false
            }
        }
    }
}
