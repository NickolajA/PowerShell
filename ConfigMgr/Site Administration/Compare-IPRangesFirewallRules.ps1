param(
[parameter(Mandatory=$true)]
$IPRangeOld,
[parameter(Mandatory=$true)]
$IPRangeNew
)
Begin {
    $ReferenceObject = $IPRangeOld.Split(",")
    $ReferenceObjectCount = [System.Math]::Round(($ReferenceObject | Measure-Object).Count / 2)
    $DifferenceObject = $IPRangeNew.Split(",")
    $DifferenceObjectCount = [System.Math]::Round(($DifferenceObject | Measure-Object).Count / 2)
    if ($ReferenceObjectCount -ge $DifferenceObjectCount) {
        $SyncWindow = $ReferenceObjectCount
    }
    else {
        $SyncWindow = $DifferenceObjectCount
    }
}
Process {
    Compare-Object -ReferenceObject $ReferenceObject -DifferenceObject $DifferenceObject -SyncWindow $SyncWindow | ForEach-Object {
        if ($_.SideIndicator -like "=>") {
            $Object = New-Object -TypeName PSObject
            $Object | Add-Member -MemberType NoteProperty -Name Difference -Value ($_.InputObject)
            $Object | Add-Member -MemberType NoteProperty -Name Origin -Value ($_.SideIndicator)
            Write-Output $Object
        }
    }
}