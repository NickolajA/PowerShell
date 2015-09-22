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
    .\Invoke-CMSoftwareUpdateCIUniqueIDCleanup.ps1 -SiteServer CM01 -CIUniqueID '79e81e3e-97f6-4059-8a25-6732f8ec0a94', '7f3790b2-cb25-4d3c-b8f9-8ffb9f3fdd82'
    Remove memberships between Software Update Groups and Software Updates with CI_UniqueID '7f3790b2-cb25-4d3c-b8f9-8ffb9f3fdd82' and '79e81e3e-97f6-4059-8a25-6732f8ec0a94' on a Primary Site server called 'CM01':

    .\Invoke-CMSoftwareUpdateCIUniqueIDCleanup.ps1 -SiteServer CM01 -Path 'C:\Temp\CIUniqueIDs.txt'
    Remove memberships between Software Update Groups and Software Updates with CI_UniqueID saved in the text file 'C:\Temp\CIUniqueIDs.txt' on a Primary Site server called 'CM01':
.NOTES
    Script name: Invoke-CMSoftwareUpdateCIUniqueIDCleanup.ps1
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