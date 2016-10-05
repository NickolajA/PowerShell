<#
.SYNOPSIS
    Enumerate all users in a specific collection, get their primary devices and add those to a device collection

.DESCRIPTION
    Enumerate all users in a specific collection, get their primary devices and add those to a device collection

.PARAMETER SiteServer
    Site server name with SMS Provider installed.

.PARAMETER UserCollectionName
    Enter a User Collection name containing the users in scope.

.PARAMETER DeviceCollectionName
    Enter a Device Collection name that Primary Devices for each user specified for the UserCollectionName parameter will be added to.

.EXAMPLE
    .\Add-CMUsersPrimaryDevicesToCollection.ps1 -SiteServer CM01 -UserCollectionName "All Users" -DeviceCollectionName "Test Collection" -Verbose

.NOTES
    FileName:    Add-CMUsersPrimaryDevicesToCollection.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    Created:     2016-10-05
    Updated:     2016-10-05
    
    Version history:
    1.0.0 - (2016-10-05) Script created
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,

    [parameter(Mandatory=$true, HelpMessage="Enter a User Collection name containing the users in scope.")]
    [ValidateNotNullOrEmpty()]
    [string]$UserCollectionName,

    [parameter(Mandatory=$true, HelpMessage="Enter a Device Collection name that Primary Devices for each user specified for the UserCollectionName parameter will be added to.")]
    [ValidateNotNullOrEmpty()]
    [string]$DeviceCollectionName
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
    Set-Location -Path $SiteDrive -ErrorAction Stop -Verbose:$false

    # Disable Fast parameter usage check for Lazy properties
    $CMPSSuppressFastNotUsedCheck = $true
}
Process {
    # Determine User Collection
    $UserCollection = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer -Filter "Name like '$($UserCollectionName)' AND CollectionType = 1"
    if ($UserCollection -ne $null) {
        # Determine Device Collection
        $DeviceCollection = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer -Filter "Name like '$($DeviceCollectionName)' AND CollectionType = 2"
        if ($DeviceCollection -ne $null) {
            # Get all membership rules for User Collection
            $UserCollectionMemberships = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_FullCollectionMembership -ComputerName $SiteServer -Filter "CollectionID like '$($UserCollection.CollectionID)' AND ResourceType = 4"

            # Get Primary Device relationships for each user and add that to target Device Collection
            foreach ($User in $UserCollectionMemberships) {
                $PrimaryDevices = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_UserMachineRelationship -ComputerName $SiteServer -Filter "UniqueUserName like '$([regex]::Escape($User.SMSID))'"
                if ($PrimaryDevices -ne $null) {
                    foreach ($PrimaryDevice in $PrimaryDevices) {
                        Write-Verbose -Message "User '$($User.SMSID)' has adefined relationship with device '$($PrimaryDevice.ResourceName)'"
                        try {
                            Add-CMDeviceCollectionDirectMembershipRule -CollectionId $DeviceCollection.CollectionID -ResourceId $PrimaryDevice.ResourceID -Verbose:$false -ErrorAction Stop
                        }
                        catch [System.Exception] {
                            Write-Warning -Message $_.Exception.Message
                        }
                    }
                }
                else {
                    Write-Verbose -Message "Query for primary device relationships for user '$($User.SMSID)' returned 0 results"
                }
            }
        }
        else {
            Write-Warning -Message "Unable to determine valid device collection object from parameter input"
        }
    }
    else {
        Write-Warning -Message "Unable to determine valid user collection object from parameter input"
    }
}
End {
    Set-Location -Path $CurrentLocation
}