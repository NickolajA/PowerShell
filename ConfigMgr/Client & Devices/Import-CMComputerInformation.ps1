param(
[parameter(Mandatory=$true)]
$SiteServer,
[parameter(Mandatory=$true)]
$SiteCode,
[parameter(Mandatory=$true)]
$ComputerName,
[parameter(Mandatory=$true)]
[ValidatePattern('^([0-9a-fA-F]{2}[:]{0,1}){5}[0-9a-fA-F]{2}$')]
$MACAddress,
[parameter(Mandatory=$true)]
$CollectionName
)

try {
    $CollectionQuery = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer -Filter "Name='$CollectionName'"
    $WMIConnection = ([WMIClass]"\\$($SiteServer)\root\SMS\site_$($SiteCode):SMS_Site")
    $NewEntry = $WMIConnection.psbase.GetMethodParameters("ImportMachineEntry")
    $NewEntry.MACAddress = $MACAddress
    $NewEntry.NetbiosName = $ComputerName
    $NewEntry.OverwriteExistingRecord = $True
    $Resource = $WMIConnection.psbase.InvokeMethod("ImportMachineEntry",$NewEntry,$null)
    $NewRule = ([WMIClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_CollectionRuleDirect").CreateInstance()
    $NewRule.ResourceClassName = "SMS_R_SYSTEM"
    $NewRule.ResourceID = $Resource.ResourceID
    $NewRule.RuleName = $ComputerName
    $CollectionQuery.AddMemberShipRule($NewRule) | Out-Null
    Write-Output "INFO: Successfully imported $($ComputerName) to the $($CollectionName) collection"
} 
catch {
    Write-Error $_.Exception
}

try {
    Write-Output "INFO: Refreshing collection"
    if (Test-Connection -ComputerName $SiteServer -Count 15) {
        $CollectionQuery = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer -Filter "Name='$CollectionName'"
        $CollectionQuery.RequestRefresh() | Out-Null
    }
}
catch {
    Write-Error $_.Exception
}
