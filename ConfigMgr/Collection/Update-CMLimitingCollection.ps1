<#
.SYNOPSIS
    Update limiting collections on specific device collections matching a specified target limiting collection.
.DESCRIPTION
    Update limiting collections on specific device collections matching a specified target limiting collection.
.PARAMETER SiteServer
    Site server name with SMS Provider installed
.PARAMETER TargetLimitingCollection
    Collections that matches any of the targeted limiting collections will be updated with the specified limiting collection
.PARAMETER LimitingCollection
    Limiting collection that will be set on target collection
.PARAMETER ShowProgress
    Show a progressbar displaying the current operation
.EXAMPLE
    .\Update-CMLimitingCollection.ps1 -TargetLimitingCollection @("TestCollection1","TestCollection2") -LimitingCollection "TestCollection3"
.NOTES
    Script name: Update-CMLimitingCollection.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    DateCreated: 2014-11-17
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed")]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,
    [parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, HelpMessage="Collections that matches any of the targeted limiting collections will be updated with the specified limiting collection")]
    [string[]]$TargetLimitingCollection,
    [parameter(Mandatory=$true, HelpMessage="Limiting collection that will be set on target collection")]
    [string]$LimitingCollection,
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
    if ($PSBoundParameters["ShowProgress"]) {
        $ProgressCount = 0
    }
    $DisabledCollections = @("SMSDM001","SMS000US","SMSDM003","SMS00001")
}
Process {
    try {
        $LimitingCollectionObject = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer -Filter "Name like '$($LimitingCollection)'" -ErrorAction Stop
        if ($LimitingCollectionObject -ne $null) {
            foreach ($Collection in $TargetLimitingCollection) {
                Write-Verbose "$Collection"
                $Collections = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer -Filter "LimitToCollectionName like '$($Collection)'" -ErrorAction Stop
                Write-Verbose -Message "SELECT * FROM SMS_Collection WHERE LimitToCollectionName like '$($Collection)'"
                if ($Collections -ne $null) {
                    Write-Verbose -Message "Query returned $(($Collections | Measure-Object).Count) objects"
                    foreach ($Coll in $Collections) {
                        if ($Coll.CollectionID -ne $LimitingCollectionObject.CollectionID) {
                            if ($Coll.CollectionID -notin $DisabledCollections) {
                                $LCName = $LimitingCollectionObject | Select-Object -ExpandProperty Name
                                $LCID = $LimitingCollectionObject | Select-Object -ExpandProperty CollectionID
                                if ($PSCmdlet.ShouldProcess("Collection: $($Coll.Name)","Update")) {
                                    $Coll.LimitToCollectionID = $LCID
                                    $Coll.LimitToCollectionName = $LCName
                                    $Coll.Put()
                                }
                            }
                            else {
                                Write-Warning -Message "Unable to set limiting collection on a protected collection"
                            }
                        }
                        else {
                            Write-Warning -Message "Unable to set limiting collection on collection '$($Coll.Name)' to '$($LimitingCollectionObject.Name)'"
                        }
                    }
                }
                else {
                    Write-Verbose -Message "Query returned $(($Collections | Measure-Object).Count) objects"
                }
            }
        }
        else {
            Write-Warning -Message "Unable to locate a collection called '$($LimitingCollection)'"
        }
    }
    catch [Exception] {
        Throw $_.Exception.Message
    }
}