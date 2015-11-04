<#
.SYNOPSIS
    Create a Device Collection folder structure in ConfigMgr 2012
.DESCRIPTION
    Create a Device Collection folder structure in ConfigMgr 2012
.PARAMETER SiteServer
    Site server name with SMS Provider installed
.EXAMPLE
    .\Create-CMDeviceCollectionFolders.ps1 -SiteServer CM01    
.NOTES
    Script name: Create-CMDeviceCollectionFolders.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    DateCreated: 2015-11-02
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer
)
Begin {
    # Determine SiteCode from WMI
    try {
        Write-Verbose -Message "Determining SiteCode for Site Server: '$($SiteServer)'"
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
                Write-Debug -Message "SiteCode: $($SiteCode)"
            }
        }
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to determine SiteCode" ; break
    }
}
Process {
    # Create top-level Device Collection folders
    $DeviceCollectionFolders = @("Application Management","Client Management","Compliance Management","Limiting Collections","Search Collections","Maintenance Windows","Mobile Device Management","Endpoint Protection","Power Management", "OS Deployment", "Software Updates")
    foreach ($DeviceCollectionFolder in $DeviceCollectionFolders) {
        try {
            $Instance = ([WMIClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_ObjectContainerNode").CreateInstance()
            $Instance.ObjectType = 5000
            $Instance.Name = $DeviceCollectionFolder
            $Instance.ObjectTypeName = "SMS_Collection_Device"
            $Instance.ParentContainerNodeID = 0
            $Instance.SearchFolder = $false
            $Instance.SourceSite = $SiteCode
            $Instance.Put() | Out-Null
            $ValidateFolderCreation = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_ObjectContainerNode -ComputerName $SiteServer -Filter "Name like '$($DeviceCollectionFolder)'" | Select-Object -ExpandProperty Name
            if ($ValidateFolderCreation -match $DeviceCollectionFolder) {
                Write-Output "INFO: Successfully created the '$($DeviceCollectionFolder)' device collection folder"
            }
        }
        catch {
            Write-Warning -Message $_.Exception.Message
        }
    }
}

