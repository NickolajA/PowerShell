function Get-CMMSoftwareUpdate {
    <#
    .SYNOPSIS
        Convert a Software Update CI_ID or CI_UniqueID property into KB and Description
    .DESCRIPTION
        Convert a Software Update CI_ID or CI_UniqueID property into KB and Description
    .PARAMETER SiteServer
        Site server name with SMS Provider installed
    .PARAMETER CIID
        Specify the CI_ID to convert to a Software Update
    .PARAMETER CIUniqueID
        Specify the CI_UniqueID to convert to a Software Update
    .EXAMPLE
        ConvertTo-CMSoftwareUpdate -SiteServer CM01 -CIID 16855151
        ConvertTo-CMSoftwareUpdate -SiteServer CM01 -CIUniqueID 79e81e3e-97f6-4059-8a25-6732f8ec0a94
    .NOTES
        Name:        ConvertTo-CMSoftwareUpdate
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        DateCreated: 2015-08-21
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory=$true, ParameterSetName="CIID", HelpMessage="Site server name with SMS Provider installed")]
        [parameter(ParameterSetName="CIUniqueID")]
        [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
        [ValidateNotNullorEmpty()]
        [string]$SiteServer,
        [parameter(Mandatory=$true, ParameterSetName="CIID", HelpMessage="Specify the CI_ID to convert to a Software Update")]
        [ValidateNotNullorEmpty()]
        [string]$CIID,
        [parameter(Mandatory=$true, ParameterSetName="CIUniqueID", HelpMessage="Specify the CI_UniqueID to convert to a Software Update")]
        [ValidateNotNullorEmpty()]
        [string]$CIUniqueID
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
        try {
            if ($PSBoundParameters["CIID"]) {
                $SoftwareUpdates = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_SoftwareUpdate -Filter "CI_ID like '$($CIID)'" -ErrorAction Stop
            }
            if ($PSBoundParameters["CIUniqueID"]) {
                $SoftwareUpdates = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_SoftwareUpdate -Filter "CI_UniqueID like '$($CIUniqueID)'" -ErrorAction Stop
            }
        }
        catch [System.UnauthorizedAccessException] {
            Write-Warning -Message "Access denied" ; break
        }
        catch [System.Exception] {
            Write-Warning -Message $_.Exception.Message ; break
        }
        if ($SoftwareUpdates -ne $null) {
            foreach ($SoftwareUpdate in $SoftwareUpdates) {
                $PSObject = [PSCustomObject]@{
                    ArticleID = "KB" + $SoftwareUpdate.ArticleID
                    Description = $SoftwareUpdate.LocalizedDisplayName
                }
                Write-Output $PSObject
            }
        }
        else {
            Write-Warning -Message "No Software Update was found matching the specified search criteria"
        }
    }
}

function Start-CMMSoftwareUpdateGroupCleanup {
    <#
    .SYNOPSIS
        Perform a clean up of software updates that are a member of certain Software Update Group
    .DESCRIPTION
        Use this script if you need to perform a clean up of expired or superseded Software Updates that are members of a certain Software Upgrade Group in ConfigMgr 2012
    .PARAMETER SiteServer
        Site server name with SMS Provider installed
    .PARAMETER ExpiredOnly
        Only remove expired Software Updates. This includes updates that are both expired and superseded. It does, however, exclude updates that are superseded but not expired
    .PARAMETER RemoveContent
        Remove the content for those Software Updates that will be removed from a Software Upgrade Group
    .PARAMETER ShowProgress
        Show a progressbar displaying the current operation
    .EXAMPLE
        Start-CMMSoftwareUpdateGroupCleanup -SiteServer CM01 -RemoveContent -ShowProgress
        Clean a Software Update Group called 'Critical and Security Patches - 2014-11' from expired and superseded Software Updates, while showing the current progress, on a Primary Site server called 'CM01':
    .NOTES
        Name:        Start-CMMSoftwareUpdateGroupCleanup
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        DateCreated: 2014-11-17
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory=$true,HelpMessage="Site server where the SMS Provider is installed")]
        [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
        [string]$SiteServer,
        [parameter(Mandatory=$false,HelpMessage="Only remove expired Software Updates. This includes updates that are both expired and superseded. It does, however, exclude updates that are superseded but not expired")]
        [switch]$ExpiredOnly,
        [parameter(Mandatory=$false,HelpMessage="Remove the content for those Software Updates that will be removed from a Software Upgrade Group")]
        [switch]$RemoveContent,
        [parameter(Mandatory=$false,HelpMessage="Show a progressbar displaying the current operation")]
        [switch]$ShowProgress
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
    }
    Process {
        try {
            $SUGResults = (Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_AuthorizationList -ComputerName $SiteServer -ErrorAction SilentlyContinue | Measure-Object).Count
            if ($SUGResults -ge 1) {
                $AuthorizationLists = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_AuthorizationList -ComputerName $SiteServer -ErrorAction Stop
                foreach ($AuthorizationList in $AuthorizationLists) {
                    $AuthorizationList = [wmi]"$($AuthorizationList.__PATH)"
                    Write-Verbose -Message "Start processing '$($AuthorizationList.LocalizedDisplayName)'"
                    $UpdatesCount = $AuthorizationList.Updates.Count
                    $UpdatesList = New-Object -TypeName System.Collections.ArrayList
                    $RemovedUpdatesList = New-Object -TypeName System.Collections.ArrayList
                    if ($PSBoundParameters["ShowProgress"]) {
                        $ProgressCount = 0
                    }
                    foreach ($Update in ($AuthorizationList.Updates)) {
                        $CIID = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_SoftwareUpdate -ComputerName $SiteServer -Filter "CI_ID = '$($Update)'" -ErrorAction Stop
                        if ($PSBoundParameters["ShowProgress"]) {
                            $ProgressCount++
                            Write-Progress -Activity "Processing Software Updates in '$($AuthorizationList.LocalizedDisplayName)'" -Id 1 -Status "$($ProgressCount) / $($UpdatesCount)" -CurrentOperation "$($CIID.LocalizedDisplayName)" -PercentComplete (($ProgressCount / $UpdatesCount) * 100)
                        }
                        if ($CIID.IsExpired -eq $true) {
                            #Write-Verbose -Message "Update '$($CIID.LocalizedDisplayName)' was expired and will be removed from '$($AuthorizationList.LocalizedDisplayName)'"
                            if ($CIID.CI_ID -notin $RemovedUpdatesList) {
                                $RemovedUpdatesList.Add($CIID.CI_ID) | Out-Null
                            }
                        }
                        elseif (($CIID.IsSuperseded -eq $true) -and (-not($PSBoundParameters["ExpiredOnly"]))) {
                            #Write-Verbose -Message "Update '$($CIID.LocalizedDisplayName)' was superseded and will be removed from '$($AuthorizationList.LocalizedDisplayName)'"
                            if ($CIID.CI_ID -notin $RemovedUpdatesList) {
                                $RemovedUpdatesList.Add($CIID.CI_ID) | Out-Null
                            }
                        }
                        else {
                            if ($CIID.CI_ID -notin $UpdatesList) {
                                $UpdatesList.Add($CIID.CI_ID) | Out-Null
                            }
                        }
                    }
                    # Process the list of Updates added to the ArrayList only if the count is less what's in the actualy Software Update Group
                    if ($UpdatesCount -gt $UpdatesList.Count) {
                        try {
                            if ($PSCmdlet.ShouldProcess("$($AuthorizationList.LocalizedDisplayName)","Clean '$($UpdatesCount - ($UpdatesList.Count))' updates")) {
                                $AuthorizationList.Updates = $UpdatesList
                                $AuthorizationList.Put() | Out-Null
                                Write-Verbose -Message "Successfully cleaned up $($UpdatesCount - ($UpdatesList.Count)) updates from '$($AuthorizationList.LocalizedDisplayName)'"
                            }
                            # Remove content for each CI_ID in the RemovedUpdatesList array
                            if ($PSBoundParameters["RemoveContent"]) {
                                try {
                                    $DeploymentPackageList = New-Object -TypeName System.Collections.ArrayList
                                    foreach ($CI_ID in $RemovedUpdatesList) {
                                        Write-Verbose -Message "Collecting content data for CI_ID: $($CI_ID)"
                                        $ContentData = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Query "SELECT SMS_PackageToContent.ContentID,SMS_PackageToContent.PackageID from SMS_PackageToContent JOIN SMS_CIToContent on SMS_CIToContent.ContentID = SMS_PackageToContent.ContentID where SMS_CIToContent.CI_ID in ($($CI_ID))" -ComputerName $SiteServer -ErrorAction Stop
                                        Write-Verbose -Message "Found '$(($ContentData | Measure-Object).Count)' objects"
                                        foreach ($Content in $ContentData) {
                                            $ContentID = $Content | Select-Object -ExpandProperty ContentID
                                            $PackageID = $Content | Select-Object -ExpandProperty PackageID
                                            $DeploymentPackage = [wmi]"\\$($SiteServer)\root\SMS\site_$($SiteCode):SMS_SoftwareUpdatesPackage.PackageID='$($PackageID)'"
                                            if ($DeploymentPackage.PackageID -notin $DeploymentPackageList) {
                                                $DeploymentPackageList.Add($DeploymentPackage.PackageID) | Out-Null
                                            }
                                            if ($PSCmdlet.ShouldProcess("$($PackageID)","Remove ContentID '$($ContentID)'")) {
                                                Write-Verbose -Message "Attempting to remove ContentID '$($ContentID)' from PackageID '$($PackageID)'"
                                                $ReturnValue = $DeploymentPackage.RemoveContent($ContentID, $false)
                                                if ($ReturnValue.ReturnValue -eq 0) {
                                                    Write-Verbose -Message "Successfully removed ContentID '$($ContentID)' from PackageID '$($PackageID)'"
                                                }
                                            }
                                        }
                                    }
                                }
                                catch [Exception] {
                                    Write-Warning -Message "An error occured when attempting to remove ContentID '$($ContentID)' from '$($PackageID)'"
                                }
                            }
                        }
                        catch [Exception] {
                            Write-Warning -Message "Unable to save changes to '$($AuthorizationList.LocalizedDisplayName)'" ; break
                        }
                    }
                    else {
                        Write-Verbose -Message "No changes detected, will not update '$($AuthorizationList.LocalizedDisplayName)'"
                    }
                    # Refresh content source for all Deployment Packages in the DeploymentPackageList array
                    if (($DeploymentPackageList.Count -ge 1) -and ($PSBoundParameters["RemoveContent"])) {
                        foreach ($DPackageID in $DeploymentPackageList) {
                            if ($PSCmdlet.ShouldProcess("$($DPackageID)","Refresh content source")) {
                                $DPackage = [wmi]"\\$($SiteServer)\root\SMS\site_$($SiteCode):SMS_SoftwareUpdatesPackage.PackageID='$($DPackageID)'"
                                Write-Verbose -Message "Attempting to refresh content source for Deployment Package '$($DPackage.Name)'"
                                $ReturnValue = $DPackage.RefreshPkgSource()
                                if ($ReturnValue.ReturnValue -eq 0) {
                                    Write-Verbose -Message "Successfully refreshed content source for Deployment Package '$($DPackage.Name)'"
                                }
                            }
                        }
                    }
                }
            }
            else {
                Write-Warning -Message "Unable to locate any Software Update Groups"
            }
        }
        catch [Exception] {
            Throw $_.Exception.Message
        }
    }
    End {
        if ($PSBoundParameters["ShowProgress"]) {
            Write-Progress -Activity "Enumerating Software Updates" -Completed -ErrorAction SilentlyContinue
        }
    }
}

function Export-CMMQuery {
    <#
    .SYNOPSIS
        Export a single or all custom Queries to a XML file
    .DESCRIPTION
        Export a single or all custom Queries to a XML file. This file can later be used to import the Queries again.
    .PARAMETER SiteServer
        Site server name with SMS Provider installed
    .PARAMETER Name
        Name of a Query
    .PARAMETER Path
        Specify a valid path to where the XML file containing the Queries will be stored
    .PARAMETER Recurse
        Export all custom Queries
    .PARAMETER Force
        Will overwrite any existing XML files specified in the Path parameter
    .EXAMPLE
        Export-CMMQuery -SiteServer CM01 -Name "OSD - Windows 8.1 Enterprise 64-bit" -Path "C:\Export\Query.xml" -Force
        Export a Query called 'OSD - Windows 8.1 Enterprise 64-bit' to 'C:\Export\Query.xml' and overwrite if file already exists, on a Primary Site server called 'CM01':
    .NOTES
        Name:        Export-CMMQuery
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        DateCreated: 2015-05-17
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory=$true, ParameterSetName="Multiple", HelpMessage="Site server where the SMS Provider is installed")]
        [parameter(ParameterSetName="Single")]
        [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
        [ValidateNotNullOrEmpty()]
        [string]$SiteServer,
        [parameter(Mandatory=$false, ParameterSetName="Single", HelpMessage="Name of the Query")]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        [parameter(Mandatory=$true, ParameterSetName="Multiple", HelpMessage="Specify a valid path to where the XML file containing the Queries will be stored")]
        [parameter(ParameterSetName="Single")]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("^[A-Za-z]{1}:\\\w+\\\w+")]
        [ValidateScript({
            if ((Split-Path -Path $_ -Leaf).IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
                Throw "$(Split-Path -Path $_ -Leaf) contains invalid characters"
            }
            else {
                if ([System.IO.Path]::GetExtension((Split-Path -Path $_ -Leaf)) -like ".xml") {
                    return $true
                }
                else {
                    Throw "$(Split-Path -Path $_ -Leaf) contains unsupported file extension. Supported extensions are '.xml'"
                }
            }
        })]
        [string]$Path,
        [parameter(Mandatory=$false, ParameterSetName="Multiple", HelpMessage="Export all custom Queries")]
        [switch]$Recurse,
        [parameter(Mandatory=$false, ParameterSetName="Multiple", HelpMessage="Will overwrite any existing XML files specified in the Path parameter")]
        [parameter(ParameterSetName="Single")]
        [switch]$Force
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
        # See if XML file exists
        if ([System.IO.File]::Exists($Path)) {
            if (-not($PSBoundParameters["Force"])) {
                Throw "Error creating '$($Path)', file already exists"
            }
        }
    }
    Process {
        # Construct XML document
        $XMLData = New-Object -TypeName System.Xml.XmlDocument
        $XMLRoot = $XMLData.CreateElement("ConfigurationManager")
        $XMLData.AppendChild($XMLRoot) | Out-Null
        $XMLRoot.SetAttribute("Description", "Export of Queries")
        # Get custom Queries
        try {
            if ($PSBoundParameters["Recurse"]) {
                Write-Verbose -Message "Query: SELECT * FROM SMS_Query WHERE (QueryID not like 'SMS%') AND (TargetClassName like 'SMS_StatusMessage')"
                $Queries = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Query -ComputerName $SiteServer -Filter "(QueryID not like 'SMS%') AND (TargetClassName not like 'SMS_StatusMessage')" -ErrorAction Stop
                $WmiFilter = "(QueryID not like 'SMS%') AND (TargetClassName not like 'SMS_StatusMessage')"
            }
            elseif ($PSBoundParameters["Name"]) {
                if (($Name.StartsWith("*")) -and ($Name.EndsWith("*"))) {
                    Write-Verbose -Message "Query: SELECT * FROM SMS_Query WHERE (Name like '%$($Name.Replace('*',''))%') AND (QueryID not like 'SMS%') AND (TargetClassName not like 'SMS_StatusMessage')"
                    $WmiFilter = "(Name like '%$($Name)%') AND (QueryID not like 'SMS%') AND (TargetClassName not like 'SMS_StatusMessage')"
                }
                elseif ($Name.StartsWith("*")) {
                    Write-Verbose -Message "Query: SELECT * FROM SMS_Query WHERE (Name like '%$($Name.Replace('*',''))') AND (QueryID not like 'SMS%') AND (TargetClassName not like 'SMS_StatusMessage')"
                    $WmiFilter = "(Name like '%$($Name)') AND (QueryID not like 'SMS%') AND (TargetClassName not like 'SMS_StatusMessage')"
                }
                elseif ($Name.EndsWith("*")) {
                    Write-Verbose -Message "Query: SELECT * FROM SMS_Query WHERE (Name like '$($Name.Replace('*',''))%') AND (QueryID not like 'SMS%') AND (TargetClassName not like 'SMS_StatusMessage')"
                    $WmiFilter = "(Name like '$($Name)%') AND (QueryID not like 'SMS%') AND (TargetClassName not like 'SMS_StatusMessage')"
                }
                else {
                    Write-Verbose -Message "Query: SELECT * FROM SMS_Query WHERE (Name like '$($Name)') AND (QueryID not like 'SMS%') AND (TargetClassName not like 'SMS_StatusMessage')"
                    $WmiFilter = "(Name like '$($Name)') AND (QueryID not like 'SMS%') AND (TargetClassName not like 'SMS_StatusMessage')"
                }
                if ($Name -match "\*") {
                    $Name = $Name.Replace("*","")
                    $WmiFilter = $WmiFilter.Replace("*","")
                }
            }
            $Queries = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Query -ComputerName $SiteServer -Filter $WmiFilter -ErrorAction Stop
            $QueryResultCount = ($Queries | Measure-Object).Count
            if ($QueryResultCount -gt 1) {
                Write-Verbose -Message "Query returned $($QueryResultCount) results"
            }
            else {
                Write-Verbose -Message "Query returned $($QueryResultCount) result"
            }
            if ($Queries -ne $null) {
                foreach ($Query in $Queries) {
                    $XMLQuery = $XMLData.CreateElement("Query")
                    $XMLData.ConfigurationManager.AppendChild($XMLQuery) | Out-Null
                    $XMLQueryName = $XMLData.CreateElement("Name")
                    $XMLQueryName.InnerText = ($Query | Select-Object -ExpandProperty Name)
                    $XMLQueryExpression = $XMLData.CreateElement("Expression")
                    $XMLQueryExpression.InnerText = ($Query | Select-Object -ExpandProperty Expression)
                    $XMLQueryLimitToCollectionID = $XMLData.CreateElement("LimitToCollectionID")
                    $XMLQueryLimitToCollectionID.InnerText = ($Query | Select-Object -ExpandProperty LimitToCollectionID)
                    $XMLQueryTargetClassName = $XMLData.CreateElement("TargetClassName")
                    $XMLQueryTargetClassName.InnerText = ($Query | Select-Object -ExpandProperty TargetClassName)
                    $XMLQuery.AppendChild($XMLQueryName) | Out-Null
                    $XMLQuery.AppendChild($XMLQueryExpression) | Out-Null
                    $XMLQuery.AppendChild($XMLQueryLimitToCollectionID) | Out-Null
                    $XMLQuery.AppendChild($XMLQueryTargetClassName) | Out-Null
                    Write-Verbose -Message "Exported '$($XMLQueryName.InnerText)' to '$($Path)'"
                }
            }
            else {
                Write-Verbose -Message "Query did not return any objects"
            }
        }
        catch [Exception] {
            Throw $_.Exception.Message
        }
    }
    End {
        # Save XML data to file specified in $Path parameter
        $XMLData.Save($Path) | Out-Null
    }
}

function Import-CMMQuery {
    <#
    .SYNOPSIS
        Import a set of exported custom Queries to ConfigMgr 2012
    .DESCRIPTION
        When you've exported a set of custom Queries with Export-CMQuery, you can use this script import them back into ConfigMgr 2012
    .PARAMETER SiteServer
        Site server name with SMS Provider installed
    .PARAMETER Path
        Specify a valid path to where the XML file containing the exported Queries is located
    .EXAMPLE
        Import-CMMQuery -SiteServer CM01 -Path "C:\Export\Query.xml" -Verbose
        Import all Queries from the file 'C:\Export\Query.xml' on a Primary Site server called 'CM01':
    .NOTES
        Name:        Import-CMMQuery
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        DateCreated: 2015-05-17
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed")]
        [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
        [ValidateNotNullOrEmpty()]
        [string]$SiteServer,
        [parameter(Mandatory=$true, HelpMessage="Specify a valid path to where the XML file containing the Queries will be stored")]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("^[A-Za-z]{1}:\\\w+\\\w+")]
        [ValidateScript({
            # Check if path contains any invalid characters
            if ((Split-Path -Path $_ -Leaf).IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
                Throw "$(Split-Path -Path $_ -Leaf) contains invalid characters"
            }
            else {
                # Check if file extension is XML
                if ([System.IO.Path]::GetExtension((Split-Path -Path $_ -Leaf)) -like ".xml") {
                    # Check if the whole path exists
                    if (Test-Path -Path $_ -PathType Leaf) {
                            return $true
                    }
                    else {
                        Throw "Unable to locate part of or the whole specified path, specify a valid path to an exported XML file"
                    }
                }
                else {
                    Throw "$(Split-Path -Path $_ -Leaf) contains an unsupported file extension. Supported extension is '.xml'"
                }
            }
        })]
        [string]$Path
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
        # Get XML file and construct XML document
        [xml]$XMLData = Get-Content -Path $Path
        # Get all custom Queries
        try {
            if ($XMLData.ConfigurationManager.Description -like "Export of Queries") {
                Write-Verbose -Message "Successfully validated XML document"
            }
            else {
                Write-Warning -Message "Invalid XML document loaded" ; break
            }
            foreach ($Query in ($XMLData.ConfigurationManager.Query)) {
                $NewInstance = ([WmiClass]"\\$($SiteServer)\root\SMS\site_$($SiteCode):SMS_Query").CreateInstance()
                $NewInstance.Name = $Query.Name
                $NewInstance.Expression = $Query.Expression
                $NewInstance.TargetClassName = $Query.TargetClassName
                $NewInstance.Put() | Out-Null
                Write-Verbose -Message "Imported query '$($Query.Name)' successfully"
            }
        }
        catch [System.UnauthorizedAccessException] {
            Write-Warning -Message "Access denied" ; break
        }
        catch [System.Exception] {
            Write-Warning -Message $_.Exception.Message ; break
        }
    }
}

function Export-CMMStatusMessageQuery {
    <#
    .SYNOPSIS
        Export a single or all custom Status Message Queries to a XML file
    .DESCRIPTION
        Export a single or all custom Status Message Queries to a XML file. This file can later be used to import the Status Message Queries again.
    .PARAMETER SiteServer
        Site server name with SMS Provider installed
    .PARAMETER Name
        Name of a Status Message Query
    .PARAMETER Path
        Specify a valid path to where the XML file containing the Status Message Queries will be stored
    .PARAMETER Recurse
        Export all custom Status Message Queries
    .PARAMETER Force
        Will overwrite any existing XML files specified in the Path parameter
    .EXAMPLE
        Export-CMMStatusMessageQuery -SiteServer CM01 -Name "OSD - Windows 8.1 Enterprise 64-bit" -Path "C:\Export\SMQuery.xml" -Force
        Export a Status Message Query called 'OSD - Windows 8.1 Enterprise 64-bit' to 'C:\Export\SMQuery.xml' and overwrite if file already exists, on a Primary Site server called 'CM01':

        Export-CMMStatusMessageQuery -SiteServer CM01 -Recurse -Path "C:\Export\SMQuery.xml" -Force
        Export all custom Status Message Queries to 'C:\Export\SMQuery.xml' and overwrite if file already exists, on a Primary Site server called 'CM01':
    .NOTES
        Name:        Export-CMMStatusMessageQuery
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        DateCreated: 2014-12-30
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory=$true, ParameterSetName="Multiple", HelpMessage="Site server where the SMS Provider is installed")]
        [parameter(ParameterSetName="Single")]
        [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
        [ValidateNotNullOrEmpty()]
        [string]$SiteServer,
        [parameter(Mandatory=$false, ParameterSetName="Single", HelpMessage="Name of a Status Message Query")]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        [parameter(Mandatory=$true, ParameterSetName="Multiple", HelpMessage="Specify a valid path to where the XML file containing the Status Message Queries will be stored")]
        [parameter(ParameterSetName="Single")]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("^[A-Za-z]{1}:\\\w+\\\w+")]
        [ValidateScript({
            if ((Split-Path -Path $_ -Leaf).IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
                Throw "$(Split-Path -Path $_ -Leaf) contains invalid characters"
            }
            else {
                if ([System.IO.Path]::GetExtension((Split-Path -Path $_ -Leaf)) -like ".xml") {
                    return $true
                }
                else {
                    Throw "$(Split-Path -Path $_ -Leaf) contains unsupported file extension. Supported extensions are '.xml'"
                }
            }
        })]
        [string]$Path,
        [parameter(Mandatory=$false, ParameterSetName="Multiple", HelpMessage="Export all custom Status Message Queries")]
        [switch]$Recurse,
        [parameter(Mandatory=$false, ParameterSetName="Multiple", HelpMessage="Will overwrite any existing XML files specified in the Path parameter")]
        [parameter(ParameterSetName="Single")]
        [switch]$Force
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
        # See if XML file exists
        if ([System.IO.File]::Exists($Path)) {
            if (-not($PSBoundParameters["Force"])) {
                Throw "Error creating '$($Path)', file already exists"
            }
        }
    }
    Process {
        # Construct XML document
        $XMLData = New-Object -TypeName System.Xml.XmlDocument
        $XMLRoot = $XMLData.CreateElement("ConfigurationManager")
        $XMLData.AppendChild($XMLRoot) | Out-Null
        $XMLRoot.SetAttribute("Description", "Export of Status Message Queries")
        # Get custom Status Message Queries
        try {
            if ($PSBoundParameters["Recurse"]) {
                Write-Verbose -Message "Query: SELECT * FROM SMS_Query WHERE (QueryID not like 'SMS%') AND (TargetClassName like 'SMS_StatusMessage')"
                $StatusMessageQueries = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Query -ComputerName $SiteServer -Filter "(QueryID not like 'SMS%') AND (TargetClassName like 'SMS_StatusMessage')" -ErrorAction Stop
                $WmiFilter = "(QueryID not like 'SMS%') AND (TargetClassName like 'SMS_StatusMessage')"
            }
            elseif ($PSBoundParameters["Name"]) {
                if (($Name.StartsWith("*")) -and ($Name.EndsWith("*"))) {
                    Write-Verbose -Message "Query: SELECT * FROM SMS_Query WHERE (Name like '%$($Name.Replace('*',''))%') AND (QueryID not like 'SMS%') AND (TargetClassName like 'SMS_StatusMessage')"
                    $WmiFilter = "(Name like '%$($Name)%') AND (QueryID not like 'SMS%') AND (TargetClassName like 'SMS_StatusMessage')"
                }
                elseif ($Name.StartsWith("*")) {
                    Write-Verbose -Message "Query: SELECT * FROM SMS_Query WHERE (Name like '%$($Name.Replace('*',''))') AND (QueryID not like 'SMS%') AND (TargetClassName like 'SMS_StatusMessage')"
                    $WmiFilter = "(Name like '%$($Name)') AND (QueryID not like 'SMS%') AND (TargetClassName like 'SMS_StatusMessage')"
                }
                elseif ($Name.EndsWith("*")) {
                    Write-Verbose -Message "Query: SELECT * FROM SMS_Query WHERE (Name like '$($Name.Replace('*',''))%') AND (QueryID not like 'SMS%') AND (TargetClassName like 'SMS_StatusMessage')"
                    $WmiFilter = "(Name like '$($Name)%') AND (QueryID not like 'SMS%') AND (TargetClassName like 'SMS_StatusMessage')"
                }
                else {
                    Write-Verbose -Message "Query: SELECT * FROM SMS_Query WHERE (Name like '$($Name)') AND (QueryID not like 'SMS%') AND (TargetClassName like 'SMS_StatusMessage')"
                    $WmiFilter = "(Name like '$($Name)') AND (QueryID not like 'SMS%') AND (TargetClassName like 'SMS_StatusMessage')"
                }
                if ($Name -match "\*") {
                    $Name = $Name.Replace("*","")
                    $WmiFilter = $WmiFilter.Replace("*","")
                }
            }
            $StatusMessageQueries = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Query -ComputerName $SiteServer -Filter $WmiFilter -ErrorAction Stop
            $QueryResultCount = ($StatusMessageQueries | Measure-Object).Count
            if ($QueryResultCount -gt 1) {
                Write-Verbose -Message "Query returned $($QueryResultCount) results"
            }
            else {
                Write-Verbose -Message "Query returned $($QueryResultCount) result"
            }
            if ($StatusMessageQueries -ne $null) {
                foreach ($StatusMessageQuery in $StatusMessageQueries) {
                    $XMLQuery = $XMLData.CreateElement("Query")
                    $XMLData.ConfigurationManager.AppendChild($XMLQuery) | Out-Null
                    $XMLQueryName = $XMLData.CreateElement("Name")
                    $XMLQueryName.InnerText = ($StatusMessageQuery | Select-Object -ExpandProperty Name)
                    $XMLQueryExpression = $XMLData.CreateElement("Expression")
                    $XMLQueryExpression.InnerText = ($StatusMessageQuery | Select-Object -ExpandProperty Expression)
                    $XMLQueryLimitToCollectionID = $XMLData.CreateElement("LimitToCollectionID")
                    $XMLQueryLimitToCollectionID.InnerText = ($StatusMessageQuery | Select-Object -ExpandProperty LimitToCollectionID)
                    $XMLQueryTargetClassName = $XMLData.CreateElement("TargetClassName")
                    $XMLQueryTargetClassName.InnerText = ($StatusMessageQuery | Select-Object -ExpandProperty TargetClassName)
                    $XMLQuery.AppendChild($XMLQueryName) | Out-Null
                    $XMLQuery.AppendChild($XMLQueryExpression) | Out-Null
                    $XMLQuery.AppendChild($XMLQueryLimitToCollectionID) | Out-Null
                    $XMLQuery.AppendChild($XMLQueryTargetClassName) | Out-Null
                    Write-Verbose -Message "Exported '$($XMLQueryName.InnerText)' to '$($Path)'"
                }
            }
            else {
                Write-Verbose -Message "Query did not return any objects"
            }
        }
        catch [Exception] {
            Throw $_.Exception.Message
        }
    }
    End {
        # Save XML data to file specified in $Path parameter
        $XMLData.Save($Path) | Out-Null
    }
}

function Import-CMMStatusMessageQuery {
    <#
    .SYNOPSIS
        Import a set of exported custom Status Message Queries to ConfigMgr 2012
    .DESCRIPTION
        When you've exported a set of custom Status Message Queries with Export-CMStatusMessageQuery, you can use this script import them back into ConfigMgr 2012
    .PARAMETER SiteServer
        Site server name with SMS Provider installed
    .PARAMETER Path
        Specify a valid path to where the XML file containing the exported Status Message Queries is located
    .EXAMPLE
        Import-CMMStatusMessageQuery -SiteServer CM01 -Path "C:\Export\SMQuery.xml" -Verbose
        Import all Status Message Queries from the file 'C:\Export\SMQuery.xml' on a Primary Site server called 'CM01':
    .NOTES
        Name:        Import-CMMStatusMessageQuery
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        DateCreated: 2015-01-12
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed")]
        [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
        [ValidateNotNullOrEmpty()]
        [string]$SiteServer,
        [parameter(Mandatory=$true, HelpMessage="Specify a valid path to where the XML file containing the Status Message Queries will be stored")]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("^[A-Za-z]{1}:\\\w+\\\w+")]
        [ValidateScript({
            # Check if path contains any invalid characters
            if ((Split-Path -Path $_ -Leaf).IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
                Throw "$(Split-Path -Path $_ -Leaf) contains invalid characters"
            }
            else {
                # Check if file extension is XML
                if ([System.IO.Path]::GetExtension((Split-Path -Path $_ -Leaf)) -like ".xml") {
                    # Check if the whole path exists
                    if (Test-Path -Path $_ -PathType Leaf) {
                            return $true
                    }
                    else {
                        Throw "Unable to locate part of or the whole specified path, specify a valid path to an exported XML file"
                    }
                }
                else {
                    Throw "$(Split-Path -Path $_ -Leaf) contains an unsupported file extension. Supported extension is '.xml'"
                }
            }
        })]
        [string]$Path
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
    }
    Process {
        # Get XML file and construct XML document
        [xml]$XMLData = Get-Content -Path $Path
        # Get all custom Status Message Queries
        try {
            if ($XMLData.ConfigurationManager.Description -like "Export of Status Message Queries") {
                Write-Verbose -Message "Successfully validated XML document"
            }
            else {
                Throw "Invalid XML document loaded"
            }
            foreach ($Query in ($XMLData.ConfigurationManager.Query)) {
                $NewInstance = ([WmiClass]"\\$($SiteServer)\root\SMS\site_$($SiteCode):SMS_Query").CreateInstance()
                $NewInstance.Name = $Query.Name
                $NewInstance.Expression = $Query.Expression
                $NewInstance.TargetClassName = $Query.TargetClassName
                $NewInstance.Put() | Out-Null
                Write-Verbose -Message "Imported query '$($Query.Name)' successfully"
            }
        }
        catch [Exception] {
            Throw $_.Exception.Message
        }
    }
}

function Get-CMMDisabledProgram {
    <#
    .SYNOPSIS
        List all Disabled Programs of Packages in ConfigMgr 2012
    .DESCRIPTION
        Use this script to list all of the disabled Programs for each Package in ConfigMgr 2012. This script will also give you the option to enable those Programs.
    .PARAMETER SiteServer
        Site server name with SMS Provider installed
    .PARAMETER Enable
        Specify this switch only if you wish to enable the disable Programs. Don't specify it if you wish to only list the disabled Programs.
    .EXAMPLE
        Get-CMMDisabledPrograms -SiteServer CM01 -Verbose
        Lists all disabled Programs and their Package Name association on a Primary Site server called 'CM01':
    .NOTES
        Name:        Get-CMMDisabledPrograms
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        DateCreated: 2015-03-10
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed")]
        [ValidateNotNullOrEmpty()]
        [string]$SiteServer,
        [parameter(Mandatory=$false, HelpMessage="Enable disabled programs")]
        [switch]$Enable
    )
    Begin {
        # Determine SiteCode from WMI
        try {
            Write-Verbose "Determining SiteCode for Site Server: '$($SiteServer)'"
            $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop -Verbose:$false
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
        # Get current location
        $CurrentLocation = $PSScriptRoot
        # Load ConfigMgr module
        try {
            $SiteDrive = $SiteCode + ":"
            Import-Module -Name ConfigurationManager -ErrorAction Stop
        }
        catch [System.UnauthorizedAccessException] {
            Write-Warning -Message "Access denied" ; break
        }
        catch [System.Exception] {
            try {
                Import-Module (Join-Path -Path (($env:SMS_ADMIN_UI_PATH).Substring(0,$env:SMS_ADMIN_UI_PATH.Length-5)) -ChildPath "\ConfigurationManager.psd1") -Force -ErrorAction Stop
                if ((Get-PSDrive $SiteCode -ErrorAction SilentlyContinue | Measure-Object).Count -ne 1) {
                    New-PSDrive -Name $SiteCode -PSProvider "AdminUI.PS.Provider\CMSite" -Root $SiteServer -ErrorAction Stop
                }
            }
            catch [System.UnauthorizedAccessException] {
                Write-Warning -Message "Access denied" ; break
            }
            catch [System.Exception] {
                Write-Warning -Message "$($_.Exception.Message) $($_.InvocationInfo.ScriptLineNumber)" ; break
            }
        }
        # Set location to the CMSite drive
        Set-Location -Path $SiteDrive -ErrorAction Stop
    }
    Process {
        # Change location to the Site Drive
        Set-Location $SiteDrive -Verbose:$false
        # Get all Programs
        $Programs = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Program -ComputerName $SiteServer -Verbose:$false
        if ($Programs -ne $null) {
            foreach ($Program in $Programs) {
                if ($Program.ProgramFlags -eq ($Program.ProgramFlags -bor "0x00001000")) {
                    $PSObject = [PSCustomObject]@{
                        "PackageName" = $Program.PackageName
                        "ProgramName" = $Program.ProgramName
                    }
                    if ($PSBoundParameters["Enable"]) {
                        Write-Verbose -Message "Enabling program '$($Program.ProgramName)' for package '$($Program.PackageName)'"
                        try {
                            Get-CMProgram -ProgramName $Program.ProgramName -PackageId $Program.PackageID -Verbose:$false | Enable-CMProgram -Verbose:$false -ErrorAction Stop
                        }
                        catch {
                            Write-Warning -Message "Unable to enable program '$($Program.ProgramName)' for package '$($Program.PackageName)'"
                        }
                    }
                    else {
                        Write-Output $PSObject
                    }
                }
            }
        }
        else {
            Write-Warning -Message "No Programs found"
        }
    }
    End {
        Set-Location -Path $CurrentLocation
    }
}

function Update-CMMContentSourceTool {
    <#
    .SYNOPSIS
        Graphical user interface tool that can update content source location for all object types in ConfigMgr 2012
    .DESCRIPTION
        Use this tool if you have to update any or all object types respective content source location. You have the opportunity to select to update either all objects of a certain type, or just a selection of them.
    .PARAMETER SiteServer
        Site server name with SMS Provider installed
    .EXAMPLE
        Update-CMMContentSourceTool -SiteServer CM01
        Invoke the content source update tool against a Primary Site server called 'CM01':
    .NOTES
        Name:        Update-CMMContentSourceTool
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        DateCreated: 2015-08-22
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory=$true, HelpMessage="Specify the Primary Site server")]
        [ValidateNotNullOrEmpty()]
        [string]$SiteServer
    )
    Begin {
        # Determine Site Code
        try {
            $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
            foreach ($SiteCodeObject in $SiteCodeObjects) {
                if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                    $SiteCode = $SiteCodeObject.SiteCode
                }
            }
        }
        catch [System.UnauthorizedAccessException] {
	        Write-Warning -Message "Access denied" ; break
        }
        catch [System.Exception] {
	        Write-Warning -Message "Unable to determine Site Code" ; break
        }
        # Assemblies
        try {
            Add-Type -AssemblyName "System.Drawing" -ErrorAction Stop
            Add-Type -AssemblyName "System.Windows.Forms" -ErrorAction Stop
        }
        catch [System.UnauthorizedAccessException] {
	        Write-Warning -Message "Access denied when attempting to load required assemblies" ; break
        }
        catch [System.Exception] {
	        Write-Warning -Message "Unable to load required assemblies. Error message: $($_.Exception.Message) Line: $($_.InvocationInfo.ScriptLineNumber)" ; break
        }
    }
    Process {
        # Functions
        function Load-Form {
            $Form.Controls.AddRange(@(
                $ButtonStart,
                $ButtonValidate,
                $TextBoxMatch,
                $TextBoxReplace,
                $ComboBoxTypes,
                $CheckBoxCopyContent,
                $OutputBox,
                $DGVResults,
                $GBLog,
                $GBResults,
                $GBMatch,
                $GBReplace,
                $GBOptions,
                $GBActions,
                $StatusBar
            ))
	        $Form.Add_Shown({$Form.Activate()})
            $Form.Add_Shown({Load-Connect})
	        $Form.ShowDialog() | Out-Null
            $TextBoxMatch.Focus() | Out-Null
        }

        function Load-Connect {
            Write-OutputBox -OutputBoxMessage "Connected to Site server '$($SiteServer)' with Site Code '$($SiteCode)'" -Type INFO
        }

        function Invoke-CleanControls {
            param(
                [parameter(Mandatory=$true)]
                [ValidateSet("All","Log")]
                $Option
            )
            if ($Option -eq "All") {
                $DGVResults.Rows.Clear()
                $OutputBox.ResetText()
            }
            if ($Option -eq "Log") {
                $OutputBox.ResetText()
            }
        }

        function Write-OutputBox {
	        param(
	            [parameter(Mandatory=$true)]
	            [string]$OutputBoxMessage,
                [parameter(Mandatory=$true)]
	            [ValidateSet("WARNING","ERROR","INFO")]
	            [string]$Type
	        )
            Begin {
                $DateTime = (Get-Date).ToLongTimeString()
            }
	        Process {
		        if ($OutputBox.Text.Length -eq 0) {
			        $OutputBox.Text = "$($DateTime) - $($Type): $($OutputBoxMessage)"
			        [System.Windows.Forms.Application]::DoEvents()
                    $OutputBox.SelectionStart = $OutputBox.Text.Length
                    $OutputBox.ScrollToCaret()
		        }
		        else {
			        $OutputBox.AppendText("`n$($DateTime) - $($Type): $($OutputBoxMessage)")
			        [System.Windows.Forms.Application]::DoEvents()
                    $OutputBox.SelectionStart = $OutputBox.Text.Length
                    $OutputBox.ScrollToCaret()
		        }  
	        }
        }

        function Update-StatusBar {
            param(
	            [parameter(Mandatory=$true)]
                [ValidateSet("Ready","Updating","Validating","Enumerating")]
	            [string]$Activity,
	            [parameter(Mandatory=$true)]
	            [string]$Text
            )
            $StatusBarPanelActivity.Text = $Activity
            $StatusBarPanelProcessing.Text = $Text
            [System.Windows.Forms.Application]::DoEvents()
        }

        function Update-ApplicationContentSource {
            param(
                [parameter(Mandatory=$true)]
                [ValidateSet("Validate","Update")]
                [string]$Action,
                [parameter(Mandatory=$false)]
                [switch]$CopyFiles
            )
            Begin {
                try {
                    Add-Type -Path (Join-Path -Path (Get-Item $env:SMS_ADMIN_UI_PATH).Parent.FullName -ChildPath "Microsoft.ConfigurationManagement.ApplicationManagement.dll") -ErrorAction Stop
                    Add-Type -Path (Join-Path -Path (Get-Item $env:SMS_ADMIN_UI_PATH).Parent.FullName -ChildPath "Microsoft.ConfigurationManagement.ApplicationManagement.Extender.dll") -ErrorAction Stop
                    Add-Type -Path (Join-Path -Path (Get-Item $env:SMS_ADMIN_UI_PATH).Parent.FullName -ChildPath "Microsoft.ConfigurationManagement.ApplicationManagement.MsiInstaller.dll") -ErrorAction Stop
                }
                catch [System.UnauthorizedAccessException] {
	                Write-OutputBox -OutputBoxMessage "Access denied when attempting to load ApplicationManagement dll's" -Type ERROR ; break
                }
                catch [System.Exception] {
	                Write-OutputBox -OutputBoxMessage "Unable to load required ApplicationManagement dll's. Make sure that you're running this tool on system where the ConfigMgr console is installed and that you're running the tool elevated" -Type ERROR ; break
                }
            }
            Process {
                if ($Action -eq "Validate") {
                    $AppCount = 0
                    Update-StatusBar -Activity Enumerating -Text " "
                    $Applications = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_ApplicationLatest" -ComputerName $SiteServer
                    $ApplicationCount = ($Applications | Measure-Object).Count
                    foreach ($Application in $Applications) {
                        $AppCount++
                        $ApplicationName = $Application.LocalizedDisplayName
                        Update-StatusBar -Activity Validating -Text "Validating application $($AppCount) / $($ApplicationCount)"
                        if ($Application.HasContent -eq $true) {
                            # Get Application object including Lazy properties
                            $Application.Get()
                            # Deserialize SDMPakageXML property from string
                            $ApplicationXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($Application.SDMPackageXML, $true)
                            foreach ($DeploymentType in $ApplicationXML.DeploymentTypes) {
                                $DeploymentTypeName = $DeploymentType.Title
                                $ExistingContentLocation = $DeploymentType.Installer.Contents[0].Location
                                if ($ExistingContentLocation -match [regex]::Escape($TextBoxMatch.Text)) {
                                    $UpdatedContentLocation = $DeploymentType.Installer.Contents[0].Location -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                                    $DGVResults.Rows.Add($true, $ApplicationName, $DeploymentTypeName, $ExistingContentLocation, $UpdatedContentLocation)
                                    Write-OutputBox -OutputBoxMessage "Validated deployment type '$($DeploymentTypeName)' for application '$($ApplicationName)'" -Type INFO
                                }
                                else {
                                    Write-OutputBox -OutputBoxMessage "Validation of deployment type '$($DeploymentTypeName)' for application '$($ApplicationName)' did not match the search pattern" -Type INFO
                                }
                            }
                            # Update Form application
                            [System.Windows.Forms.Application]::DoEvents()
                        }
                        else {
                            Write-OutputBox -OutputBoxMessage "Validation of application '$($ApplicationName)' detected that there was no associated content" -Type INFO
                        }
                    }
                    Update-StatusBar -Activity Ready -Text " "
                    Write-OutputBox -OutputBoxMessage "Completed content source validation" -Type INFO
                    if ($DGVResults.RowCount -ge 1) {
                        $ButtonStart.Enabled = $true
                    }
                }
                if ($Action -eq "Update") {
                    # Determine selected row count
                    $AppCount = 0
                    $AppRowCount = 0
                    for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                        if ($DGVResults.Rows[$RowIndex].Cells[0].Value -eq $true) {
                            $AppRowCount++
                        }
                    }
                    # Enumerate through selected rows in DataGridView
                    for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                        $CellAppName = $DGVResults.Rows[$RowIndex].Cells[1].Value
                        $CellAppSelected = $DGVResults.Rows[$RowIndex].Cells[0].Value
                        if ($CellAppSelected -eq $true) {
                            $AppCount++
                            $Application = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_ApplicationLatest" -ComputerName $SiteServer -Filter "LocalizedDisplayName like '$($CellAppName)'"
                            if ($Application -ne $null) {
                                $ApplicationName = $Application.LocalizedDisplayName
                                Update-StatusBar -Activity Updating -Text "Updating application $($AppCount) / $($AppRowCount)"
                                # Get Application object including Lazy properties
                                $Application.Get()
                                # Deserialize SDMPakageXML property from string
                                $ApplicationXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($Application.SDMPackageXML, $true)
                                foreach ($DeploymentType in $ApplicationXML.DeploymentTypes) {
                                    $DeploymentTypeName = $DeploymentType.Title
                                    $ExistingContentLocation = $DeploymentType.Installer.Contents[0].Location
                                    if ($ExistingContentLocation -match [regex]::Escape($TextBoxMatch.Text)) {
                                        $UpdatedContentLocation = $DeploymentType.Installer.Contents[0].Location -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                                        # Copy files
                                        if ($CopyFiles -eq $true) {
                                            if ($DeploymentType.Installer.Technology -eq "AppV") {
                                                $AmendUpdatedContentLocation = Split-Path -Path $UpdatedContentLocation -Parent
                                                if (-not(Test-Path -Path $AmendUpdatedContentLocation)) {
                                                    New-Item -Path $AmendUpdatedContentLocation -ItemType Directory | Out-Null
                                                }
                                                if (Test-Path -Path $ExistingContentLocation) {
                                                    $ExistingContentLocationItems = Get-ChildItem -Path $ExistingContentLocation
                                                    Write-OutputBox -OutputBoxMessage "Copying content source files from $($ExistingContentLocation) to $($AmendUpdatedContentLocation)" -Type INFO
                                                    foreach ($ExistingContentLocationItem in $ExistingContentLocationItems) {
                                                        Copy-Item -Path $ExistingContentLocationItem.FullName -Destination $AmendUpdatedContentLocation -Force -Recurse
                                                    }
                                                }
                                                else {
                                                    Write-OutputBox -OutputBoxMessage "Unable to access $($ExistingContentLocation)" -Type WARNING
                                                }
                                            }
                                            else {
                                                if (-not(Test-Path -Path $UpdatedContentLocation)) {
                                                    New-Item -Path $UpdatedContentLocation -ItemType Directory | Out-Null
                                                }
                                                if (Test-Path -Path $ExistingContentLocation) {
                                                    $ExistingContentLocationItems = Get-ChildItem -Path $ExistingContentLocation
                                                    Write-OutputBox -OutputBoxMessage "Copying content source files from $($ExistingContentLocation) to $($UpdatedContentLocation)" -Type INFO
                                                    foreach ($ExistingContentLocationItem in $ExistingContentLocationItems) {
                                                        Copy-Item -Path $ExistingContentLocationItem.FullName -Destination $UpdatedContentLocation -Force -Recurse
                                                    }
                                                }
                                                else {
                                                    Write-OutputBox -OutputBoxMessage "Unable to access $($ExistingContentLocation)" -Type WARNING
                                                }
                                            }
                                        }
                                        # Update content source
                                        $ContentImporter = [Microsoft.ConfigurationManagement.ApplicationManagement.ContentImporter]::CreateContentFromFolder($UpdatedContentLocation)
                                        $DeploymentType.Installer.Contents[0].ID = $ContentImporter.ID
                                        $DeploymentType.Installer.Contents[0] = $ContentImporter
                                        # Serialize $ApplicationXML object back to a string and store it in $UpdatedXML
                                        $UpdatedXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::SerializeToString($ApplicationXML, $true)
                                        $Application.SDMPackageXML = $UpdatedXML
                                        $Application.Put() | Out-Null
                                        Write-OutputBox -OutputBoxMessage "Updated deployment type '$($DeploymentTypeName)' for application '$($ApplicationName)'" -Type INFO
                                        [System.Windows.Forms.Application]::DoEvents()
                                    }
                                }
                            }
                        }
                    }
                    Update-StatusBar -Activity Ready -Text " "
                    Write-OutputBox -OutputBoxMessage "Completed updating content sources" -Type INFO
                    $ButtonStart.Enabled = $false
                }
            }
        }

        function Update-PackageContentSource {
            param(
                [parameter(Mandatory=$true)]
                [ValidateSet("Validate","Update")]
                [string]$Action,
                [parameter(Mandatory=$false)]
                [switch]$CopyFiles
            )
            Process {
                if ($Action -eq "Validate") {
                    $PackageCount = 0
                    Update-StatusBar -Activity Enumerating -Text " "
                    $Packages = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_Package" -ComputerName $SiteServer
                    $PackagesCount = ($Packages | Measure-Object).Count
                    foreach ($Package in $Packages) {
                        $PackageCount++
                        $PackageName = $Package.Name
                        $PackageID = $Package.PackageID
                        Update-StatusBar -Activity Validating -Text "Validating package $($PackageCount) / $($PackagesCount)"
                        if ($Package.PkgSourcePath -ne $null) {
                            if ($Package.PkgSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                                $ExistingPackageSourcePath = $Package.PkgSourcePath
                                $UpdatedPackageSourcePath = $Package.PkgSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                                $DGVResults.Rows.Add($true, $PackageName, $ExistingPackageSourcePath, $UpdatedPackageSourcePath, $PackageID)
                                $DGVResults.ClearSelection()
                                Write-OutputBox -OutputBoxMessage "Successfully validated package '$($PackageName)'" -Type INFO
                                [System.Windows.Forms.Application]::DoEvents()
                            }
                            else {
                                Write-OutputBox -OutputBoxMessage "No matching content source for package '$($PackageName)' was found" -Type INFO
                            }
                        }
                        else {
                            Write-OutputBox -OutputBoxMessage "Validation of package '$($PackageName)' detected that there was no associated content" -Type INFO
                        }
                    }
                    Update-StatusBar -Activity Ready -Text " "
                    Write-OutputBox -OutputBoxMessage "Completed content source validation" -Type INFO
                    $ButtonStart.Enabled = $true
                }
                if ($Action -eq "Update") {
                    # Determine selected row count
                    $PackageCount = 0
                    $PackageRowCount = 0
                    for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                        if ($DGVResults.Rows[$RowIndex].Cells[0].Value -eq $true) {
                            $PackageRowCount++
                        }
                    }
                    # Enumerate through selected rows in DataGridView
                    for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                        $CellPackageName = $DGVResults.Rows[$RowIndex].Cells[1].Value
                        $CellPackageSelected = $DGVResults.Rows[$RowIndex].Cells[0].Value
                        $CellPackageID = $DGVResults.Rows[$RowIndex].Cells[4].Value
                        if ($CellPackageSelected -eq $true) {
                            $PackageCount++
                            $Package = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_Package" -ComputerName $SiteServer -Filter "PackageID like '$($CellPackageID)'"
                            if ($Package -ne $null) {
                                $PackageName = $Package.Name
                                Update-StatusBar -Activity Validating -Text "Updating package $($PackageCount) / $($PackageRowCount)"
                                [System.Windows.Forms.Application]::DoEvents()
                                if ($Package.PkgSourcePath -ne $null) {
                                    if ($Package.PkgSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                                        $ExistingPackageSourcePath = $Package.PkgSourcePath
                                        $UpdatedPackageSourcePath = $Package.PkgSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                                        # Copy files
                                        if ($CopyFiles -eq $true) {
                                            if (-not(Test-Path -Path $UpdatedPackageSourcePath)) {
                                                New-Item -Path $UpdatedPackageSourcePath -ItemType Directory | Out-Null
                                            }
                                            if ((Get-ChildItem -Path $UpdatedPackageSourcePath | Measure-Object).Count -eq 0) {
                                                if (Test-Path -Path $ExistingPackageSourcePath) {
                                                    $ExistingPackageSourcePathItems = Get-ChildItem -Path $ExistingPackageSourcePath
                                                    Write-OutputBox -OutputBoxMessage "Copying content source files from $($ExistingPackageSourcePath) to $($UpdatedPackageSourcePath)" -Type INFO
                                                    foreach ($ExistingPackageSourcePathItem in $ExistingPackageSourcePathItems) {
                                                        Copy-Item -Path $ExistingPackageSourcePathItem.FullName -Destination $UpdatedPackageSourcePath -Force -Recurse
                                                    }
                                                }
                                                else {
                                                    Write-OutputBox -OutputBoxMessage "Unable to access $($ExistingPackageSourcePath)" -Type WARNING
                                                }
                                            }
                                        }
                                        # Update content source
                                        $Package.PkgSourcePath = $UpdatedPackageSourcePath
                                        $Package.Put() | Out-Null
                                        $ValidatePackage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_Package" -ComputerName $SiteServer -Filter "PackageID like '$($CellPackageID)'"
                                        if ($ValidatePackage.PkgSourcePath -eq $UpdatedPackageSourcePath) {
                                            Write-OutputBox -OutputBoxMessage "Updated package '$($PackageName)'" -Type INFO
                                        }
                                        else {
                                            Write-OutputBox -OutputBoxMessage "An error occurred while updating package '$($PackageName)'" -Type ERROR
                                        }
                                        [System.Windows.Forms.Application]::DoEvents()
                                    }
                                    else {
                                        Write-OutputBox -OutputBoxMessage "No matching content source for package '$($PackageName)' was found" -Type INFO
                                    }
                                }
                                else {
                                    Write-OutputBox -OutputBoxMessage "Validation of package '$($PackageName)' detected that there was no associated content" -Type INFO
                                }
                            }
                        }
                    }
                    Update-StatusBar -Activity Ready -Text " "
                    Write-OutputBox -OutputBoxMessage "Completed updating content sources" -Type INFO
                    $ButtonStart.Enabled = $false
                }
            }
        }

        function Update-DeploymentPackageContentSource {
            param(
                [parameter(Mandatory=$true)]
                [ValidateSet("Validate","Update")]
                [string]$Action,
                [parameter(Mandatory=$false)]
                [switch]$CopyFiles
            )
            Process {
                if ($Action -eq "Validate") {
                    $DeploymentPackageCount = 0
                    Update-StatusBar -Activity Enumerating -Text " "
                    $DeploymentPackages = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_SoftwareUpdatesPackage" -ComputerName $SiteServer
                    $DeploymentPackagesCount = ($DeploymentPackages | Measure-Object).Count
                    foreach ($DeploymentPackage in $DeploymentPackages) {
                        $DeploymentPackageCount++
                        $DeploymentPackageName = $DeploymentPackage.Name
                        $DeploymentPackageID = $DeploymentPackage.PackageID
                        Update-StatusBar -Activity Validating -Text "Validating deployment package $($DeploymentPackageCount) / $($DeploymentPackagesCount)"
                        if ($DeploymentPackage.PkgSourcePath -ne $null) {
                            if ($DeploymentPackage.PkgSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                                $ExistingDeploymentPackageSourcePath = $DeploymentPackage.PkgSourcePath
                                $UpdatedDeploymentPackageSourcePath = $DeploymentPackage.PkgSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                                $DGVResults.Rows.Add($true, $DeploymentPackageName, $ExistingDeploymentPackageSourcePath, $UpdatedDeploymentPackageSourcePath, $DeploymentPackageID)
                                Write-OutputBox -OutputBoxMessage "Successfully validated deployment package '$($DeploymentPackageName)'" -Type INFO
                                [System.Windows.Forms.Application]::DoEvents()
                            }
                            else {
                                Write-OutputBox -OutputBoxMessage "No matching content source for deployment package '$($DeploymentPackageName)' was found" -Type INFO
                            }
                        }
                        else {
                            Write-OutputBox -OutputBoxMessage "Validation of deployment package '$($DeploymentPackageName)' detected that there was no associated content" -Type INFO
                        }
                    }
                    Update-StatusBar -Activity Ready -Text " "
                    Write-OutputBox -OutputBoxMessage "Completed content source validation" -Type INFO
                    $ButtonStart.Enabled = $true
                }
                if ($Action -eq "Update") {
                    # Determine selected row count
                    $DeploymentPackageCount = 0
                    $DeploymentPackageRowCount = 0
                    for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                        if ($DGVResults.Rows[$RowIndex].Cells[0].Value -eq $true) {
                            $DeploymentPackageRowCount++
                        }
                    }
                    # Enumerate through selected rows in DataGridView
                    for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                        $CellDeploymentPackageName = $DGVResults.Rows[$RowIndex].Cells[1].Value
                        $CellDeploymentPackageSelected = $DGVResults.Rows[$RowIndex].Cells[0].Value
                        $CellDeploymentPackageID = $DGVResults.Rows[$RowIndex].Cells[4].Value
                        if ($CellDeploymentPackageSelected -eq $true) {
                            $DeploymentPackageCount++
                            $DeploymentPackage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_SoftwareUpdatesPackage" -ComputerName $SiteServer -Filter "PackageID like '$($CellDeploymentPackageID)'"
                            if ($DeploymentPackage -ne $null) {
                                $DeploymentPackageName = $DeploymentPackage.Name
                                Update-StatusBar -Activity Validating -Text "Updating package $($DeploymentPackageCount) / $($DeploymentPackageRowCount)"
                                [System.Windows.Forms.Application]::DoEvents()
                                if ($DeploymentPackage.PkgSourcePath -ne $null) {
                                    if ($DeploymentPackage.PkgSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                                        $ExistingDeploymentPackageSourcePath = $DeploymentPackage.PkgSourcePath
                                        $UpdatedDeploymentPackageSourcePath = $DeploymentPackage.PkgSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                                        # Copy files
                                        if ($CopyFiles -eq $true) {
                                            if (-not(Test-Path -Path $UpdatedDeploymentPackageSourcePath)) {
                                                New-Item -Path $UpdatedDeploymentPackageSourcePath -ItemType Directory | Out-Null
                                            }
                                            if ((Get-ChildItem -Path $UpdatedDeploymentPackageSourcePath | Measure-Object).Count -eq 0) {
                                                if (Test-Path -Path $ExistingDeploymentPackageSourcePath) {
                                                    $ExistingDeploymentPackageSourcePathItems = Get-ChildItem -Path $ExistingDeploymentPackageSourcePath
                                                    Write-OutputBox -OutputBoxMessage "Copying content source files from $($ExistingDeploymentPackageSourcePath) to $($UpdatedDeploymentPackageSourcePath)" -Type INFO
                                                    foreach ($ExistingDeploymentPackageSourcePathItem in $ExistingDeploymentPackageSourcePathItems) {
                                                        Copy-Item -Path $ExistingDeploymentPackageSourcePathItem.FullName -Destination $UpdatedDeploymentPackageSourcePath -Force -Recurse
                                                    }
                                                }
                                                else {
                                                    Write-OutputBox -OutputBoxMessage "Unable to access $($ExistingDeploymentPackageSourcePath)" -Type WARNING
                                                }
                                            }
                                        }
                                        # Update content source
                                        $DeploymentPackage.PkgSourcePath = $UpdatedDeploymentPackageSourcePath
                                        $DeploymentPackage.Put() | Out-Null
                                        $ValidateDeploymentPackage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_SoftwareUpdatesPackage" -ComputerName $SiteServer -Filter "PackageID like '$($CellDeploymentPackageID)'"
                                        if ($ValidateDeploymentPackage.PkgSourcePath -eq $UpdatedDeploymentPackageSourcePath) {
                                            Write-OutputBox -OutputBoxMessage "Updated deployment package '$($DeploymentPackageName)'" -Type INFO
                                        }
                                        else {
                                            Write-OutputBox -OutputBoxMessage "An error occurred while updating deployment package '$($DeploymentPackageName)'" -Type ERROR
                                        }
                                        [System.Windows.Forms.Application]::DoEvents()
                                    }
                                    else {
                                        Write-OutputBox -OutputBoxMessage "No matching content source for package '$($DeploymentPackageName)' was found" -Type INFO
                                    }
                                }
                                else {
                                    Write-OutputBox -OutputBoxMessage "Validation of package '$($DeploymentPackageName)' detected that there was no associated content" -Type INFO
                                }
                            }
                        }
                    }
                    Update-StatusBar -Activity Ready -Text " "
                    Write-OutputBox -OutputBoxMessage "Completed updating content sources" -Type INFO
                    $ButtonStart.Enabled = $false
                }
            }
        }

        function Update-DriverContentSource {
            param(
                [parameter(Mandatory=$true)]
                [ValidateSet("Validate","Update")]
                [string]$Action,
                [parameter(Mandatory=$false)]
                [switch]$CopyFiles
            )
            Process {
                if ($Action -eq "Validate") {
                    $DriverCount = 0
                    Update-StatusBar -Activity Enumerating -Text " "
                    $Drivers = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_Driver" -ComputerName $SiteServer
                    $DriversCount = ($Drivers | Measure-Object).Count
                    foreach ($Driver in $Drivers) {
                        $DriverCount++
                        $DriverName = $Driver.LocalizedDisplayName
                        $DriverCIID = $Driver.CI_ID
                        Update-StatusBar -Activity Validating -Text "Validating driver $($DriverCount) / $($DriversCount)"
                        if ($Driver.ContentSourcePath -ne $null) {
                            if ($Driver.ContentSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                                $ExistingDriverSourcePath = $Driver.ContentSourcePath
                                $UpdatedDriverSourcePath = $Driver.ContentSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                                $DGVResults.Rows.Add($true, $DriverName, $ExistingDriverSourcePath, $UpdatedDriverSourcePath, $DriverCIID)
                                Write-OutputBox -OutputBoxMessage "Successfully validated driver '$($DriverName)'" -Type INFO
                                [System.Windows.Forms.Application]::DoEvents()
                            }
                            else {
                                Write-OutputBox -OutputBoxMessage "No matching content source for driver '$($DriverName)' was found" -Type INFO
                            }
                        }
                        else {
                            Write-OutputBox -OutputBoxMessage "Validation of driver '$($DriverName)' detected that there was no associated content" -Type INFO
                        }
                    }
                    Update-StatusBar -Activity Ready -Text " "
                    Write-OutputBox -OutputBoxMessage "Completed content source validation" -Type INFO
                    $ButtonStart.Enabled = $true
                }
                if ($Action -eq "Update") {
                    # Determine selected row count
                    $DriverCount = 0
                    $DriverRowCount = 0
                    for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                        if ($DGVResults.Rows[$RowIndex].Cells[0].Value -eq $true) {
                            $DriverRowCount++
                        }
                    }
                    # Enumerate through selected rows in DataGridView
                    for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                        $CellDriverName = $DGVResults.Rows[$RowIndex].Cells[1].Value
                        $CellDriverSelected = $DGVResults.Rows[$RowIndex].Cells[0].Value
                        $CellDriverCIID = $DGVResults.Rows[$RowIndex].Cells[4].Value
                        if ($CellDriverSelected -eq $true) {
                            $DriverCount++
                            $Driver = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_Driver" -ComputerName $SiteServer -Filter "CI_ID like '$($CellDriverCIID)'"
                            if ($Driver -ne $null) {
                                $DriverName = $Driver.LocalizedDisplayName
                                Update-StatusBar -Activity Validating -Text "Updating driver $($DriverCount) / $($DriverRowCount)"
                                [System.Windows.Forms.Application]::DoEvents()
                                if ($Driver.ContentSourcePath -ne $null) {
                                    if ($Driver.ContentSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                                        $ExistingDriverSourcePath = $Driver.ContentSourcePath
                                        $UpdatedDriverSourcePath = $Driver.ContentSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                                        # Copy files
                                        if ($CopyFiles -eq $true) {
                                            if (-not(Test-Path -Path $UpdatedDriverSourcePath)) {
                                                New-Item -Path $UpdatedDriverSourcePath -ItemType Directory | Out-Null
                                            }
                                            if ((Get-ChildItem -Path $UpdatedDriverSourcePath | Measure-Object).Count -eq 0) {
                                                if (Test-Path -Path $ExistingDriverSourcePath) {
                                                    $ExistingDriverSourcePathItems = Get-ChildItem -Path $ExistingDriverSourcePath
                                                    Write-OutputBox -OutputBoxMessage "Copying content source files from $($ExistingDriverSourcePath) to $($UpdatedDriverSourcePath)" -Type INFO
                                                    foreach ($ExistingDriverSourcePathItem in $ExistingDriverSourcePathItems) {
                                                        Copy-Item -Path $ExistingDriverSourcePathItem.FullName -Destination $UpdatedDriverSourcePath -Force -Recurse
                                                    }
                                                }
                                                else {
                                                    Write-OutputBox -OutputBoxMessage "Unable to access $($ExistingDriverSourcePath)" -Type WARNING
                                                }
                                            }
                                        }
                                        # Update content source
                                        $Driver.ContentSourcePath = $UpdatedDriverSourcePath
                                        $Driver.Put() | Out-Null
                                        $ValidateDriver = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_Driver" -ComputerName $SiteServer -Filter "CI_ID like '$($CellDriverCIID)'"
                                        if ($ValidateDriver.ContentSourcePath -eq $UpdatedDriverSourcePath) {
                                            Write-OutputBox -OutputBoxMessage "Updated driver '$($DriverName)'" -Type INFO
                                        }
                                        else {
                                            Write-OutputBox -OutputBoxMessage "An error occurred while updating driver '$($DriverName)'" -Type ERROR
                                        }
                                        [System.Windows.Forms.Application]::DoEvents()
                                    }
                                    else {
                                        Write-OutputBox -OutputBoxMessage "No matching content source for driver '$($DriverName)' was found" -Type INFO
                                    }
                                }
                                else {
                                    Write-OutputBox -OutputBoxMessage "Validation of driver '$($DriverName)' detected that there was no associated content" -Type INFO
                                }
                            }
                        }
                    }
                    Update-StatusBar -Activity Ready -Text " "
                    Write-OutputBox -OutputBoxMessage "Completed updating content sources" -Type INFO
                    $ButtonStart.Enabled = $false
                }
            }
        }

        function Update-DriverPackageContentSource {
            param(
                [parameter(Mandatory=$true)]
                [ValidateSet("Validate","Update")]
                [string]$Action,
                [parameter(Mandatory=$false)]
                [switch]$CopyFiles
            )
            Process {
                if ($Action -eq "Validate") {
                    $DriverPackageCount = 0
                    Update-StatusBar -Activity Enumerating -Text " "
                    $DriverPackages = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_DriverPackage" -ComputerName $SiteServer
                    $DriverPackagesCount = ($DriverPackages | Measure-Object).Count
                    foreach ($DriverPackage in $DriverPackages) {
                        $DriverPackageCount++
                        $DriverPackageName = $DriverPackage.Name
                        $DriverPackageID = $DriverPackage.PackageID
                        Update-StatusBar -Activity Validating -Text "Validating driver package $($DriverPackageCount) / $($DriverPackagesCount)"
                        if ($DriverPackage.PkgSourcePath -ne $null) {
                            if ($DriverPackage.PkgSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                                $ExistingDriverPackageSourcePath = $DriverPackage.PkgSourcePath
                                $UpdatedDriverPackageSourcePath = $DriverPackage.PkgSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                                $DGVResults.Rows.Add($true, $DriverPackageName, $ExistingDriverPackageSourcePath, $UpdatedDriverPackageSourcePath, $DriverPackageID)
                                Write-OutputBox -OutputBoxMessage "Successfully validated driver package '$($DriverPackageName)'" -Type INFO
                                [System.Windows.Forms.Application]::DoEvents()
                            }
                            else {
                                Write-OutputBox -OutputBoxMessage "No matching content source for driver package '$($DriverPackageName)' was found" -Type INFO
                            }
                        }
                        else {
                            Write-OutputBox -OutputBoxMessage "Validation of driver package '$($DriverPackageName)' detected that there was no associated content" -Type INFO
                        }
                    }
                    Update-StatusBar -Activity Ready -Text " "
                    Write-OutputBox -OutputBoxMessage "Completed content source validation" -Type INFO
                    $ButtonStart.Enabled = $true
                }
                if ($Action -eq "Update") {
                    # Determine selected row count
                    $DriverPackageCount = 0
                    $DriverPackageRowCount = 0
                    for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                        if ($DGVResults.Rows[$RowIndex].Cells[0].Value -eq $true) {
                            $DriverPackageRowCount++
                        }
                    }
                    # Enumerate through selected rows in DataGridView
                    for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                        $CellDriverPackageName = $DGVResults.Rows[$RowIndex].Cells[1].Value
                        $CellDriverPackageSelected = $DGVResults.Rows[$RowIndex].Cells[0].Value
                        $CellDriverPackageID = $DGVResults.Rows[$RowIndex].Cells[4].Value
                        if ($CellDriverPackageSelected -eq $true) {
                            $DriverPackageCount++
                            $DriverPackage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_DriverPackage" -ComputerName $SiteServer -Filter "PackageID like '$($CellDriverPackageID)'"
                            if ($DriverPackage -ne $null) {
                                $DriverPackageName = $DriverPackage.Name
                                Update-StatusBar -Activity Validating -Text "Updating driver package $($DriverPackageCount) / $($DriverPackageRowCount)"
                                [System.Windows.Forms.Application]::DoEvents()
                                if ($DriverPackage.PkgSourcePath -ne $null) {
                                    if ($DriverPackage.PkgSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                                        $ExistingDriverPackageSourcePath = $DriverPackage.PkgSourcePath
                                        $UpdatedDriverPackageSourcePath = $DriverPackage.PkgSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                                        # Copy files
                                        if ($CopyFiles -eq $true) {
                                            if (-not(Test-Path -Path $UpdatedDriverPackageSourcePath)) {
                                                New-Item -Path $UpdatedDriverPackageSourcePath -ItemType Directory | Out-Null
                                            }
                                            if ((Get-ChildItem -Path $UpdatedDriverPackageSourcePath | Measure-Object).Count -eq 0) {
                                                if (Test-Path -Path $ExistingDriverPackageSourcePath) {
                                                    $ExistingDriverPackageSourcePathItems = Get-ChildItem -Path $ExistingDriverPackageSourcePath
                                                    Write-OutputBox -OutputBoxMessage "Copying content source files from $($ExistingDriverPackageSourcePath) to $($UpdatedDriverPackageSourcePath)" -Type INFO
                                                    foreach ($ExistingDriverPackageSourcePathItem in $ExistingDriverPackageSourcePathItems) {
                                                        Copy-Item -Path $ExistingDriverPackageSourcePathItem.FullName -Destination $UpdatedDriverPackageSourcePath -Force -Recurse
                                                    }
                                                }
                                                else {
                                                    Write-OutputBox -OutputBoxMessage "Unable to access $($ExistingDriverPackageSourcePath)" -Type WARNING
                                                }
                                            }
                                        }
                                        # Update content source
                                        $DriverPackage.PkgSourcePath = $UpdatedDriverPackageSourcePath
                                        $DriverPackage.Put() | Out-Null
                                        $ValidateDriverPackage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_DriverPackage" -ComputerName $SiteServer -Filter "PackageID like '$($CellDriverPackageID)'"
                                        if ($ValidateDriverPackage.PkgSourcePath -eq $UpdatedDriverPackageSourcePath) {
                                            Write-OutputBox -OutputBoxMessage "Updated driver package '$($DriverPackageName)'" -Type INFO
                                        }
                                        else {
                                            Write-OutputBox -OutputBoxMessage "An error occurred while updating driver package '$($DriverPackageName)'" -Type ERROR
                                        }
                                        [System.Windows.Forms.Application]::DoEvents()
                                    }
                                    else {
                                        Write-OutputBox -OutputBoxMessage "No matching content source for driver package '$($DriverPackageName)' was found" -Type INFO
                                    }
                                }
                                else {
                                    Write-OutputBox -OutputBoxMessage "Validation of driver package '$($DriverPackageName)' detected that there was no associated content" -Type INFO
                                }
                            }
                        }
                    }
                    Update-StatusBar -Activity Ready -Text " "
                    Write-OutputBox -OutputBoxMessage "Completed updating content sources" -Type INFO
                    $ButtonStart.Enabled = $false
                }
            }
        }

        function Update-OperatingSystemImageContentSource {
            param(
                [parameter(Mandatory=$true)]
                [ValidateSet("Validate","Update")]
                [string]$Action,
                [parameter(Mandatory=$false)]
                [switch]$CopyFiles
            )
            Process {
                if ($Action -eq "Validate") {
                    $OperatingSystemImageCount = 0
                    Update-StatusBar -Activity Enumerating -Text " "
                    $OperatingSystemImages = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_ImagePackage" -ComputerName $SiteServer
                    $OperatingSystemImagesCount = ($OperatingSystemImages | Measure-Object).Count
                    foreach ($OperatingSystemImage in $OperatingSystemImages) {
                        $OperatingSystemImageCount++
                        $OperatingSystemImageName = $OperatingSystemImage.Name
                        $OperatingSystemImageID = $OperatingSystemImage.PackageID
                        Update-StatusBar -Activity Validating -Text "Validating operating system image $($OperatingSystemImageCount) / $($OperatingSystemImagesCount)"
                        if ($OperatingSystemImage.PkgSourcePath -ne $null) {
                            if ($OperatingSystemImage.PkgSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                                $ExistingOperatingSystemImageSourcePath = $OperatingSystemImage.PkgSourcePath
                                $UpdatedOperatingSystemImageSourcePath = $OperatingSystemImage.PkgSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                                $DGVResults.Rows.Add($true, $OperatingSystemImageName, $ExistingOperatingSystemImageSourcePath, $UpdatedOperatingSystemImageSourcePath, $OperatingSystemImageID)
                                Write-OutputBox -OutputBoxMessage "Successfully validated operating system image '$($OperatingSystemImageName)'" -Type INFO
                                [System.Windows.Forms.Application]::DoEvents()
                            }
                            else {
                                Write-OutputBox -OutputBoxMessage "No matching content source for operating system image '$($OperatingSystemImageName)' was found" -Type INFO
                            }
                        }
                        else {
                            Write-OutputBox -OutputBoxMessage "Validation of operating system image '$($OperatingSystemImageName)' detected that there was no associated content" -Type INFO
                        }
                    }
                    Update-StatusBar -Activity Ready -Text " "
                    Write-OutputBox -OutputBoxMessage "Completed content source validation" -Type INFO
                    $ButtonStart.Enabled = $true
                }
                if ($Action -eq "Update") {
                    # Determine selected row count
                    $OperatingSystemImageCount = 0
                    $OperatingSystemImageRowCount = 0
                    for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                        if ($DGVResults.Rows[$RowIndex].Cells[0].Value -eq $true) {
                            $OperatingSystemImageRowCount++
                        }
                    }
                    # Enumerate through selected rows in DataGridView
                    for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                        $CellOperatingSystemImageName = $DGVResults.Rows[$RowIndex].Cells[1].Value
                        $CellOperatingSystemImageSelected = $DGVResults.Rows[$RowIndex].Cells[0].Value
                        $CellOperatingSystemImageID = $DGVResults.Rows[$RowIndex].Cells[4].Value
                        if ($CellOperatingSystemImageSelected -eq $true) {
                            $OperatingSystemImageCount++
                            $OperatingSystemImage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_ImagePackage" -ComputerName $SiteServer -Filter "PackageID like '$($CellOperatingSystemImageID)'"
                            if ($OperatingSystemImage -ne $null) {
                                $OperatingSystemImageName = $OperatingSystemImage.Name
                                Update-StatusBar -Activity Validating -Text "Updating operating system image $($OperatingSystemImageCount) / $($OperatingSystemImageRowCount)"
                                [System.Windows.Forms.Application]::DoEvents()
                                if ($OperatingSystemImage.PkgSourcePath -ne $null) {
                                    if ($OperatingSystemImage.PkgSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                                        $ExistingOperatingSystemImageSourcePath = $OperatingSystemImage.PkgSourcePath
                                        $UpdatedOperatingSystemImageSourcePath = $OperatingSystemImage.PkgSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                                        # Amend updated content source path for successful file copy operations
                                        $AmendUpdatedOperatingSystemImageSourcePath = Split-Path -Path $UpdatedOperatingSystemImageSourcePath -Parent
                                        # Copy files
                                        if ($CopyFiles -eq $true) {
                                            if (-not(Test-Path -Path $AmendUpdatedOperatingSystemImageSourcePath)) {
                                                New-Item -Path $AmendUpdatedOperatingSystemImageSourcePath -ItemType Directory | Out-Null
                                            }
                                            if (Test-Path -Path $ExistingOperatingSystemImageSourcePath) {
                                                $ExistingOperatingSystemImageSourcePathItems = Get-ChildItem -Path $ExistingOperatingSystemImageSourcePath
                                                Write-OutputBox -OutputBoxMessage "Copying wim file $($ExistingOperatingSystemImageSourcePath) to $($AmendUpdatedOperatingSystemImageSourcePath)" -Type INFO
                                                foreach ($ExistingOperatingSystemImageSourcePathItem in $ExistingOperatingSystemImageSourcePathItems) {
                                                    Copy-Item -Path $ExistingOperatingSystemImageSourcePathItem.FullName -Destination $AmendUpdatedOperatingSystemImageSourcePath -Force -Recurse
                                                }
                                            }
                                            else {
                                                Write-OutputBox -OutputBoxMessage "Unable to access $($ExistingOperatingSystemImageSourcePath)" -Type WARNING
                                            }
                                        }
                                        # Update content source
                                        if (Test-Path -Path $UpdatedOperatingSystemImageSourcePath) {
                                            $OperatingSystemImage.Get()
                                            $OperatingSystemImage.PkgSourcePath = $UpdatedOperatingSystemImageSourcePath
                                            $OperatingSystemImage.Put() | Out-Null
                                            $ValidateOperatingSystemImage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_ImagePackage" -ComputerName $SiteServer -Filter "PackageID like '$($CellOperatingSystemImageID)'"
                                            if ($ValidateOperatingSystemImage.PkgSourcePath -eq $UpdatedOperatingSystemImageSourcePath) {
                                                Write-OutputBox -OutputBoxMessage "Updated operating system image '$($OperatingSystemImageName)'" -Type INFO
                                            }
                                            else {
                                                Write-OutputBox -OutputBoxMessage "An error occurred while updating operating system image '$($OperatingSystemImageName)'" -Type ERROR
                                            }
                                            [System.Windows.Forms.Application]::DoEvents()
                                        }
                                        else {
                                            Write-OutputBox -OutputBoxMessage "Unable to locate $($OperatingSystemImageName) wim file on updated content source path. Manually copy the content files or check the Copy content files to new location check box " -Type WARNING
                                        }
                                    }
                                    else {
                                        Write-OutputBox -OutputBoxMessage "No matching content source for operating system image '$($OperatingSystemImageName)' was found" -Type INFO
                                    }
                                }
                                else {
                                    Write-OutputBox -OutputBoxMessage "Validation of operating system image '$($OperatingSystemImageName)' detected that there was no associated content" -Type INFO
                                }
                            }
                        }
                    }
                    Update-StatusBar -Activity Ready -Text " "
                    Write-OutputBox -OutputBoxMessage "Completed updating content sources" -Type INFO
                    $ButtonStart.Enabled = $false
                }
            }
        }
    
        function Update-OperatingSystemPackageContentSource {
            param(
                [parameter(Mandatory=$true)]
                [ValidateSet("Validate","Update")]
                [string]$Action,
                [parameter(Mandatory=$false)]
                [switch]$CopyFiles
            )
            Process {
                if ($Action -eq "Validate") {
                    $OperatingSystemPackageCount = 0
                    Update-StatusBar -Activity Enumerating -Text " "
                    $OperatingSystemPackages = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_OperatingSystemInstallPackage" -ComputerName $SiteServer
                    $OperatingSystemPackagesCount = ($OperatingSystemPackages | Measure-Object).Count
                    foreach ($OperatingSystemPackage in $OperatingSystemPackages) {
                        $OperatingSystemPackageCount++
                        $OperatingSystemPackageName = $OperatingSystemPackage.Name
                        $OperatingSystemPackageID = $OperatingSystemPackage.PackageID
                        Update-StatusBar -Activity Validating -Text "Validating operating system package $($OperatingSystemPackageCount) / $($OperatingSystemPackagesCount)"
                        if ($OperatingSystemPackage.PkgSourcePath -ne $null) {
                            if ($OperatingSystemPackage.PkgSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                                $ExistingOperatingSystemPackageSourcePath = $OperatingSystemPackage.PkgSourcePath
                                $UpdatedOperatingSystemPackageSourcePath = $OperatingSystemPackage.PkgSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                                $DGVResults.Rows.Add($true, $OperatingSystemPackageName, $ExistingOperatingSystemPackageSourcePath, $UpdatedOperatingSystemPackageSourcePath, $OperatingSystemPackageID)
                                Write-OutputBox -OutputBoxMessage "Successfully validated operating system package '$($OperatingSystemPackageName)'" -Type INFO
                                [System.Windows.Forms.Application]::DoEvents()
                            }
                            else {
                                Write-OutputBox -OutputBoxMessage "No matching content source for operating system package '$($OperatingSystemPackageName)' was found" -Type INFO
                            }
                        }
                        else {
                            Write-OutputBox -OutputBoxMessage "Validation of operating system package '$($OperatingSystemPackageName)' detected that there was no associated content" -Type INFO
                        }
                    }
                    Update-StatusBar -Activity Ready -Text " "
                    Write-OutputBox -OutputBoxMessage "Completed content source validation" -Type INFO
                    $ButtonStart.Enabled = $true
                }
                if ($Action -eq "Update") {
                    # Determine selected row count
                    $OperatingSystemPackageCount = 0
                    $OperatingSystemPackageRowCount = 0
                    for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                        if ($DGVResults.Rows[$RowIndex].Cells[0].Value -eq $true) {
                            $OperatingSystemPackageRowCount++
                        }
                    }
                    # Enumerate through selected rows in DataGridView
                    for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                        $CellOperatingSystemPackageName = $DGVResults.Rows[$RowIndex].Cells[1].Value
                        $CellOperatingSystemPackageSelected = $DGVResults.Rows[$RowIndex].Cells[0].Value
                        $CellOperatingSystemPackageID = $DGVResults.Rows[$RowIndex].Cells[4].Value
                        if ($CellOperatingSystemPackageSelected -eq $true) {
                            $OperatingSystemPackageCount++
                            $OperatingSystemPackage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_OperatingSystemInstallPackage" -ComputerName $SiteServer -Filter "PackageID like '$($CellOperatingSystemPackageID)'"
                            if ($OperatingSystemPackage -ne $null) {
                                $OperatingSystemPackageName = $OperatingSystemPackage.Name
                                Update-StatusBar -Activity Validating -Text "Updating operating system package $($OperatingSystemPackageCount) / $($OperatingSystemPackageRowCount)"
                                [System.Windows.Forms.Application]::DoEvents()
                                if ($OperatingSystemPackage.PkgSourcePath -ne $null) {
                                    if ($OperatingSystemPackage.PkgSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                                        $ExistingOperatingSystemPackageSourcePath = $OperatingSystemPackage.PkgSourcePath
                                        $UpdatedOperatingSystemPackageSourcePath = $OperatingSystemPackage.PkgSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                                        # Copy files
                                        if ($CopyFiles -eq $true) {
                                            if (-not(Test-Path -Path $UpdatedOperatingSystemPackageSourcePath)) {
                                                New-Item -Path $UpdatedOperatingSystemPackageSourcePath -ItemType Directory | Out-Null
                                            }
                                            if ((Get-ChildItem -Path $UpdatedOperatingSystemPackageSourcePath | Measure-Object).Count -eq 0) {
                                                if (Test-Path -Path $ExistingOperatingSystemPackageSourcePath) {
                                                    $ExistingOperatingSystemPackageSourcePathItems = Get-ChildItem -Path $ExistingOperatingSystemPackageSourcePath
                                                    Write-OutputBox -OutputBoxMessage "Copying content source files from $($ExistingOperatingSystemPackageSourcePath) to $($UpdatedOperatingSystemPackageSourcePath)" -Type INFO
                                                    foreach ($ExistingOperatingSystemPackageSourcePathItem in $ExistingOperatingSystemPackageSourcePathItems) {
                                                        Copy-Item -Path $ExistingOperatingSystemPackageSourcePathItem.FullName -Destination $UpdatedOperatingSystemPackageSourcePath -Force -Recurse
                                                    }
                                                }
                                                else {
                                                    Write-OutputBox -OutputBoxMessage "Unable to access $($ExistingOperatingSystemPackageSourcePath)" -Type WARNING
                                                }
                                            }
                                        }
                                        # Update content source
                                        $OperatingSystemPackage.Get()
                                        $OperatingSystemPackage.PkgSourcePath = $UpdatedOperatingSystemPackageSourcePath
                                        $OperatingSystemPackage.Put() | Out-Null
                                        $ValidateOperatingSystemPackage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_OperatingSystemInstallPackage" -ComputerName $SiteServer -Filter "PackageID like '$($CellOperatingSystemPackageID)'"
                                        if ($ValidateOperatingSystemPackage.PkgSourcePath -eq $UpdatedOperatingSystemPackageSourcePath) {
                                            Write-OutputBox -OutputBoxMessage "Updated operating system package '$($OperatingSystemPackageName)'" -Type INFO
                                        }
                                        else {
                                            Write-OutputBox -OutputBoxMessage "An error occurred while updating operating system package '$($OperatingSystemPackageName)'" -Type ERROR
                                        }
                                        [System.Windows.Forms.Application]::DoEvents()
                                    }
                                    else {
                                        Write-OutputBox -OutputBoxMessage "No matching content source for operating system package '$($OperatingSystemPackageName)' was found" -Type INFO
                                    }
                                }
                                else {
                                    Write-OutputBox -OutputBoxMessage "Validation of operating system package '$($OperatingSystemPackageName)' detected that there was no associated content" -Type INFO
                                }
                            }
                        }
                    }
                    Update-StatusBar -Activity Ready -Text " "
                    Write-OutputBox -OutputBoxMessage "Completed updating content sources" -Type INFO
                    $ButtonStart.Enabled = $false
                }
            }
        }

        function Update-BootImageContentSource {
            param(
                [parameter(Mandatory=$true)]
                [ValidateSet("Validate","Update")]
                [string]$Action,
                [parameter(Mandatory=$false)]
                [switch]$CopyFiles
            )
            Process {
                if ($Action -eq "Validate") {
                    $BootImageCount = 0
                    Update-StatusBar -Activity Enumerating -Text " "
                    $BootImages = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_BootImagePackage" -ComputerName $SiteServer
                    $BootImagesCount = ($BootImages | Measure-Object).Count
                    foreach ($BootImage in $BootImages) {
                        $BootImageCount++
                        $BootImageName = $BootImage.Name
                        $BootImageID = $BootImage.PackageID
                        Update-StatusBar -Activity Validating -Text "Validating operating system image $($BootImageCount) / $($BootImagesCount)"
                        if ($BootImage.PkgSourcePath -ne $null) {
                            if ($BootImage.PkgSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                                $ExistingBootImageSourcePath = $BootImage.PkgSourcePath
                                $UpdatedBootImageSourcePath = $BootImage.PkgSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                                $DGVResults.Rows.Add($true, $BootImageName, $ExistingBootImageSourcePath, $UpdatedBootImageSourcePath, $BootImageID)
                                Write-OutputBox -OutputBoxMessage "Successfully validated boot image '$($BootImageName)'" -Type INFO
                                [System.Windows.Forms.Application]::DoEvents()
                            }
                            else {
                                Write-OutputBox -OutputBoxMessage "No matching content source for boot image '$($BootImageName)' was found" -Type INFO
                            }
                        }
                        else {
                            Write-OutputBox -OutputBoxMessage "Validation of boot image '$($BootImageName)' detected that there was no associated content" -Type INFO
                        }
                    }
                    Update-StatusBar -Activity Ready -Text " "
                    Write-OutputBox -OutputBoxMessage "Completed content source validation" -Type INFO
                    $ButtonStart.Enabled = $true
                }
                if ($Action -eq "Update") {
                    # Determine selected row count
                    $BootImageCount = 0
                    $BootImageRowCount = 0
                    for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                        if ($DGVResults.Rows[$RowIndex].Cells[0].Value -eq $true) {
                            $BootImageRowCount++
                        }
                    }
                    # Enumerate through selected rows in DataGridView
                    for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                        $CellBootImageName = $DGVResults.Rows[$RowIndex].Cells[1].Value
                        $CellBootImageSelected = $DGVResults.Rows[$RowIndex].Cells[0].Value
                        $CellBootImageID = $DGVResults.Rows[$RowIndex].Cells[4].Value
                        if ($CellBootImageSelected -eq $true) {
                            $BootImageCount++
                            $BootImage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_BootImagePackage" -ComputerName $SiteServer -Filter "PackageID like '$($CellBootImageID)'"
                            if ($BootImage -ne $null) {
                                $BootImageName = $BootImage.Name
                                Update-StatusBar -Activity Validating -Text "Updating boot image $($BootImageCount) / $($BootImageRowCount)"
                                [System.Windows.Forms.Application]::DoEvents()
                                if ($BootImage.PkgSourcePath -ne $null) {
                                    if ($BootImage.PkgSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                                        $ExistingBootImageSourcePath = $BootImage.PkgSourcePath
                                        $UpdatedBootImageSourcePath = $BootImage.PkgSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                                        # Copy files
                                        if ($CopyFiles -eq $true) {
                                            if (-not(Test-Path -Path $UpdatedBootImageSourcePath)) {
                                                New-Item -Path $UpdatedBootImageSourcePath -ItemType Directory | Out-Null
                                            }
                                            if ((Get-ChildItem -Path $UpdatedBootImageSourcePath | Measure-Object).Count -eq 0) {
                                                if (Test-Path -Path $ExistingBootImageSourcePath) {
                                                    $ExistingBootImageSourcePathItems = Get-ChildItem -Path $ExistingBootImageSourcePath
                                                    Write-OutputBox -OutputBoxMessage "Copying content source files from $($ExistingBootImageSourcePath) to $($UpdatedBootImageSourcePath)" -Type INFO
                                                    foreach ($ExistingBootImageSourcePathItem in $ExistingBootImageSourcePathItems) {
                                                        Copy-Item -Path $ExistingBootImageSourcePathItem.FullName -Destination $UpdatedBootImageSourcePath -Force -Recurse
                                                    }
                                                }
                                                else {
                                                    Write-OutputBox -OutputBoxMessage "Unable to access $($ExistingBootImageSourcePath)" -Type WARNING
                                                }
                                            }
                                        }
                                        # Update content source
                                        $BootImage.Get()
                                        $BootImage.PkgSourcePath = $UpdatedBootImageSourcePath
                                        $BootImage.Put() | Out-Null
                                        $ValidateBootImage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_BootImagePackage" -ComputerName $SiteServer -Filter "PackageID like '$($CellBootImageID)'"
                                        if ($ValidateBootImage.PkgSourcePath -eq $UpdatedBootImageSourcePath) {
                                            Write-OutputBox -OutputBoxMessage "Updated boot image '$($BootImageName)'" -Type INFO
                                        }
                                        else {
                                            Write-OutputBox -OutputBoxMessage "An error occurred while updating boot image '$($BootImageName)'" -Type ERROR
                                        }
                                        [System.Windows.Forms.Application]::DoEvents()
                                    }
                                    else {
                                        Write-OutputBox -OutputBoxMessage "No matching content source for boot image '$($BootImageName)' was found" -Type INFO
                                    }
                                }
                                else {
                                    Write-OutputBox -OutputBoxMessage "Validation of boot image '$($BootImageName)' detected that there was no associated content" -Type INFO
                                }
                            }
                        }
                    }
                    Update-StatusBar -Activity Ready -Text " "
                    Write-OutputBox -OutputBoxMessage "Completed updating content sources" -Type INFO
                    $ButtonStart.Enabled = $false
                }
            }
        }

        # Forms
        $Form = New-Object System.Windows.Forms.Form    
        $Form.Size = New-Object System.Drawing.Size(900,700)  
        $Form.MinimumSize = New-Object System.Drawing.Size(900,700)
        $Form.MaximumSize = New-Object System.Drawing.Size([System.Int32]::MaxValue,[System.Int32]::MaxValue)
        $Form.SizeGripStyle = "Show"
        $Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHome + "\powershell.exe")
        $Form.Text = "ConfigMgr Content Source Update Tool 1.0.0"
        $Form.ControlBox = $true
        $Form.TopMost = $false

        # Buttons
        $ButtonStart = New-Object System.Windows.Forms.Button 
        $ButtonStart.Location = New-Object System.Drawing.Size(762,35)
        $ButtonStart.Size = New-Object System.Drawing.Size(95,30) 
        $ButtonStart.Text = "Update"
        $ButtonStart.TabIndex = "3"
        $ButtonStart.Anchor = "Top, Right"
        $ButtonStart.Enabled = $false
        $ButtonStart.Add_Click({
            if ($CheckBoxCopyContent.Checked -eq $true) {
                $CopyFiles = $true
            }
            else {
                $CopyFiles = $false
            }
            switch ($ComboBoxTypes.SelectedItem) {
                "Application" {
                    Invoke-CleanControls -Option Log
                    Update-ApplicationContentSource -Action Update -CopyFiles:$CopyFiles
                }
                "Package" {
                    Invoke-CleanControls -Option Log
                    Update-PackageContentSource -Action Update -CopyFiles:$CopyFiles
                }
                "Deployment Package" {
                    Invoke-CleanControls -Option Log
                    Update-DeploymentPackageContentSource -Action Update -CopyFiles:$CopyFiles
                }
                "Driver" {
                    Invoke-CleanControls -Option Log
                    Update-DriverContentSource -Action Update -CopyFiles:$CopyFiles
                }
                "Driver Package" {
                    Invoke-CleanControls -Option Log
                    Update-DriverPackageContentSource -Action Update -CopyFiles:$CopyFiles
                }
                "Operating System Image" {
                    Invoke-CleanControls -Option Log
                    Update-OperatingSystemImageContentSource -Action Update -CopyFiles:$CopyFiles
                }
                "Operating System Package" {
                    Invoke-CleanControls -Option Log
                    Update-OperatingSystemPackageContentSource -Action Update -CopyFiles:$CopyFiles
                }
                "Boot Image" {
                    Invoke-CleanControls -Option Log
                    Update-BootImageContentSource -Action Update -CopyFiles:$CopyFiles
                }
            }
        })
        $ButtonValidate = New-Object System.Windows.Forms.Button 
        $ButtonValidate.Location = New-Object System.Drawing.Size(762,75)
        $ButtonValidate.Size = New-Object System.Drawing.Size(95,30) 
        $ButtonValidate.Text = "Validate"
        $ButtonValidate.TabIndex = "2"
        $ButtonValidate.Anchor = "Top, Right"
        $ButtonValidate.Enabled = $false
        $ButtonValidate.Add_Click({
            if ($CheckBoxCopyContent.Checked -eq $true) {
                $CopyFiles = $true
            }
            else {
                $CopyFiles = $false
            }
            switch ($ComboBoxTypes.SelectedItem) {
                "Application" {
                    Invoke-CleanControls -Option All
                    Update-ApplicationContentSource -Action Validate -CopyFiles:$CopyFiles
                }
                "Package" {
                    Invoke-CleanControls -Option All
                    Update-PackageContentSource -Action Validate -CopyFiles:$CopyFiles
                }
                "Deployment Package" {
                    Invoke-CleanControls -Option All
                    Update-DeploymentPackageContentSource -Action Validate -CopyFiles:$CopyFiles
                }
                "Driver" {
                    Invoke-CleanControls -Option All
                    Update-DriverContentSource -Action Validate -CopyFiles:$CopyFiles
                }
                "Driver Package" {
                    Invoke-CleanControls -Option All
                    Update-DriverPackageContentSource -Action Validate -CopyFiles:$CopyFiles
                }
                "Operating System Image" {
                    Invoke-CleanControls -Option All
                    Update-OperatingSystemImageContentSource -Action Validate -CopyFiles:$CopyFiles
                }
                "Operating System Package" {
                    Invoke-CleanControls -Option All
                    Update-OperatingSystemPackageContentSource -Action Validate -CopyFiles:$CopyFiles
                }
                "Boot Image" {
                    Invoke-CleanControls -Option All
                    Update-BootImageContentSource -Action Validate -CopyFiles:$CopyFiles
                }
            }    
        })

        # GroupBoxes
        $GBMatch = New-Object -TypeName System.Windows.Forms.GroupBox
        $GBMatch.Location = New-Object -TypeName System.Drawing.Size(10,10)
        $GBMatch.Size = New-Object -TypeName System.Drawing.Size(500,50)
        $GBMatch.Anchor = "Top, Left, Right"
        $GBMatch.Text = "Match pattern for Content Source locations"
        $GBReplace = New-Object -TypeName System.Windows.Forms.GroupBox
        $GBReplace.Location = New-Object -TypeName System.Drawing.Size(10,70)
        $GBReplace.Size = New-Object -TypeName System.Drawing.Size(500,50)
        $GBReplace.Anchor = "Top, Left, Right"
        $GBReplace.Text = "Replace pattern for Content Source locations"
        $GBOptions = New-Object -TypeName System.Windows.Forms.GroupBox
        $GBOptions.Location = New-Object -TypeName System.Drawing.Size(520,10)
        $GBOptions.Size = New-Object -TypeName System.Drawing.Size(220,110)
        $GBOptions.Anchor = "Top, Right"
        $GBOptions.Text = "Options"
        $GBActions = New-Object -TypeName System.Windows.Forms.GroupBox
        $GBActions.Location = New-Object -TypeName System.Drawing.Size(750,10)
        $GBActions.Size = New-Object -TypeName System.Drawing.Size(120,110)
        $GBActions.Anchor = "Top, Right"
        $GBActions.Text = "Actions"
        $GBResults = New-Object -TypeName System.Windows.Forms.GroupBox
        $GBResults.Location = New-Object -TypeName System.Drawing.Size(10,130)
        $GBResults.Size = New-Object -TypeName System.Drawing.Size(860,315)
        $GBResults.Anchor = "Top, Bottom, Left, Right"
        $GBResults.Text = "Content Source information"
        $GBLog = New-Object -TypeName System.Windows.Forms.GroupBox
        $GBLog.Location = New-Object -TypeName System.Drawing.Size(10,455)
        $GBLog.Size = New-Object -TypeName System.Drawing.Size(860,175)
        $GBLog.Anchor = "Bottom, Left, Right"
        $GBLog.Text = "Logging"

        # ComboBoxes
        $ComboBoxTypes = New-Object System.Windows.Forms.ComboBox
        $ComboBoxTypes.Location = New-Object System.Drawing.Size(530,30) 
        $ComboBoxTypes.Size = New-Object System.Drawing.Size(200,20)
        $ComboBoxTypes.Items.AddRange(@("Application","Package","Deployment Package","Driver","Driver Package","Operating System Image","Operating System Upgrade Package","Boot Image"))
        $ComboBoxTypes.SelectedItem = "Application"
        $ComboBoxTypes.Anchor = "Top, Right"
        $ComboBoxTypes.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
        $ComboBoxTypes.Add_SelectedIndexChanged({
            $DGVResults.Rows.Clear()
            $ButtonStart.Enabled = $false
            if ($ComboBoxTypes.SelectedItem -eq "Application") {
                $DGVResults.Columns.Clear()
                $DGVResults.Columns.Insert(0,(New-Object -TypeName System.Windows.Forms.DataGridViewCheckBoxColumn))
                $DGVResults.Columns[0].Name = "Update"
                $DGVResults.Columns[0].Resizable = [System.Windows.Forms.DataGridViewTriState]::False
                $DGVResults.Columns[0].Width = "50"
                $DGVResults.Columns.Insert(1,(New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn))
                $DGVResults.Columns[1].Name = $ComboBoxTypes.SelectedItem
                $DGVResults.Columns[1].Width = "200"
                $DGVResults.Columns[1].ReadOnly = $true
                $DGVResults.Columns.Insert(2,(New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn))
                $DGVResults.Columns[2].Name = "Deployment Type"
                $DGVResults.Columns[2].AutoSizeMode = "Fill"
                $DGVResults.Columns[2].ReadOnly = $true
                $DGVResults.Columns.Insert(3,(New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn))
                $DGVResults.Columns[3].Name = "Existing Content Source"
                $DGVResults.Columns[3].AutoSizeMode = "Fill"
                $DGVResults.Columns[3].ReadOnly = $true
                $DGVResults.Columns.Insert(4,(New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn))
                $DGVResults.Columns[4].Name = "Updated Content Source"
                $DGVResults.Columns[4].AutoSizeMode = "Fill"
                $DGVResults.Columns[4].ReadOnly = $true
            }
            else {
                $DGVResults.Columns.Clear()
                $DGVResults.Columns.Insert(0,(New-Object -TypeName System.Windows.Forms.DataGridViewCheckBoxColumn))
                $DGVResults.Columns[0].Name = "Update"
                $DGVResults.Columns[0].Resizable = [System.Windows.Forms.DataGridViewTriState]::False
                $DGVResults.Columns[0].Width = "50"
                $DGVResults.Columns.Insert(1,(New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn))
                $DGVResults.Columns[1].Name = $ComboBoxTypes.SelectedItem
                $DGVResults.Columns[1].Width = "200"
                $DGVResults.Columns[1].ReadOnly = $true
                $DGVResults.Columns.Insert(2,(New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn))
                $DGVResults.Columns[2].Name = "Existing Content Source"
                $DGVResults.Columns[2].AutoSizeMode = "Fill"
                $DGVResults.Columns[2].ReadOnly = $true
                $DGVResults.Columns.Insert(3,(New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn))
                $DGVResults.Columns[3].Name = "Updated Content Source"
                $DGVResults.Columns[3].AutoSizeMode = "Fill"
                $DGVResults.Columns[3].ReadOnly = $true
                $DGVResults.Columns.Insert(4,(New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn))
                $DGVResults.Columns[4].Name = "ID"
                $DGVResults.Columns[4].AutoSizeMode = "Fill"
                $DGVResults.Columns[4].ReadOnly = $true
                $DGVResults.Columns[4].Visible = $false
            }
        })

        # CheckBoxes
        $CheckBoxCopyContent = New-Object System.Windows.Forms.CheckBox
        $CheckBoxCopyContent.Location = New-Object System.Drawing.Size(530,60) 
        $CheckBoxCopyContent.Size = New-Object System.Drawing.Size(200,20)
        $CheckBoxCopyContent.Text = "Copy content files to new location"
        $CheckBoxCopyContent.Anchor = "Top, Right"

        # TextBoxes
        $TextBoxMatch = New-Object System.Windows.Forms.TextBox
        $TextBoxMatch.Location = New-Object System.Drawing.Size(20,28) 
        $TextBoxMatch.Size = New-Object System.Drawing.Size(480,20)
        $TextBoxMatch.TabIndex = "0"
        $TextBoxMatch.Anchor = "Top, Left, Right"
        $TextBoxMatch.Add_TextChanged({
            if (($TextBoxMatch.Text.Length -ge 2) -and ($TextBoxReplace.Text.Length -ge 2)) {
                $ButtonValidate.Enabled = $true
            }
            else {
                $ButtonValidate.Enabled = $false
            }
        })
        $TextBoxReplace = New-Object System.Windows.Forms.TextBox
        $TextBoxReplace.Location = New-Object System.Drawing.Size(20,88) 
        $TextBoxReplace.Size = New-Object System.Drawing.Size(480,20)
        $TextBoxReplace.TabIndex = "1"
        $TextBoxReplace.Anchor = "Top, Left, Right"
        $TextBoxReplace.Add_TextChanged({
            if (($TextBoxMatch.Text.Length -ge 2) -and ($TextBoxReplace.Text.Length -ge 2)) {
                $ButtonValidate.Enabled = $true
            }
            else {
                $ButtonValidate.Enabled = $false
            }
        })

        # RichTextBox
        $OutputBox = New-Object System.Windows.Forms.RichTextBox
        $OutputBox.Location = New-Object System.Drawing.Size(20,475)
        $OutputBox.Size = New-Object System.Drawing.Size(838,145)
        $OutputBox.Anchor = "Bottom, Left, Right"
        $OutputBox.Font = "Courier New"
        $OutputBox.BackColor = "white"
        $OutputBox.ReadOnly = $true
        $OutputBox.MultiLine = $true

        # StatusBar
        $StatusBarPanelActivity = New-Object Windows.Forms.StatusBarPanel
        $StatusBarPanelActivity.Text = "Ready"
        $StatusBarPanelActivity.Width = "100"
        $StatusBarPanelProcessing = New-Object Windows.Forms.StatusBarPanel
        $StatusBarPanelProcessing.Text = ""
        $StatusBarPanelProcessing.AutoSize = "Spring"
        $StatusBar = New-Object Windows.Forms.StatusBar
        $StatusBar.Size = New-Object System.Drawing.Size(500,20)
        $StatusBar.ShowPanels = $true
        $StatusBar.SizingGrip = $false
        $StatusBar.AutoSize = "Full"
        $StatusBar.Panels.AddRange(@(
            $StatusBarPanelActivity, 
            $StatusBarPanelProcessing
        ))

        # DataGridViews
        $DGVResults = New-Object System.Windows.Forms.DataGridView
        $DGVResults.Location = New-Object System.Drawing.Size(20,150)
        $DGVResults.Size = New-Object System.Drawing.Size(838,285)
        $DGVResults.Anchor = "Top, Bottom, Left, Right"
        $DGVResults.ColumnHeadersVisible = $true
        $DGVResults.Columns.Insert(0,(New-Object -TypeName System.Windows.Forms.DataGridViewCheckBoxColumn))
        $DGVResults.Columns[0].Name = "Update"
        $DGVResults.Columns[0].Resizable = [System.Windows.Forms.DataGridViewTriState]::False
        $DGVResults.Columns[0].Width = "50"
        $DGVResults.Columns.Insert(1,(New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn))
        $DGVResults.Columns[1].Name = "Application"
        $DGVResults.Columns[1].Width = "200"
        $DGVResults.Columns[1].ReadOnly = $true
        $DGVResults.Columns.Insert(2,(New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn))
        $DGVResults.Columns[2].Name = "Deployment Type"
        $DGVResults.Columns[2].AutoSizeMode = "Fill"
        $DGVResults.Columns[2].ReadOnly = $true
        $DGVResults.Columns.Insert(3,(New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn))
        $DGVResults.Columns[3].Name = "Existing Content Source"
        $DGVResults.Columns[3].AutoSizeMode = "Fill"
        $DGVResults.Columns[3].ReadOnly = $true
        $DGVResults.Columns.Insert(4,(New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn))
        $DGVResults.Columns[4].Name = "Updated Content Source"
        $DGVResults.Columns[4].AutoSizeMode = "Fill"
        $DGVResults.Columns[4].ReadOnly = $true
        $DGVResults.AllowUserToAddRows = $false
        $DGVResults.AllowUserToDeleteRows = $false
        $DGVResults.ReadOnly = $false
        $DGVResults.MultiSelect = $true
        $DGVResults.ColumnHeadersHeightSizeMode = "DisableResizing"
        $DGVResults.RowHeadersWidthSizeMode = "DisableResizing"
        $DGVResults.RowHeadersVisible = $false
        $DGVResults.SelectionMode = "FullRowSelect"

        # Load Form
        Load-Form
    }
}

function Validate-CMMDeviceMigration {
    <#
    .SYNOPSIS
        Graphical user interface tool for validating device migration status in ConfigMgr 2012
    .DESCRIPTION
        Graphical user interface tool for validating device migration status in ConfigMgr 2012
    .PARAMETER SiteServer
        Site server name with SMS Provider installed
    .EXAMPLE
        Validate-CMMDeviceMigration -SiteServer CM01
        Validate device migration status on a Primary Site server called 'CM01':
    .NOTES
        Name:        Validate-CMMDeviceMigration
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        DateCreated: 2015-03-10
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed")]
        [string]$SiteServer
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
    }
    Process {
        function Load-Form {
            $Form.Controls.AddRange(@(
                $SBStatus, 
                $DGVMigrated, 
                $DGVNotMigrated, 
                $ButtonStart, 
                $ButtonClear, 
                $RTBInput, 
                $OutputBox, 
                $GBOutputBox, 
                $GBInput, 
                $GBMigrated, 
                $GBNotMigrated
            ))
            $Form.Add_Shown({
                $Form.Activate()
                $RTBInput.Select()
            })
	        [void]$Form.ShowDialog()
        }

        function Write-OutputBox {
	        param(
	        [parameter(Mandatory=$true)]
	        [string]$OutputBoxMessage,
	        [ValidateSet("WARNING","ERROR","INFO")]
	        [string]$Type,
            [switch]$NoNewLine
	        )
	        Process {
                $DateTime = (Get-Date).ToLongTimeString()
                if ($NoNewLine -eq $true) {
		            if ($OutputBox.Text.Length -eq 0) {
			            $OutputBox.Text = "$($OutputBoxMessage)"
			            [System.Windows.Forms.Application]::DoEvents()
                        $OutputBox.SelectionStart = $OutputBox.Text.Length
                        $OutputBox.ScrollToCaret()
		            }
		            else {
			            $OutputBox.AppendText("$($OutputBoxMessage)")
			            [System.Windows.Forms.Application]::DoEvents()
                        $OutputBox.SelectionStart = $OutputBox.Text.Length
                        $OutputBox.ScrollToCaret()
		            }
                }
                else {
		            if ($OutputBox.Text.Length -eq 0) {
			            $OutputBox.Text = "$($DateTime) - $($Type): $($OutputBoxMessage)"
			            [System.Windows.Forms.Application]::DoEvents()
                        $OutputBox.SelectionStart = $OutputBox.Text.Length
                        $OutputBox.ScrollToCaret()
		            }
		            else {
			            $OutputBox.AppendText("`n$($DateTime) - $($Type): $($OutputBoxMessage)")
			            [System.Windows.Forms.Application]::DoEvents()
                        $OutputBox.SelectionStart = $OutputBox.Text.Length
                        $OutputBox.ScrollToCaret()
		            }        
                }
	        }
        }

        function Get-CMDeviceAvailability {
            param(
            [parameter(Mandatory=$true)]
            [string]$DeviceName,
            [parameter(Mandatory=$true)]
            [int]$Count,
            [parameter(Mandatory=$true)]
            [int]$TotalCount
            )
            $SBPProcessingCount.Text = "Processing device $($Count) of $($TotalCount)"
            $Device = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_R_System -ComputerName $SiteServer -Filter "Name like '$($DeviceName)'"
            if ($Device -ne $null) {
                if ($Device.Client -eq 1) {
                    Write-OutputBox -OutputBoxMessage "Migrated: $($Device.Name)" -Type INFO
                    $DGVMigrated.Rows.Add($Device.Name)
                    $GBMigrated.Text = "Migrated: $($DGVMigrated.RowCount)"
                    [System.Windows.Forms.Application]::DoEvents()
                }
                if ($Device.Client -eq $null) {
                    Write-OutputBox -OutputBoxMessage "Not migrated: $($Device.Name)" -Type WARNING
                    $DGVNotMigrated.Rows.Add($Device.Name)
                    $GBNotMigrated.Text = "Not migrated: $($DGVNotMigrated.RowCount)"
                    [System.Windows.Forms.Application]::DoEvents()
                }
            }
            else {
                Write-OutputBox -OutputBoxMessage "Not migrated: $($DeviceName)" -Type WARNING
                $DGVNotMigrated.Rows.Add($DeviceName)
                $GBNotMigrated.Text = "Not migrated: $($DGVNotMigrated.RowCount)"
                [System.Windows.Forms.Application]::DoEvents()
            }
        }

        function Start-Search {
            $ButtonStart.Enabled = $false
            $SBPStatus.Text = "Processing"
            $GBMigrated.Text = "Migrated"
            $GBNotMigrated.Text = "Not migrated"
            $CurrentCount = 0
            foreach ($DGVObject in $Form.Controls) {
                if ($DGVObject.GetType().ToString() -like "System.Windows.Forms.DataGridView") {
                    $DGVObject.Rows.Clear()
                }
            }
            $Devices = $RTBInput.Text
            $DeviceArray = $Devices.Split("`n")
            if ($DeviceArray -ne $null) {
                foreach ($Device in $DeviceArray) {
                    $CurrentCount++
                    Get-CMDeviceAvailability -DeviceName $Device -Count $CurrentCount -TotalCount ($DeviceArray | Measure-Object).Count
                }
            }
            else {
                Write-OutputBox -OutputBoxMessage "No devices has been added to the list" -Type WARNING
            }
            Write-OutputBox -OutputBoxMessage "Finished processing $(($DeviceArray | Measure-Object).Count) devices" -Type INFO
            $ButtonStart.Enabled = $true
            $SBPStatus.Text = "Ready"
            $SBPProcessingCount.Text = ""
        }

        function Start-Clear {
            $RTBInput.ResetText()
            $DGVMigrated.Rows.Clear()
            $GBMigrated.Text = "Migrated"
            $GBNotMigrated.Text = "Not migrated"
            $DGVNotMigrated.Rows.Clear()
            $OutputBox.ResetText()

        }

        # Global variables
        $Global:ProcessedSuccess = 0
        $Global:ProcessedWarning = 0
        $Global:ProcessedError = 0

        # Assemblies
        [void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
        [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

        # Form
        $Form = New-Object System.Windows.Forms.Form    
        $Form.Size = New-Object System.Drawing.Size(950,700)  
        $Form.MinimumSize = New-Object System.Drawing.Size(950,700)
        $Form.MaximumSize = New-Object System.Drawing.Size(950,[int]::MaxValue)
        $Form.SizeGripStyle = "Show"
        $Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHome + "\powershell.exe")
        $Form.Text = "ConfigMgr Migration Status Tool 1.0"
        $Form.ControlBox = $true
        $Form.TopMost = $false

        # StatusBar
        $SBPStatus = New-Object Windows.Forms.StatusBarPanel
        $SBPStatus.Text = "Ready"
        $SBPStatus.Width = "100"
        $SBPTotalCount = New-Object Windows.Forms.StatusBarPanel
        $SBPTotalCount.Text = ""
        $SBPTotalCount.Width = "100"
        $SBPProcessingCount = New-Object Windows.Forms.StatusBarPanel
        $SBPProcessingCount.Text = ""
        $SBPProcessingCount.Width = "740"
        $SBStatus = New-Object Windows.Forms.StatusBar
        $SBStatus.ShowPanels = $true
        $SBStatus.SizingGrip = $false
        $SBStatus.AutoSize = "Full"
        $SBStatus.Panels.AddRange(@(
            $SBPStatus, 
            $SBPTotalCount, 
            $SBPProcessingCount
        ))

        # GrouBox
        $GBOutputBox = New-Object System.Windows.Forms.GroupBox
        $GBOutputBox.Location = New-Object System.Drawing.Size(10,480) 
        $GBOutputBox.Size = New-Object System.Drawing.Size(920,150) 
        $GBOutputBox.Text = "Logging"
        $GBOutputBox.Anchor = "Bottom, Left, Right"
        $GBInput = New-Object System.Windows.Forms.GroupBox
        $GBInput.Location = New-Object System.Drawing.Size(10,10) 
        $GBInput.Size = New-Object System.Drawing.Size(220,460) 
        $GBInput.Text = "Device List"
        $GBInput.Anchor = "Top, Left, Bottom"
        $GBMigrated = New-Object System.Windows.Forms.GroupBox
        $GBMigrated.Location = New-Object System.Drawing.Size(240,10) 
        $GBMigrated.Size = New-Object System.Drawing.Size(340,460) 
        $GBMigrated.Text = "Migrated"
        $GBMigrated.Anchor = "Top, Bottom, Left, Right"
        $GBNotMigrated = New-Object System.Windows.Forms.GroupBox
        $GBNotMigrated.Location = New-Object System.Drawing.Size(590,10) 
        $GBNotMigrated.Size = New-Object System.Drawing.Size(340,460) 
        $GBNotMigrated.Text = "Not migrated"
        $GBNotMigrated.Anchor = "Top, Bottom, Right"

        # Button
        $ButtonStart = New-Object System.Windows.Forms.Button 
        $ButtonStart.Location = New-Object System.Drawing.Size(125,427)
        $ButtonStart.Size = New-Object System.Drawing.Size(95,30) 
        $ButtonStart.Text = "Start"
        $ButtonStart.TabIndex = 1
        $ButtonStart.Anchor = "Bottom, Left, Right"
        $ButtonStart.Add_Click({Start-Search})
        $ButtonClear = New-Object System.Windows.Forms.Button 
        $ButtonClear.Location = New-Object System.Drawing.Size(20,427)
        $ButtonClear.Size = New-Object System.Drawing.Size(95,30) 
        $ButtonClear.Text = "Clear"
        $ButtonClear.TabIndex = 2
        $ButtonClear.Anchor = "Bottom, Left, Right"
        $ButtonClear.Add_Click({Start-Clear})

        # RichTextBox
        $OutputBox = New-Object System.Windows.Forms.RichTextBox
        $OutputBox.Location = New-Object System.Drawing.Size(20,500)
        $OutputBox.Size = New-Object System.Drawing.Size(900,120)
        $OutputBox.Anchor = "Bottom, Left, Right"
        $OutputBox.Font = "Courier New"
        $OutputBox.BackColor = "white"
        $OutputBox.ReadOnly = $true
        $OutputBox.MultiLine = $True
        $RTBInput = New-Object System.Windows.Forms.RichTextBox
        $RTBInput.Location = New-Object System.Drawing.Size(20,27)
        $RTBInput.Size = New-Object System.Drawing.Size(200,390)
        $RTBInput.TabIndex = 1
        $RTBInput.Anchor = "Top, Bottom, Left, Right"
        $RTBInput.Add_TextChanged({
            $InputText = $RTBInput.Text
            $InputText = $InputText.Split("`n")
            $InputCount = ($InputText | Measure-Object).Count
            $SBPTotalCount.Text = "Row count: $($InputCount)"
        })

        # DataGriView
        $DGVMigrated = New-Object System.Windows.Forms.DataGridView
        $DGVMigrated.Location = New-Object System.Drawing.Size(250,30)
        $DGVMigrated.Size = New-Object System.Drawing.Size(320,425)
        $DGVMigrated.Anchor = "Top, Bottom, Left, Right"
        $DGVMigrated.ColumnCount = 1
        $DGVMigrated.ColumnHeadersVisible = $true
        $DGVMigrated.Columns[0].Name = "Device"
        $DGVMigrated.Columns[0].AutoSizeMode = "Fill"
        $DGVMigrated.AllowUserToAddRows = $false
        $DGVMigrated.AllowUserToDeleteRows = $false
        $DGVMigrated.ReadOnly = $true
        $DGVMigrated.MultiSelect = $true
        $DGVMigrated.ColumnHeadersHeightSizeMode = "DisableResizing"
        $DGVMigrated.RowHeadersWidthSizeMode = "DisableResizing"
        $DGVMigrated.RowHeadersVisible = $false
        $DGVNotMigrated = New-Object System.Windows.Forms.DataGridView
        $DGVNotMigrated.Location = New-Object System.Drawing.Size(600,30)
        $DGVNotMigrated.Size = New-Object System.Drawing.Size(320,425)
        $DGVNotMigrated.Anchor = "Top, Bottom, Left, Right"
        $DGVNotMigrated.ColumnCount = 1
        $DGVNotMigrated.ColumnHeadersVisible = $true
        $DGVNotMigrated.Columns[0].Name = "Device"
        $DGVNotMigrated.Columns[0].AutoSizeMode = "Fill"
        $DGVNotMigrated.AllowUserToAddRows = $false
        $DGVNotMigrated.AllowUserToDeleteRows = $false
        $DGVNotMigrated.ReadOnly = $true
        $DGVNotMigrated.MultiSelect = $true
        $DGVNotMigrated.ColumnHeadersHeightSizeMode = "DisableResizing"
        $DGVNotMigrated.RowHeadersWidthSizeMode = "DisableResizing"
        $DGVNotMigrated.RowHeadersVisible = $false

        # Load Form
        Load-Form
    }
}

function Start-CMMSoftwareUpdateCIUniqueIDCleanup {
    <#
    .SYNOPSIS
        Remove memberships between Software Updates with a specific CI_UniqueID and Software Update Groups
    .DESCRIPTION
        Remove memberships between Software Updates with a specific CI_UniqueID and Software Update Groups. Specify a single CI_UniqueID to the CIUniqueID parameter or multiple CI_UniqueID's in a text file and point the Path parameter to the location of the text file.
    .PARAMETER SiteServer
        Site server name with SMS Provider installed
    .PARAMETER CIUniqueID
        Specify a single or an array of CI_UniqueIDs to remove memberships from Software Update Groups
    .PARAMETER Path
        Path to a text file containing CI_UniqueID's on a seperate line that will their have memberships with Software Update Groups removed
    .EXAMPLE
        Start-CMMSoftwareUpdateCIUniqueIDCleanup -SiteServer CM01 -CIUniqueID '79e81e3e-97f6-4059-8a25-6732f8ec0a94', '7f3790b2-cb25-4d3c-b8f9-8ffb9f3fdd82'
        Remove memberships between Software Update Groups and Software Updates with CI_UniqueID '7f3790b2-cb25-4d3c-b8f9-8ffb9f3fdd82' and '79e81e3e-97f6-4059-8a25-6732f8ec0a94' on a Primary Site server called 'CM01':

        Start-CMMSoftwareUpdateCIUniqueIDCleanup -SiteServer CM01 -Path 'C:\Temp\CIUniqueIDs.txt'
        Remove memberships between Software Update Groups and Software Updates with CI_UniqueID saved in the text file 'C:\Temp\CIUniqueIDs.txt' on a Primary Site server called 'CM01':
    .NOTES
        Name:        Start-CMMSoftwareUpdateCIUniqueIDCleanup
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        DateCreated: 2015-08-22
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory=$true, ParameterSetName="Array", HelpMessage="Site server name with SMS Provider installed")]
        [parameter(ParameterSetName="Text")]
        [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
        [ValidateNotNullorEmpty()]
        [string]$SiteServer,
        [parameter(Mandatory=$true, ParameterSetName="Array", HelpMessage="Specify a single or an array of CI_UniqueIDs to remove memberships from Software Update Groups")]
        [ValidateNotNullorEmpty()]
        [string[]]$CIUniqueID,
        [parameter(Mandatory=$true, ParameterSetName="Text", HelpMessage="Path to a text file containing CI_UniqueID's on a seperate line that will their have memberships with Software Update Groups removed")]
        [ValidateNotNullorEmpty()]
        [ValidatePattern("^(?:[\w]\:|\\)(\\[a-z_\-\s0-9\.]+)+\.(txt)$")]
        [ValidateScript({
	        # Check if path contains any invalid characters
	        if ((Split-Path -Path $_ -Leaf).IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
		        Write-Warning -Message "$(Split-Path -Path $_ -Leaf) contains invalid characters" ; break
	        }
	        else {
		        # Check if the whole directory path exists
		        if (-not(Test-Path -Path (Split-Path -Path $_) -PathType Container -ErrorAction SilentlyContinue)) {
			        Write-Warning -Message "Unable to locate part of or the whole specified path" ; break
		        }
		        elseif (Test-Path -Path (Split-Path -Path $_) -PathType Container -ErrorAction SilentlyContinue) {
			        return $true
		        }
		        else {
			        Write-Warning -Message "Unhandled error" ; break
		        }
	        }
        })]
        [string]$Path
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
        # Construct an array list of CI Unique ID's based upon specified text file
        $CIUniqueList = Get-Content -Path $Path
        $RemovedSoftwareUpdatesList = New-Object -TypeName System.Collections.ArrayList
        $RemovedSoftwareUpdatesList.AddRange(@($CIUniqueList))
    }
    Process {
        try {
            $AuthorizationLists = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_AuthorizationList -ComputerName $SiteServer -ErrorAction Stop
            foreach ($AuthorizationList in $AuthorizationLists) {
                $AuthorizationList.Get()
                Write-Verbose -Message "Enumerating Software Update Group: $($AuthorizationList.LocalizedDisplayName)"
                foreach ($CI in $CIUniqueList) {
                    $CIObject = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_SoftwareUpdate -ComputerName $SiteServer -Filter "CI_UniqueID = '$($CI)'" -ErrorAction Stop
                    Write-Verbose -Message "Searching for Software Update with CI_UniqueID: $($CIObject.CI_UniqueID)"
                    if ($CIObject.CI_ID -in ($AuthorizationList.Updates)) {
                        if ($PSCmdlet.ShouldProcess($AuthorizationList.LocalizedDisplayName, "Remove Software Update with CI_UniqueID '$($CIObject.CI_UniqueID)'")) {
                            Write-Verbose -Message "Software Update with CI_UniqueID '$($CIObject.CI_UniqueID)' and 'KB$($CIObject.ArticleID)' will be removed from '$($AuthorizationList.LocalizedDisplayName)'"
                            $NewSoftwareUpdatesList = New-Object -TypeName System.Collections.ArrayList
                            $NewSoftwareUpdatesList.AddRange(@($AuthorizationList.Updates)) | Out-Null
                            Write-Verbose -Message "Count for '$($AuthorizationList.LocalizedDisplayName)': $($NewSoftwareUpdatesList.Count)"
                            Write-Verbose -Message "Removing Software Update with CI_UniqueID '$($CIObject.CI_UniqueID)' from '$($AuthorizationList.LocalizedDisplayName)'"
                            $NewSoftwareUpdatesList.Remove($CIObject.CI_ID)
                            $ErrorActionPreference = "Stop"
                            try {
                                $AuthorizationList.Updates = $NewSoftwareUpdatesList
                                $AuthorizationList.Put() | Out-Null
                                Write-Verbose -Message "Count for '$($AuthorizationList.LocalizedDisplayName)': $($NewSoftwareUpdatesList.Count)"
                                Write-Warning -Message "Successfully removed Software Update with CI_UniqueID '$($CIObject.CI_UniqueID)' from '$($AuthorizationList.LocalizedDisplayName)'"
                            }
                            catch [System.Exception] {
                                Write-Warning -Message "Unable to remove Software Update with CI_UniqueID '$($CIObject.CI_UniqueID)' from '$($AuthorizationList.LocalizedDisplayName)'"
                            }
                        }
                    }
                }
            }
        }
        catch [System.Exception] {
            Write-Warning -Message "Unable to retrieve Software Update Groups from $($SiteServer)"
        }
    }
}