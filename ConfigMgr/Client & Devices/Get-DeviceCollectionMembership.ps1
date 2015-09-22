<#
.SYNOPSIS
    List all Device Collections that a specific Device is a member of
.DESCRIPTION
    This script will list all Device Collections that a specific Device is a member of in ConfigMgr 2012
.PARAMETER SiteServer
    Site server name with SMS Provider installed
.PARAMETER DeviceName
    Enter the name of the device
.EXAMPLE
    .\Get-DeviceCollectionMembership.ps1 -SiteServer CM01 -DeviceName CL001
    List all Device Collections that a device called 'CL001' is a member of, on a Primary Site server called 'CM01':
.NOTES
    Script name: Get-DeviceCollectionMembership.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    DateCreated: 2015-06-11
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,
    [parameter(Mandatory=$true, HelpMessage="Enter the name of the device")]
    [ValidateNotNullOrEmpty()]
    [string]$DeviceName
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
    # Main code part goes here
    $Collections = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_FullCollectionMembership -Filter "Name like '$($DeviceName)'"
    if ($Collections -ne $null) {
        foreach ($Collection in $Collections) {
            $CollectionName = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Collection -Filter "CollectionID like '$($Collection.CollectionID)'" | Select-Object -ExpandProperty Name
            $PSObject = [PSCustomObject]@{
                CollectionName = $CollectionName
            }
            Write-Output -InputObject $PSObject
        }
    }
}