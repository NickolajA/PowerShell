<#
.SYNOPSIS
    Populate Maintenance Windows collections in ConfigMgr with devices sourced from Service Manager

.DESCRIPTION
    This script will populate Maintenance Windows collections in ConfigMgr with devices that have a specific Maintenance Window set in Service Manager.
    The Maintenance Window name defined on the server asset in Service Manager, needs to match the name of a Maintenance Window collection, otherwise the population
    of that server asset will not occur.

    This script also has logic to determining servers missing, including such that does not belong to a Maintenance Window collection. It does this by comparing
    current members in the Maintenance Windows collection with members that should be added sourced from Service Manager.

    To use this script, the Cireson.AssetManagement.HardwareAsset class needs to exist in Service Manager. Maintenance Window is determined from a ServiceWindow 
    property on the objects in Service Manager.

    It's also required to have the SMLets module installed on the system where this script will be executed on.

.PARAMETER SiteServer
    Site server where the SMS Provider is installed.

.PARAMETER SMDefaultComputer
    Value for the Service Manager target server.

.PARAMETER MaintenanceWindowNamePrefix
    Set a prefix used for filtering Maintenance Windows device collections.

.PARAMETER ShowProgress
    Show a progressbar displaying the current operation.

.EXAMPLE
    Populate devices from Service Manager in corresponding Maintenance Windows collections in ConfigMgr:
    Invoke-CMPopulateMaintenanceWindowsDeviceMembers.ps1 -SiteServer CM01 -SMDefaultComputer SCSM01 -ShowProgress

.NOTES
    FileName:    Invoke-CMPopulateMaintenanceWindowsDeviceMembers.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    Created:     2016-04-05
    Updated:     2016-04-18
    Version:     1.0.1
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,

    [parameter(Mandatory=$true, HelpMessage="Value for the Service Manager target server.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SMDefaultComputer,

    [parameter(Mandatory=$false, HelpMessage="Set a prefix used for filtering Maintenance Windows device collections.")]
    [ValidateNotNullOrEmpty()]
    [string]$MaintenanceWindowNamePrefix = "MWS -",

    [parameter(Mandatory=$false, HelpMessage="Show a progressbar displaying the current operation.")]
    [switch]$ShowProgress
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

    # Load SMLets
    try {
        Import-Module -Name SMLets -ErrorAction Stop -Verbose:$false
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        Write-Warning -Message "$($_.Exception.Message). Line: $($_.InvocationInfo.ScriptLineNumber)" ; break
    }

    # Determine current location
    $CurrentLocation = $PSScriptRoot
}
Process {
    # Functions
    function Write-EventLogEntry {
        param(
            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$LogName,

            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$Source,

            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [int]$EventID,

            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [ValidateSet("Information","Warning","Error")]
            [string]$EntryType,

            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$Message
        )
        # Create event log if not exist
        if ([System.Diagnostics.EventLog]::Exists($LogName) -eq $false) {
            try {
                New-EventLog -LogName $LogName -Source $Source -ErrorAction Stop -Verbose:$false | Out-Null
            }
            catch [System.Exception] {
                Write-Warning -Message "$($_.Exception.Message). Line: $($_.InvocationInfo.ScriptLineNumber)" ; break
            }
        }

        # Write event log entry
        try {
            Write-EventLog -LogName $LogName -Source $Source -EntryType $EntryType -EventId $EventID -Message $Message -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message "$($_.Exception.Message). Line: $($_.InvocationInfo.ScriptLineNumber)" ; break
        }
    }

    function New-DirectMembershipRule {
        param(
            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$RuleName,

            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$ResourceID
        )
        # Create a new SMS_CollectionRuleDirect instance and return it
        $DirectMembershipRuleInstance = ([WmiClass]"\\$($SiteServer)\root\SMS\site_$($SiteCode):SMS_CollectionRuleDirect").CreateInstance()
        $DirectMembershipRuleInstance.ResourceClassName = "SMS_R_System"
        $DirectMembershipRuleInstance.ResourceID = $ResourceID
        $DirectMembershipRuleInstance.RuleName = $RuleName
        return $DirectMembershipRuleInstance
    }

    if ($PSBoundParameters["ShowProgress"]) {
        $ProgressCount = 0
    }

    # Begin processing
    Write-EventLogEntry -LogName "ConfigMgr Maintenance Windows" -Source "Maintenance Window Populator" -EventID 1000 -EntryType Information -Message "Initialize processing of server maintenance window memberships."

    # Determine Maintenance Window names from ConfigMgr
    try {
        $MaintenanceWindowCollectionList = New-Object -TypeName System.Collections.ArrayList
        $MaintenanceWindowCollections = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer -Filter "Name like '$($MaintenanceWindowNamePrefix)%'" -ErrorAction Stop | Select-Object -Property Name, CollectionID
        if ($MaintenanceWindowCollections -ne $null) {
            $MaintenanceWindowCollectionList.AddRange(@($MaintenanceWindowCollections))
        }
        else {
            Write-EventLogEntry -LogName "ConfigMgr Maintenance Windows" -Source "Maintenance Window Populator" -EventID 1001 -EntryType Warning -Message "Query for Maintenance Windows collections returned no results, aborting current operation."
        }
    }
    catch [System.Exception] {
        Write-Warning -Message "$($_.Exception.Message). Line: $($_.InvocationInfo.ScriptLineNumber)" ; break
    }

    # Process members for each Maintenance Window
    if ($MaintenanceWindowCollectionList -ne $null) {

        # Get the Cireson HardwareAsset class object
        try {
            $SCSMClass = Get-SCSMClass -Name Cireson.AssetManagement.HardwareAsset -ErrorAction Stop -Verbose:$false
        }
        catch [System.Exception] {
            Write-Warning -Message "$($_.Exception.Message). Line: $($_.InvocationInfo.ScriptLineNumber)" ; break
        }

        # Get Maintenance Windows count
        $MaintenanceWindowsCount = ($MaintenanceWindowCollectionList | Measure-Object).Count

        foreach ($MaintenanceWindowCollection in $MaintenanceWindowCollectionList) {
            # Execution start time
            $StartTime = (Get-Date)

            # Write event log information with beginning of current Maintenance Window
            Write-EventLogEntry -LogName "ConfigMgr Maintenance Windows" -Source "Maintenance Window Populator" -EventID 1002 -EntryType Information -Message "Processing current Maintenance Window collection: $($MaintenanceWindowCollection.Name)"

            # Show progressbar
            if ($PSBoundParameters["ShowProgress"]) {
                $ProgressCount++
                Write-Progress -Activity "Processing Maintenance Window collections" -Id 1 -Status "$($ProgressCount) / $($MaintenanceWindowsCount)" -PercentComplete (($ProgressCount / $MaintenanceWindowsCount) * 100)
            }

            # Determine server objects to either be added or removed from Maintenance Window
            $ServiceWindowID = Get-SCSMEnumeration -ErrorAction Stop -Verbose:$false | Where-Object { $_.DisplayName -eq $MaintenanceWindowCollection.Name } | Select-Object -ExpandProperty ID
            if ($ServiceWindowID -ne $null) {
                $SCSMServers = Get-SCSMObject -Class $SCSMClass -Filter "ServiceWindow -eq $($ServiceWindowID)" | Select-Object -ExpandProperty DisplayName
                $ConfigMgrServers = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_FullCollectionMembership -ComputerName $SiteServer -Filter "CollectionID like '$($MaintenanceWindowCollection.CollectionID)'" | Select-Object -ExpandProperty Name
                if ($SCSMServers -ne $null) {
                    # Compare servers in Maintenance Window with what's set in SCSM
                    $ComparedResults = Compare-Object -ReferenceObject $SCSMServers -DifferenceObject $ConfigMgrServers
                    if (($ComparedResults | Measure-Object).Count -ge 1) {
                        $AddToMaintenanceWindow = $ComparedResults | Where-Object { $_.SideIndicator -like "<=" } | Select-Object -ExpandProperty InputObject
                        $RemoveFromMaintenanceWindow = $ComparedResults | Where-Object { $_.SideIndicator -like "=>" } | Select-Object -ExpandProperty InputObject

                        # Get current Maintenance Window object
                        try {
                            $CurrentMaintenanceWindowCollection = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer -Filter "Name like '$($MaintenanceWindowCollection.Name)'"
                            $CurrentMaintenanceWindowCollection.Get()
                        }
                        catch [System.Exception] {
                            Write-EventLogEntry -LogName "ConfigMgr Maintenance Windows" -Source "Maintenance Window Populator" -EventID 1003 -EntryType Warning -Message "Server '$($SCSMServer.DisplayName)' was not found in Configuration Manager, will not attemp to add resource to Maintenance Window collection."
                        }
                    
                        # Add missing servers to Maintenance Window
                        if ($AddToMaintenanceWindow -ne $null) {
                            # Determine current CollectionRules objects and add them to an ArrayList
                            $DirectMembershipRulesList = New-Object -TypeName System.Collections.ArrayList
                            $DirectMembershipRulesList.AddRange(@($CurrentMaintenanceWindowCollection.CollectionRules))

                            # Handle each server that should be added to the Maintenance Window collection
                            foreach ($SCSMServer in $AddToMaintenanceWindow) {
                                try {
                                    $DeviceResourceID = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_R_System -ComputerName $SiteServer -Filter "Name like '$($SCSMServer)'" -ErrorAction Stop | Select-Object -ExpandProperty ResourceID
                                    $DirectMembershipRulesList.Add((New-DirectMembershipRule -RuleName $SCSMServer -ResourceID $DeviceResourceID)) | Out-Null
                                }
                                catch [System.Exception] {
                                    Write-EventLogEntry -LogName "ConfigMgr Maintenance Windows" -Source "Maintenance Window Populator" -EventID 1004 -EntryType Warning -Message "Server '$($SCSMServer.DisplayName)' was not found in Configuration Manager, will not attemp to add resource to Maintenance Window collection."
                                }
                            }

                            # Update Maintenance Window collection object
                            $CurrentMaintenanceWindowCollection.CollectionRules = $DirectMembershipRulesList
                            $CurrentMaintenanceWindowCollection.Put() | Out-Null
                            Write-EventLogEntry -LogName "ConfigMgr Maintenance Windows" -Source "Maintenance Window Populator" -EventID 1005 -EntryType Information -Message "Successfully populated Maintenance Window '$($MaintenanceWindowCollection.Name)' with $(($AddToMaintenanceWindow | Measure-Object).Count) servers sourced from Service Manager."
                        }

                        # Remove servers from Maintenance Window
                        if ($RemoveFromMaintenanceWindow -ne $null) {
                            # Determine current CollectionRules objects and add them to an ArrayList
                            $DirectMembershipRulesList = New-Object -TypeName System.Collections.ArrayList
                            $DirectMembershipRulesList.AddRange(@($CurrentMaintenanceWindowCollection.CollectionRules))

                            # Handle each server that should be removed from the Maintenance Windows collection
                            foreach ($SCSMServer in $RemoveFromMaintenanceWindow) {
                                if ($SCSMServer -in $DirectMembershipRulesList.RuleName) {
                                    $DirectMembershipRulesList.RemoveAt($DirectMembershipRulesList.RuleName.IndexOf($SCSMServer))
                                }
                            }

                            # Update Maintenance Window collection object
                            $CurrentMaintenanceWindowCollection.CollectionRules = $DirectMembershipRulesList
                            $CurrentMaintenanceWindowCollection.Put() | Out-Null
                            Write-EventLogEntry -LogName "ConfigMgr Maintenance Windows" -Source "Maintenance Window Populator" -EventID 1006 -EntryType Information -Message "Successfully removed $(($RemoveFromMaintenanceWindow | Measure-Object).Count) servers from Maintenance Window '$($MaintenanceWindowCollection.Name)'."
                        }

                        # Refresh
                        $CurrentMaintenanceWindowCollection.RequestRefresh() | Out-Null
                    }
                    else {
                        Write-EventLogEntry -LogName "ConfigMgr Maintenance Windows" -Source "Maintenance Window Populator" -EventID 1007 -EntryType Information -Message "Current Maintenance Window collection '$($MaintenanceWindowCollection.Name)' does not have any changes."
                    }
                }
            }

            # End execution time
            $ExecutionTime = (Get-Date) - $StartTime

            # Write event log information for end of current Maintenance Window
            Write-EventLogEntry -LogName "ConfigMgr Maintenance Windows" -Source "Maintenance Window Populator" -EventID 1008 -EntryType Information -Message "Finished processing current Maintenance Window collection: $($MaintenanceWindowCollection.Name). Operation took $($ExecutionTime.Minutes) min $($ExecutionTime.Seconds) sec."
        }
    }
}
End {
    # Begin processing
    Write-EventLogEntry -LogName "ConfigMgr Maintenance Windows" -Source "Maintenance Window Populator" -EventID 1009 -EntryType Information -Message "Successfully processed server maintenance window collection memberships."

    # Set location to script root
    Set-Location -Path $CurrentLocation
}