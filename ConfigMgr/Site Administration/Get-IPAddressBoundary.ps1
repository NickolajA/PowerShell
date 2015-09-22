param(
[parameter(Mandatory=$true)]
$SiteServer,
[parameter(Mandatory=$true)]
$IPAddress
)

function Get-CMSiteCode {
    $CMSiteCode = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer | Select-Object -ExpandProperty SiteCode
    return $CMSiteCode
}

$Results = 0
$Boundary = Get-WmiObject -Namespace "root\SMS\site_$(Get-CMSiteCode)" -Class SMS_Boundary -Filter "BoundaryType = 3"
$BoundaryCount = ($Boundary | Measure-Object).Count
if ($BoundaryCount -ge 1) {
    $Boundary | ForEach-Object {
        $BoundaryName = $_.DisplayName
        $BoundaryNameLength = $_.DisplayName.Length
        $BoundaryValue = $_.Value.Split("-")
        $IPStartRange = $BoundaryValue[0]
        $IPEndRange = $BoundaryValue[1]
        $ParseIP = [System.Net.IPAddress]::Parse($IPAddress).GetAddressBytes()
        [Array]::Reverse($ParseIP)
        $ParseIP = [System.BitConverter]::ToUInt32($ParseIP, 0)
        $ParseStartIP = [System.Net.IPAddress]::Parse($IPStartRange).GetAddressBytes()
        [Array]::Reverse($ParseStartIP)
        $ParseStartIP = [System.BitConverter]::ToUInt32($ParseStartIP, 0)
        $ParseEndIP = [System.Net.IPAddress]::Parse($IPEndRange).GetAddressBytes()
        [Array]::Reverse($ParseEndIP)
        $ParseEndIP = [System.BitConverter]::ToUInt32($ParseEndIP, 0)
        if (($ParseStartIP -le $ParseIP) -and ($ParseIP -le $ParseEndIP)) {
            if ($BoundaryName.Length -ge 1) {
                $Results = 1
                Write-Output "`nIP address '$($IPAddress)' is within the following boundary:"
                Write-Output "Description: $($BoundaryName)`n"
            }
            else {
                $Results = 1
                Write-Output "`nIP address '$($IPAddress)' is within the following boundary:"
                Write-Output "Range: $($_.Value)`n"
            }
        }
    }
    if ($Results -eq 0) {
        Write-Output "`nIP address '$($IPAddress)' was not found in any boundary`n"
    }
}
else {
    Write-Output "`nNo IP range boundaries was found`n"
}