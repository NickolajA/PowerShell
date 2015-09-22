[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server name with SMS Provider installed")]
    [ValidateNotNullorEmpty()]
    [string]$SiteServer,
    [parameter(Mandatory=$true, HelpMessage="Device name of the system to be removed from collection")]
    [ValidateNotNullorEmpty()]
    [string]$DeviceName
)
Begin {
    # Determine SiteCode from WMI
    try {
        Add-Content -Path C:\Windows\Temp\RemoveDeviceFromCollection.log -Value "Determine SiteCode for SMS Provider on: $($SiteServer)" -Force
        Write-Verbose "Determining SiteCode for Site Server: '$($SiteServer)'"
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
                Write-Debug "SiteCode: $($SiteCode)"
                Add-Content -Path C:\Windows\Temp\RemoveDeviceFromCollection.log -Value "SiteCode: $($SiteCode)" -Force
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
    # Get Device ResourceID
    Add-Content -Path C:\Windows\Temp\RemoveDeviceFromCollection.log -Value "Determine ResourceID for DeviceName: $($DeviceName)" -Force
    $ResourceIDs = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_R_System -Filter "Name like '$($DeviceName)'" | Select-Object -ExpandProperty ResourceID
    foreach ($ResourceID in $ResourceIDs) {
        Add-Content -Path C:\Windows\Temp\RemoveDeviceFromCollection.log -Value "ResourceID: $($ResourceID)" -Force
        # Determine if DeviceName is a member of OSD collections
        $CollectionIDList = New-Object -TypeName System.Collections.ArrayList
        # ArrayList of all Operating System Collection ID's
        $CollectionIDList.AddRange(@("PS100052","PS1000A8","PS1000A1","PS100053"))
        foreach ($CollectionID in $CollectionIDList) {
            $Collection = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Collection -Filter "CollectionID like '$($CollectionID)'"
            $Collection.Get()
            foreach ($CollectionRule in $Collection.CollectionRules) {
                # Remove Device from collection if there's a Collection Rule matching the DeviceName parameter
                if ($CollectionRule.ResourceID -like $ResourceID) {
                    Add-Content -Path C:\Windows\Temp\RemoveDeviceFromCollection.log -Value "Removing '$($DeviceName)' from '$($Collection.Name)" -Force
                    Write-Verbose -Message "Remove '$($DeviceName)' from '$($Collection.Name)'"
                    $Collection.DeleteMembershipRule($CollectionRule)
                }
            }
        }
    }
}