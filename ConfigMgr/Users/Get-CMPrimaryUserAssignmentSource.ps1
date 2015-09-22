<#
.SYNOPSIS
    Get the Primary User and Device relationship by assignment source
.DESCRIPTION
    This script will get all Primary User and Device relationships assigned by the specified assignment sources
.PARAMETER SiteServer
    Site server name with SMS Provider installed
.PARAMETER AssignedBy
    Specify what Primary User and Device relationships to be shown by filtering on assignment source
.PARAMETER Remove
    When specified, the matched relationship is removed
.PARAMETER ShowProgress
    Show a progressbar displaying the current operation
.EXAMPLE
    .\Get-CMPrimaryUserAssignmentSource.ps1 -SiteServer CM01 -AssignedBy Administrator, UsageAgent -ShowProgress
    Get all Primary User and Device relationships assigned by an Administrator and by the Usage Agent, while showing the progress on a Primary Site server called 'CM01':
.NOTES
    Script name: Get-CMPrimaryUserAssignmentSource.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    DateCreated: 2015-03-19
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,
    [parameter(Mandatory=$true, HelpMessage="Specify what Primary User and Device relationships to be shown by filtering on assignment source")]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("SoftwareCatalog","Administrator","UsageAgent","DeviceManagement","OSD","FastInstall","ExchangeServerConnector")]
    [string[]]$AssignedBy,
    [parameter(Mandatory=$false, HelpMessage="When specified, the matched relationship is removed")]
    [ValidateNotNullOrEmpty()]
    [switch]$Remove,
    [parameter(Mandatory=$false, HelpMessage="Show a progressbar displaying the current operation")]
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
    $AssignmentTable = [ordered]@{
        SoftwareCatalog = 1
        Administrator = 2
        UsageAgent = 4
        DeviceManagement = 5
        OSD = 6
        FastInstall = 7
        ExchangeServerConnector = 8
    }
}
Process {
    if ($PSBoundParameters["ShowProgress"]) {
        $ProgressCount = 0
    }
    $PrimaryUsers = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_UserMachineRelationship -ComputerName $SiteServer
    $PrimaryUserList = New-Object -TypeName System.Collections.ArrayList
    foreach ($Assignment in $AssignedBy) {
        $ConvertedAssignment = $AssignmentTable["$Assignment"]
        $PrimaryUserList.AddRange(@($PrimaryUsers | Where-Object { $_.Sources -eq $ConvertedAssignment }))
    }
    $PrimaryUsersCount = $PrimaryUserList.Count
    foreach ($PrimaryUser in $PrimaryUserList) {
        if ($PSBoundParameters["ShowProgress"]) {
            $ProgressCount++
        }
        $PSObject = [PSCustomObject]@{
            DeviceName = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_R_System -ComputerName $SiteServer -Filter "ResourceID like '$($PrimaryUser.ResourceID)'" | Select-Object -ExpandProperty Name
            PrimaryUserName = $PrimaryUser.UniqueUserName
            AssignedBy = $PrimaryUser.Sources | ForEach-Object {
                $CurrentAssignment = $_
                $AssignmentTable.GetEnumerator() | Where-Object { $_.Value -eq $CurrentAssignment } | Select-Object -ExpandProperty Key
            }
        }
        if ($PSBoundParameters["ShowProgress"]) {
            Write-Progress -Activity "Enumerating Primary User and Device Relationships" -Id 1 -Status "$($ProgressCount) / $($PrimaryUsersCount)" -CurrentOperation "Current device: $($PSObject.DeviceName)" -PercentComplete (($ProgressCount / $PrimaryUsersCount) * 100)
        }
        if (-not($PSBoundParameters["Remove"])) {
            Write-Output $PSObject
        }
        elseif ($PSBoundParameters["Remove"]) {
            if ($PSCmdlet.ShouldProcess("$($PSObject.DeviceName)", "Removing Primary User relationship")) {
                Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_UserMachineRelationship -ComputerName $SiteServer -Filter "ResourceID like '$($PrimaryUser.ResourceID)'" | Remove-WmiObject -Verbose:$false
            }
        }
    }
}