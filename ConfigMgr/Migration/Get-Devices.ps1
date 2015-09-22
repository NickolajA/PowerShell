[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server name with SMS Provider installed")]
    [parameter(ParameterSetName="Text")]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [ValidateNotNullorEmpty()]
    [string]$SiteServer,
    [parameter(Mandatory=$true, HelpMessage="Specify a collection to get devices from")]
    [ValidateNotNullorEmpty()]
    [string]$CollectionName,
    [parameter(Mandatory=$false, HelpMessage="Specify a match pattern to search for in the device name")]
    [ValidateNotNullorEmpty()]
    [string]$Match
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
        $CollectionID = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Collection -Filter "Name like '$($CollectionName)'" -ErrorAction Stop | Select-Object -ExpandProperty CollectionID
        if ($CollectionID -ne $null) {
            $Devices = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_FullCollectionMembership -Filter "CollectionID like '$($CollectionID)'" -ErrorAction Stop
            foreach ($Device in $Devices) {
                if ($PSBoundParameters["Match"]) {
                    if ($Device.Name -match $Match) {
                        $PSObject = [PSCustomObject]@{
                            DeviceName = $Device.Name
                        }
                        Write-Output -InputObject $PSObject
                    }
                }
                else {
                    $PSObject = [PSCustomObject]@{
                        DeviceName = $Device.Name
                    }
                    Write-Output -InputObject $PSObject
                }
            }
        }
        else {
            Write-Warning -Message "Unable to locate specified collection"
        }
    }
    catch [System.Exception] {
        Write-Warning -Message $_.Exception.Message ; break
    }
}