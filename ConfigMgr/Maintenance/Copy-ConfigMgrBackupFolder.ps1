#========================================================================
# Created on:   2013-09-13 09:49
# Created by:   Nickolaj Andersen
# Filename:     Copy-ConfigMgrBackupFolder.ps1
#========================================================================

$DailyBackupFolder = "\\fileshare\ContentLibrary\Daily"
$ArchiveFolder = "\\fileshare\ContentLibrary\Archive"
$Date = (Get-Date).ToShortDateString()
$DateKeep = (Get-Date).AddDays(-2).ToShortDateString()
$DailyFolder = "$($ArchiveFolder)\$($Date)"

if (-not(Test-Path -Path $DailyFolder)) {
	New-Item -Type Directory $DailyFolder | Out-Null
}

if ((Get-ChildItem -Path $DailyBackupFolder).Count -eq 1) {
	$BackupFolderPath = Get-ChildItem -Path $DailyBackupFolder | Select-Object -ExpandProperty FullName
	Move-Item -Path $BackupFolderPath -Destination $DailyFolder -Force
}

$ArchiveFolders = Get-ChildItem -Path $ArchiveFolder | Select-Object -ExpandProperty Name
$ArchiveFolders | ForEach-Object {
	if ($_ -lt $DateKeep) {
		Remove-Item -Path ($ArchiveFolder + "\" + $_) -Recurse -Force | Out-Null
	}
}