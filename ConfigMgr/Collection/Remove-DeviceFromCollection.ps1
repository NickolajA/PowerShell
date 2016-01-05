<#
.SYNOPSIS
    Remove a device from range of OSD related device collections in ConfigMgr
.DESCRIPTION
    This script will remove a device from a range of OSD related device collections specified in the CollectionIDList array list.
	If the device is a member of any of the specified device collections, it will be removed. This script is particular useful when
	used together with Status Filter Rules once a task sequence has successfully executed.
.PARAMETER SiteServer
    Site server name with SMS Provider installed
.PARAMETER DeviceName
    Name of the device that will be removed from any specified device collections
.EXAMPLE
    Remove device 'CL001' from any of the specified device collections, on a Primary Site server called 'CM01':
	.\Remove-DeviceFromCollection.ps1 -SiteServer CM01 -DeviceName CL001
.NOTES
    Script name: Remove-DeviceFromCollection.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    DateCreated: 2015-12-11
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server name with SMS Provider installed")]
    [ValidateNotNullorEmpty()]
    [string]$SiteServer,
    [parameter(Mandatory=$true, HelpMessage="Name of the device that will be removed from any specified device collections")]
    [ValidateNotNullorEmpty()]
    [string]$DeviceName
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
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        Write-Warning -Message $_.Exception.Message ; break
    }
}
Process {
    # Functions
    function Write-LogFile {
        param(
            [parameter(Mandatory=$true, HelpMessage="Name of the log file, e.g. 'FileName'. File extension should not be specified")]
            [ValidateNotNullOrEmpty()]
            [string]$Name,
            [parameter(Mandatory=$true, HelpMessage="Value added to the specified log file")]
            [ValidateNotNullOrEmpty()]
            [string]$Value,
            [parameter(Mandatory=$true, HelpMessage="Choose a location where the log file will be created")]
            [ValidateNotNullOrEmpty()]
            [ValidateSet("UserTemp","WindowsTemp")]
            [string]$Location
        )
        # Determine log file location
        switch ($Location) {
            "UserTemp" { $LogLocation = ($env:TEMP + "\") }
            "WindowsTemp" { $LogLocation = ($env:SystemRoot + "\Temp\") }
        }
        # Construct log file name and location
        $LogFile = ($LogLocation + $Name + ".log")
        # Create log file unless it already exists
        if (-not(Test-Path -Path $LogFile -PathType Leaf)) {
            New-Item -Path $LogFile -ItemType File -Force | Out-Null
        }
        # Add value to log file
        Add-Content -Value $Value -LiteralPath $LogFile -Force
    }

    # Get Device ResourceID
    Write-LogFile -Name "RemoveDeviceFromCollection" -Location WindowsTemp -Value "Determine ResourceID for DeviceName: $($DeviceName)"
    $ResourceIDs = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_R_System -Filter "Name like '$($DeviceName)'" | Select-Object -ExpandProperty ResourceID
    foreach ($ResourceID in $ResourceIDs) {
        Write-LogFile -Name "RemoveDeviceFromCollection" -Location WindowsTemp -Value "ResourceID: $($ResourceID)"
        # Determine if DeviceName is a member of OSD collections
        $CollectionIDList = New-Object -TypeName System.Collections.ArrayList
        # ArrayList of all Operating System Collection ID's
        $CollectionIDList.AddRange(@("PS100052","PS1000A8","PS1000A1","PS100053"))
        foreach ($CollectionID in $CollectionIDList) {
            $Collection = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Collection -Filter "CollectionID like '$($CollectionID)'"
            $Collection.Get()
            foreach ($CollectionRule in $Collection.CollectionRules) {
                # Remove Device from collection if there's a Collection Rule matching the DeviceName parameter
                if ($CollectionRule.ResourceID -like $ResourceID) {
                    Write-LogFile -Name "RemoveDeviceFromCollection" -Location WindowsTemp -Value "Removing '$($DeviceName)' from '$($Collection.Name)"
                    $Collection.DeleteMembershipRule($CollectionRule)
                }
            }
        }
    }
}