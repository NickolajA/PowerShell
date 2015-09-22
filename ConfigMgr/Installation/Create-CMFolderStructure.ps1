[CmdletBinding()]
param(
[parameter(Mandatory=$true)]
$SiteServer,
[parameter(Mandatory=$true)]
$SiteCode
)

function Validate-SiteCode {
    $ValidateSiteCode = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -Filter "SiteCode like '$($SiteCode)'" | Select-Object -ExpandProperty SiteCode
    if ($ValidateSiteCode -match $SiteCode) {
        Write-Output "INFO: Successfully established a connection to the SMS Provider"
    }
    else {
        Write-Output "WARNING: Entered SiteCode does not match with $($SiteServer)"
    }
}

# Create top-level device collection folders
$TLDeviceCollectionFolders = @("Client Management","Production","Development","Limiting Collections","Search Collections","Maintenance Windows","Endpoint Protection","Power Management")
$TLDeviceCollectionFolders | ForEach-Object {
    try {
        $NewFolder = ([WMIClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_ObjectContainerNode").CreateInstance()
        $NewFolder.ObjectType = 5000
        $NewFolder.Name = "$_"
        $NewFolder.ObjectTypeName = "SMS_Collection_Device"
        $NewFolder.ParentContainerNodeID = 0
        $NewFolder.SearchFolder = $false
        $NewFolder.SourceSite = $SiteCode
        $NewFolder.Put() | Out-Null
        $ValidateFolderCreation = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_ObjectContainerNode -ComputerName $SiteServer -Filter "Name like '$($_)'" | Select-Object -ExpandProperty Name
        if ($ValidateFolderCreation -match $_) {
            Write-Output "INFO: Successfully created the '$($_)' device collection folder"
        }
    }
    catch {
        Write-Output $_.Exception.Message
    }
}

# Create sub-level device collection folders
$SLDeviceCollectionFolders = @{
    "Production001" = "OS Deployment"
    "Production002" = "Application Management"
    "Production003" = "Software Updates"
    "Development001" = "OS Deployment"
    "Development002" = "Application Management"
    "Development003" = "Software Updates"
}
$SLDeviceCollectionFolders.GetEnumerator() | ForEach-Object {
    try {
        [string]$CurrentValue = $_.Value
        [string]$CurrentKey = $_.Key.SubString(0,($_.Key.Length-3))
        [int]$ParentContainerNodeID = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_ObjectContainerNode -ComputerName $SiteServer -Filter "Name like '$($CurrentKey)' AND ObjectType = 5000" | Select-Object -ExpandProperty ContainerNodeID
        $NewSubFolder = ([WMIClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_ObjectContainerNode").CreateInstance()
        $NewSubFolder.ObjectType = 5000
        $NewSubFolder.Name = "$CurrentValue"
        $NewSubFolder.ObjectTypeName = "SMS_Collection_Device"
        $NewSubFolder.ParentContainerNodeID = $ParentContainerNodeID
        $NewSubFolder.SearchFolder = $false
        $NewSubFolder.SourceSite = $SiteCode
        $NewSubFolder.Put() | Out-Null
        $ValidateFolderCreation = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_ObjectContainerNode -ComputerName $SiteServer -Filter "Name like '$($CurrentValue)'" | Select-Object -ExpandProperty Name
        if ($ValidateFolderCreation -match $CurrentValue) {
            Write-Output "INFO: Successfully created the '$($CurrentKey)\$($CurrentValue)' device collection folder"
        }
    }
    catch {
        Write-Output $_.Exception.Message
    }
}

# Create top-level task sequence folders
$TLTaskSequenceFolders = @("Production","Development")
$TLTaskSequenceFolders | ForEach-Object {
    try {
        $NewFolder = ([WMIClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_ObjectContainerNode").CreateInstance()
        $NewFolder.ObjectType = 20
        $NewFolder.Name = "$_"
        $NewFolder.ObjectTypeName = "SMS_TaskSequencePackage"
        $NewFolder.ParentContainerNodeID = 0
        $NewFolder.SearchFolder = $false
        $NewFolder.SourceSite = $SiteCode
        $NewFolder.Put() | Out-Null
        $ValidateFolderCreation = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_ObjectContainerNode -ComputerName $SiteServer -Filter "Name like '$($_)'" | Select-Object -ExpandProperty Name
        if ($ValidateFolderCreation -match $_) {
            Write-Output "INFO: Successfully created the '$($_)' task sequence folder"
        }
    }
    catch {
        Write-Output $_.Exception.Message
    }
}

# Create sub-level device collection folders
$SLTaskSequenceFolders = @{
    "Production001" = "OS Deployment"
    "Production002" = "Application Management"
    "Development001" = "OS Deployment"
    "Development002" = "Application Management"
}
$SLTaskSequenceFolders.GetEnumerator() | ForEach-Object {
    try {
        [string]$CurrentValue = $_.Value
        [string]$CurrentKey = $_.Key.SubString(0,($_.Key.Length-3))
        [int]$ParentContainerNodeID = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_ObjectContainerNode -ComputerName $SiteServer -Filter "Name like '$($CurrentKey)' AND ObjectType = 20" | Select-Object -ExpandProperty ContainerNodeID
        $NewSubFolder = ([WMIClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_ObjectContainerNode").CreateInstance()
        $NewSubFolder.ObjectType = 20
        $NewSubFolder.Name = "$CurrentValue"
        $NewSubFolder.ObjectTypeName = "SMS_TaskSequencePackage"
        $NewSubFolder.ParentContainerNodeID = $ParentContainerNodeID
        $NewSubFolder.SearchFolder = $false
        $NewSubFolder.SourceSite = $SiteCode
        $NewSubFolder.Put() | Out-Null
        $ValidateFolderCreation = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_ObjectContainerNode -ComputerName $SiteServer -Filter "Name like '$($CurrentValue)'" | Select-Object -ExpandProperty Name
        if ($ValidateFolderCreation -match $CurrentValue) {
            Write-Output "INFO: Successfully created the '$($CurrentKey)\$($CurrentValue)' task sequence folder"
        }
    }
    catch {
        Write-Output $_.Exception.Message
    }
}