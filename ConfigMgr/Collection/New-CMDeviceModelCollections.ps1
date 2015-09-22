<#
.SYNOPSIS
    Create device model collections in ConfigMgr 2012.
.DESCRIPTION
    This script will create collections for device models specified in a text file. You're able to specify a prefix for the collection name with the Prefix parameter. The collection name will
    be constructed from the device model present in the specified text file.
.PARAMETER SiteServer
    Site server name with SMS Provider installed
.PARAMETER FilePath
    Specify the full path to a text file containing the device models
.PARAMETER Prefix
    Specify a prefix for the collection names
.EXAMPLE
    .\New-CMDeviceModelCollections.ps1 -SiteServer CM01 -FilePath "C:\Temp\models.txt" -Prefix "All"
    Create device models collections for all models specified in a file located at 'C:\Temp\models.txt' on a Primary Site server called 'CM01':
.NOTES
    Script name: New-CMDeviceModelCollections.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    DateCreated: 2015-04-10
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,
    [parameter(Mandatory=$true, HelpMessage="Specify the full path to a text file containing the device models")]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern("^[A-Za-z]{1}:\\\w+\\\w+")]
    [ValidateScript({
        # Check if path contains any invalid characters
        if ((Split-Path -Path $_ -Leaf).IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
            throw "$(Split-Path -Path $_ -Leaf) contains invalid characters"
        }
        else {
            # Check if file extension is TXT
            if ([System.IO.Path]::GetExtension((Split-Path -Path $_ -Leaf)) -like ".txt") {
                # Check if the whole directory path exists
                if (-not(Test-Path -Path (Split-Path -Path $_) -PathType Container -ErrorAction SilentlyContinue)) {
                    if ($PSBoundParameters["Force"]) {
                        New-Item -Path (Split-Path -Path $_) -ItemType Directory | Out-Null
                        return $true
                    }
                    else {
                        throw "Unable to locate part of the specified path, use the -Force parameter to create it or specify a valid path"
                    }
                }
                elseif (Test-Path -Path (Split-Path -Path $_) -PathType Container -ErrorAction SilentlyContinue) {
                    return $true
                }
                else {
                    throw "Unhandled error"
                }
            }
            else {
                throw "$(Split-Path -Path $_ -Leaf) contains unsupported file extension. Supported extension is '.xml'"
            }
        }
    })]
    [string]$FilePath,
    [parameter(Mandatory=$false, HelpMessage="Specify a prefix for the collection names")]
    [ValidateNotNullOrEmpty()]
    [string]$Prefix
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
        throw "Unable to determine SiteCode"
    }
    # Load the models from specified text file
    $Models = Get-Content -Path $FilePath
    # Determine date and convert date to DMTF
    $Date = (Get-Date -Hour 00 -Minute 00 -Second 00).AddHours(7)
    $StartTime = [System.Management.ManagementDateTimeconverter]::ToDMTFDateTime($Date)
}
Process {
    $ModelCount = ($Models | Measure-Object).Count
    if ($ModelCount -ge 1) {
        foreach ($Model in $Models) {
            if ($PSBoundParameters["Prefix"]) {
                $FullCollectionName = $Prefix + " " + $Model
            }
            else {
                $FullCollectionName = $Model
            }
            $ValidateCollection = Get-WmiObject -Class "SMS_Collection" -Namespace "root\SMS\site_$($SiteCode)" -Filter "Name like '$($FullCollectionName)'"
            if (-not($ValidateCollection)) {
                try {
                    # Create a new Schedule Token
                    $ScheduleToken = ([WMIClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_ST_RecurInterval").CreateInstance()
                    $ScheduleToken.DayDuration = 0
                    $ScheduleToken.DaySpan = 1
                    $ScheduleToken.HourDuration = 0
                    $ScheduleToken.HourSpan = 0
                    $ScheduleToken.IsGMT = $false
                    $ScheduleToken.MinuteDuration = 0
                    $ScheduleToken.MinuteSpan = 0
                    $ScheduleToken.StartTime = $StartTime
                    # Create new collection
                    $NewDeviceCollection = ([WmiClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_Collection").CreateInstance()
                    $NewDeviceCollection.Name = "$($FullCollectionName)"
                    $NewDeviceCollection.Comment = "Collection for $($FullCollectionName)"
                    $NewDeviceCollection.OwnedByThisSite = $true
                    $NewDeviceCollection.LimitToCollectionID = "SMS00001"
                    $NewDeviceCollection.RefreshSchedule = $ScheduleToken
                    $NewDeviceCollection.RefreshType = 2
                    $NewDeviceCollection.CollectionType = 2
                    $NewDeviceCollection.Put() | Out-Null
                    Write-Verbose -Message "Successfully created the '$($FullCollectionName)' collection"
                }
                catch [Exception] {
                    Write-Warning -Message "Failed to create collection '$($FullCollectionName)'"
                }
                # WQL query expression
                $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COMPUTER_SYSTEM on SMS_G_System_COMPUTER_SYSTEM.ResourceId = SMS_R_System.ResourceId where SMS_G_System_COMPUTER_SYSTEM.Model = '$($Model)'"
                # Query for the new collection
                $Collection = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_Collection -Filter "Name like '$($FullCollectionName)' and CollectionType like '2'"
                # Validate Query syntax  
                $ValidateQuery = Invoke-WmiMethod -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_CollectionRuleQuery -Name ValidateQuery -ArgumentList $QueryExpression
                if ($ValidateQuery) {
                    # Get Lazy properties
                    $Collection.Get()
                    # Create a new rule
                    try {
                        $NewRule = ([WMIClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_CollectionRuleQuery").CreateInstance()
                        $NewRule.QueryExpression = $QueryExpression
                        $NewRule.RuleName = "$($FullCollectionName)"
                        # Commit changes and initiate the collection evaluation
                        $Collection.CollectionRules += $NewRule.psobject.baseobject
                        $Collection.Put() | Out-Null
                        $Collection.RequestRefresh() | Out-Null
                        Write-Verbose -Message "Successfully added a Query Rule for collection '$($FullCollectionName)'"
                    }
                    catch {
                        Write-Warning -Message "Failed to add a Query Rule for collection '$($FullCollectionName)'"
                    }

                }
            }
            else {
                Write-Warning -Message "Collection '$($FullCollectionName)' already exists"
            }
        }
    }
    else {
        Write-Warning -Message "No items was found in specified text file" ; break
    }
}