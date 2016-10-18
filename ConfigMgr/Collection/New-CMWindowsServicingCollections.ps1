<#
.SYNOPSIS
    Create a set of Windows 10 servicing device collections, useful for determining state, branch and supportability status.

.DESCRIPTION
    Create a set of Windows 10 servicing device collections, useful for determining state, branch and supportability status.

.PARAMETER SiteServer
    Site server name with SMS Provider installed.

.PARAMETER FolderName
    Define a Device Collection folder name where the collections will be moved to.

.PARAMETER CollectionNamePrefix
    Prefix for the Device Collections this script creates.

.PARAMETER LimitingCollectionName
    Name of a collection that will be used as Limiting Collection.

.EXAMPLE
    .\New-CMWindowsServicingCollections.ps1 -SiteServer CM01 -FolderName "Windows Servicing"

.NOTES
    FileName:    New-CMWindowsServicingCollections.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    Created:     2016-10-18
    Updated:     2016-10-18
    
    Version history:
    1.0.0 - (2016-10-18) Script created
    1.0.1 - (2016-10-10) Added support for collection name prefix
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,

    [parameter(Mandatory=$false, HelpMessage="Define a Device Collection folder name where the collections will be moved to.")]
    [ValidateNotNullOrEmpty()]
    [string]$FolderName,

    [parameter(Mandatory=$false, HelpMessage="Prefix for the Device Collections this script creates.")]
    [ValidateNotNullOrEmpty()]
    [string]$CollectionNamePrefix = "WS - ",

    [parameter(Mandatory=$false, HelpMessage="Name of a collection that will be used as Limiting Collection.")]
    [ValidateNotNullOrEmpty()]
    [string]$LimitingCollectionName = "All Systems"
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

    # Load ConfigMgr module
    try {
        $SiteDrive = $SiteCode + ":"
        Import-Module -Name ConfigurationManager -ErrorAction Stop -Verbose:$false
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        try {
            Import-Module -Name (Join-Path -Path (($env:SMS_ADMIN_UI_PATH).Substring(0,$env:SMS_ADMIN_UI_PATH.Length-5)) -ChildPath "\ConfigurationManager.psd1") -Force -ErrorAction Stop -Verbose:$false
            if ((Get-PSDrive -Name $SiteCode -ErrorAction SilentlyContinue | Measure-Object).Count -ne 1) {
                New-PSDrive -Name $SiteCode -PSProvider "AdminUI.PS.Provider\CMSite" -Root $SiteServer -ErrorAction Stop -Verbose:$false | Out-Null
            }
        }
        catch [System.UnauthorizedAccessException] {
            Write-Warning -Message "Access denied" ; break
        }
        catch [System.Exception] {
            Write-Warning -Message "$($_.Exception.Message). Line: $($_.InvocationInfo.ScriptLineNumber)" ; break
        }
    }

    # Determine and set location to the CMSite drive
    $CurrentLocation = $PSScriptRoot
    Set-Location -Path $SiteDrive -Verbose:$false

    # Disable Fast parameter usage check for Lazy properties
    $CMPSSuppressFastNotUsedCheck = $true

    # Validate specified folder name exists
    if ($PSBoundParameters["FolderName"]) {
        if (-not(Test-Path -Path (Join-Path -Path $SiteDrive -ChildPath "DeviceCollection\$($FolderName)") -Verbose:$false)) {
            Write-Warning -Message "Unable to locate specified folder name in Device Collections"
            Set-Location -Path $CurrentLocation -Verbose:$false ; exit
        }
    }
}
Process {
    # Set ProgressCount for ShowProgress
    if ($PSBoundParameters["ShowProgress"]) {
        $ProgressCount = 0
    }

    # Table of collections
    $CollectionTable = @{
        "Windows 10 Current Branch (CB)" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.OperatingSystemNameandVersion like 'Workstation 10.0%' and SMS_R_System.OSBranch = '0'"
        "Windows 10 Current Branch for Business (CBB)" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.OperatingSystemNameandVersion like 'Workstation 10.0%' and SMS_R_System.OSBranch = '1'"
        "Windows 10 Long Term Servicing Branch (LTSB)" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.OperatingSystemNameandVersion like 'Workstation 10.0%' and SMS_R_System.OSBranch = '2'"
        "Windows 10 Feature Servicing State - Current" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System  LEFT OUTER JOIN SMS_WindowsServicingStates ON SMS_WindowsServicingStates.Build = SMS_R_System.build01 AND SMS_WindowsServicingStates.branch = SMS_R_System.osbranch01 where SMS_WindowsServicingStates.State = '2'"
        "Windows 10 Feature Servicing State - Expires Soon" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System  LEFT OUTER JOIN SMS_WindowsServicingStates ON SMS_WindowsServicingStates.Build = SMS_R_System.build01 AND SMS_WindowsServicingStates.branch = SMS_R_System.osbranch01 where SMS_WindowsServicingStates.State = '3'"
        "Windows 10 Feature Servicing State - Expired" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System  LEFT OUTER JOIN SMS_WindowsServicingStates ON SMS_WindowsServicingStates.Build = SMS_R_System.build01 AND SMS_WindowsServicingStates.branch = SMS_R_System.osbranch01 where SMS_WindowsServicingStates.State = '4'"
        "Windows 10 versioon 1507" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.Build like '10.0.10240%'"
        "Windows 10 versioon 1511" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.Build like '10.0.10586%'"
        "Windows 10 versioon 1607" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.Build like '10.0.14393%'"
    }

    # Create Windows as a Service operational collections
    foreach ($DeviceCollection in $CollectionTable.Keys) {
        # Create Device Collection
        try {
            $DeviceCollectionName = ($CollectionNamePrefix + $DeviceCollection)
            Write-Verbose -Message "Creating Device Collection: $($DeviceCollectionName)"
            $DeviceCollectionRefreshSchedule = New-CMSchedule -Start (Get-Date) -RecurInterval Days -RecurCount 1 -Verbose:$false -ErrorAction Stop
            New-CMDeviceCollection -LimitingCollectionName $LimitingCollectionName -Name $DeviceCollectionName -RefreshType Both -RefreshSchedule $DeviceCollectionRefreshSchedule -Verbose:$false -ErrorAction Stop | Out-Null

            # Create device collection query membership rule
            try {
                Write-Verbose -Message "Adding query membership rule for collection: $($DeviceCollectionName)"
                Add-CMDeviceCollectionQueryMembershipRule -CollectionName $DeviceCollectionName -RuleName $DeviceCollection -QueryExpression $CollectionTable[$DeviceCollection] -Verbose:$false -ErrorAction Stop | Out-Null

                # Move collection to folder
                if ($PSBoundParameters["FolderName"]) {
                    try {
                        Write-Verbose -Message "Moving device collection to folder: $($FolderName)"
                        $DeviceCollectionObject = Get-CMDeviceCollection -Name $DeviceCollectionName -Verbose:$false -ErrorAction Stop
                        Move-CMObject -InputObject $DeviceCollectionObject -FolderPath "DeviceCollection\$($FolderName)" -Verbose:$false -ErrorAction Stop
                    }
                    catch [System.Exception] {
                        Write-Warning -Message "Unable to move device collection to folder '$($FolderName)', error message: $($_.Exception.Message)"
                    }
                }
            }
            catch [System.Exception] {
                Write-Warning -Message "Unable to create device collection query membership rule, error message: $($_.Exception.Message)"
            }
        }
        catch [System.Exception] {
            Write-Warning -Message "Unable to create device collection, error message: $($_.Exception.Message)"
        }
    }
}
End {
    Set-Location -Path $CurrentLocation
}