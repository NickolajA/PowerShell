[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true)]
    $DriveLetter,
    [parameter(Mandatory=$true)]
    $FolderName
)
Begin {
}
Process {
    $FolderStructure = @(
        "$($DriveLetter)\$($FolderName)",
        "$($DriveLetter)\$($FolderName)\Apps",
        "$($DriveLetter)\$($FolderName)\Pkgs",
        "$($DriveLetter)\$($FolderName)\SUM",
        "$($DriveLetter)\$($FolderName)\SUM\ADRs",
        "$($DriveLetter)\$($FolderName)\OSD",
        "$($DriveLetter)\$($FolderName)\OSD\BootImages",
        "$($DriveLetter)\$($FolderName)\OSD\CSettings",
        "$($DriveLetter)\$($FolderName)\OSD\DriverSources",
        "$($DriveLetter)\$($FolderName)\OSD\DriverPackages",
        "$($DriveLetter)\$($FolderName)\OSD\OSImages",
        "$($DriveLetter)\$($FolderName)\OSD\MDT",
        "$($DriveLetter)\$($FolderName)\OSD\MDT\Settings",
        "$($DriveLetter)\$($FolderName)\OSD\MDT\Toolkit"
    )
    $FolderStructure | ForEach-Object {
        try {
            if (-not(Test-Path -Path $_ -ErrorAction SilentlyContinue)) {
                Write-Output "INFO: Creating folder $($_)"
                New-Item -Path $_ -ItemType Directory | Out-Null
            }
        }
        catch {
            Write-Error $_.Exception
        }
    }
}
End {
}