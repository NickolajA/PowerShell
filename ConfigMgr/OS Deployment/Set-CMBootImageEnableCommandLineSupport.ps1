param(
[parameter(Mandatory=$true)]
$SiteServer,
[parameter(Mandatory=$true)]
$SiteCode,
[parameter(Mandatory=$true)]
$BootImageName,
[parameter(Mandatory=$false)]
[switch]$Commit
)
Begin {
    Write-Output "INFO: Querying SMS_BootImagePackage for Boot Images"
    $BootImages = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_BootImagePackage -Filter "Name like '%$($BootImageName)%'"
    if ($BootImages -ne $null) {
        if (($BootImages | Measure-Object).Count -eq 1) {
            Write-Output "INFO: Located $(($BootImages | Measure-Object).Count) Boot Image called '$($BootImages.Name)'"
        }
        else {
            Write-Output "INFO: Located $(($BootImages | Measure-Object).Count) Boot Images called:"
            foreach ($Boot in $BootImages) {
                Write-Output "INFO: '$($Boot.Name)'"
            }
        }
    }
}
Process {
    if ($Commit) {
        foreach ($BootImage in $BootImages) {
            $BootImage = [wmi]"$($BootImage.__PATH)"
            $BootImage.EnableLabShell = $true
            $BootImage.Put()
        }
    }
    else {
        Write-Output "INFO: The Commit switch was not specified, will not edit any found instances"
    }
}


