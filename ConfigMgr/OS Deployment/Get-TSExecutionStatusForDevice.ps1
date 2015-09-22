[CmdletBinding()]
param(
[parameter(Mandatory=$true)]
$SiteServer,
[parameter(Mandatory=$true)]
$SiteCode,
[parameter(Mandatory=$true)]
$ComputerName,
[parameter(Mandatory=$true)]
$PastHours
)

$TimeFrame = [System.Management.ManagementDateTimeConverter]::ToDmtfDateTime((Get-Date).AddHours(-$PastHours))
$TSSummary = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_StatusMessage -ComputerName $SiteServer -Filter "(Component like 'Task Sequence Engine') AND (MachineName like '$($ComputerName)' AND (MessageID = 11143))" -ErrorAction Stop
$StatusMessageCount = ($TSSummary | Measure-Object).Count
if (($TSSummary -ne $null) -and ($StatusMessageCount -eq 1)) {
    foreach ($Object in $TSSummary) {
        if (($Object.Time -ge $TimeFrame)) {
            $PSObject = New-Object -TypeName PSObject -Property @{
                SuccessExecutionTime = [System.Management.ManagementDateTimeconverter]::ToDateTime($Object.Time)
                MachineName = $Object.MachineName
            }
            Write-Output $PSObject
        }
    }
}
elseif (($TSSummary -ne $null) -and ($StatusMessageCount -ge 2)) {
    foreach ($Object in $TSSummary) {
        if ($Object.Time -ge $TimeFrame) {
            $PSObject = New-Object -TypeName PSObject -Property @{
                SuccessExecutionTime = [System.Management.ManagementDateTimeconverter]::ToDateTime($Object.Time)
                MachineName = $Object.MachineName
            }
            Write-Output $PSObject
        }
    }
}
else {
    Write-Output "No matches found"
}