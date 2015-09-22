<#
.SYNOPSIS
    Get the Primary User and Device relationship by assignment source
.DESCRIPTION
    This script will get all Primary User and Device relationships assigned by the specified assignment sources
.PARAMETER SiteServer
    Site server name with SMS Provider installed
.PARAMETER DeviceName
    Specify a Device names that has a user machine relationship that will be removed
.EXAMPLE
    .\Remove-PrimaryDeviceRelationship.ps1 -SiteServer CM01 -DeviceName CL01
    Removes a relationship between a device called 'CL01' and the primary user on a Primary Site server called 'CM01':
.NOTES
    Script name: Remove-PrimaryDeviceRelationship.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    DateCreated: 2015-04-20
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,
    [parameter(Mandatory=$true, HelpMessage="Specify a Device names that has a user machine relationship that will be removed")]
    [ValidateNotNullOrEmpty()]
    [string[]]$DeviceName
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
    catch [Exception] {
        Write-Warning -Message "Unable to determine SiteCode" ; break
    }
}
Process {
    try {
        foreach ($Device in $DeviceName) {
            $UserMachineRelations = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_UserMachineRelationship -ComputerName $SiteServer -Filter "ResourceName like '$($Device)'"
            if ($UserMachineRelations -ne $null) {
                if ($PSCmdlet.ShouldProcess($UserMachineRelations.__PATH, "Remove")) {
                    Remove-WmiObject -InputObject $UserMachineRelations
                }
            }
        }
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied"
    }
    catch [Exception] {
        Write-Error -Message "An error occured while trying to remove a WMI instance"
    }
}