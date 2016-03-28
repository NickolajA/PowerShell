# Functions
function Write-LogFile {
	param(
		[parameter(Mandatory=$true, HelpMessage="Name of the log file, e.g. 'FileName'. File extension should not be specified")]
		[ValidateNotNullOrEmpty()]
		[string]$Name,
		[parameter(Mandatory=$true, HelpMessage="Value added to the specified log file")]
		[ValidateNotNullOrEmpty()]
		[string]$Value,
		[parameter(Mandatory=$true, HelpMessage="Choose a location where the log file will be created")]
		[ValidateNotNullOrEmpty()]
		[ValidateSet("UserTemp","WindowsTemp")]
		[string]$Location
	)
	# Determine log file location
	switch ($Location) {
		"UserTemp" { $LogLocation = ($env:TEMP + "\") }
		"WindowsTemp" { $LogLocation = ($env:SystemRoot + "\Temp\") }
	}
	# Construct log file name and location
	$LogFile = ($LogLocation + $Name + ".log")
	# Create log file unless it already exists
	if (-not(Test-Path -Path $LogFile -PathType Leaf)) {
		New-Item -Path $LogFile -ItemType File -Force | Out-Null
	}
	# Add timestamp to value
	$Value = (Get-Date).ToShortDateString() + ":" + (Get-Date).ToLongTimeString() + " - " + $Value
	
	# Add value to log file
	Add-Content -Value $Value -LiteralPath $LogFile
}

# Stage NTFSSecurity module
try {
    $NTFSSecurityModulePath = Join-Path -Path $env:WINDIR -ChildPath "System32\WindowsPowerShell\v1.0\Modules\NTFSSecurity"
    if (-not(Test-Path -Path $NTFSSecurityModulePath -PathType Container)) {
        Write-LogFile -Name "SetDefaultWallpaper" -Location WindowsTemp -Value "Staging NTFSSecurity module in: $($NTFSSecurityModulePath)"
        Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath "Modules") -Destination $NTFSSecurityModulePath -Recurse -ErrorAction Stop
    }
}
catch [System.Exception] {
    Write-LogFile -Name "SetDefaultWallpaper" -Location WindowsTemp -Value "Unable to stage required PowerShell module: NTFSSecurity" ; break
}

# Import NTFSSecurity module
try {
    Import-Module -Name NTFSSecurity -ErrorAction Stop
}
catch [System.Exception] {
    Write-LogFile -Name "SetDefaultWallpaper" -Location WindowsTemp -Value "Unable to import required PowerShell module: NTFSSecurity" ; break
}

# Scripts variables
$NewOwner = "$($env:COMPUTERNAME)\Administrator"
$SystemContext = "NT AUTHORITY\SYSTEM"
$DefaultWallpaperRootPath = Join-Path -Path $PSScriptRoot -ChildPath "img0.jpg"

# Process C:\Windows\WEB\Wallpaper\Windows\img0.jpg
try {
    # Take ownership
    $DefaultWallpaperImagePath = Join-Path -Path $env:WINDIR -ChildPath "WEB\Wallpaper\Windows\img0.jpg"
    $CurrentOwner = Get-Item -Path $DefaultWallpaperImagePath | Get-NTFSOwner
    if ($CurrentOwner.Owner -notlike $NewOwner) {
        Write-LogFile -Name "SetDefaultWallpaper" -Location WindowsTemp -Value "Setting new owner of '$($NewOwner)' on: $($DefaultWallpaperImagePath)"
        Set-NTFSOwner -Path $DefaultWallpaperImagePath -Account $NewOwner -ErrorAction Stop
    }

    # Grant NT AUTHORITY\SYSTEM and Local Administrator Full Control access
    try {
        Write-LogFile -Name "SetDefaultWallpaper" -Location WindowsTemp -Value "Granting '$($SystemContext)' Full Control on: $($DefaultWallpaperImagePath)"
        Add-NTFSAccess -Path $DefaultWallpaperImagePath -Account $SystemContext -AccessRights FullControl -AccessType Allow -ErrorAction Stop
        Write-LogFile -Name "SetDefaultWallpaper" -Location WindowsTemp -Value "Granting '$($NewOwner)' Full Control on: $($DefaultWallpaperImagePath)"
        Add-NTFSAccess -Path $DefaultWallpaperImagePath -Account $NewOwner -AccessRights FullControl -AccessType Allow -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-LogFile -Name "SetDefaultWallpaper" -Location WindowsTemp -Value "Unable to grant required Full Control permissions on: $($DefaultWallpaperImagePath)" ; break
    }

    # Replace wallpaper
    try {
        Write-LogFile -Name "SetDefaultWallpaper" -Location WindowsTemp -Value "Replacing default wallpaper in: $($DefaultWallpaperImagePath)"
        Remove-Item -Path $DefaultWallpaperImagePath -Force -ErrorAction Stop
        Copy-Item -Path $DefaultWallpaperRootPath -Destination $DefaultWallpaperImagePath -Force -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-LogFile -Name "SetDefaultWallpaper" -Location WindowsTemp -Value "Unable to replace default wallpaper: $($DefaultWallpaperImagePath)" ; break
    }
}
catch [System.Exception] {
    Write-LogFile -Name "SetDefaultWallpaper" -Location WindowsTemp -Value "Unable to take ownership of: $($DefaultWallpaperImagePath)" ; break
}

# Process C:\Windows\WEB\4K\Wallpaper\Windows recursively
$HDWallpaperRoot = Join-Path -Path $PSScriptRoot -ChildPath "4K"
$HDWallpapers = Get-ChildItem -Path $HDWallpaperRoot
if (($HDWallpapers | Measure-Object).Count -ge 1) {
	$LocalHDWallpapersPath = Join-Path -Path $env:WINDIR -ChildPath "WEB\4K\Wallpaper\Windows"
	$LocalHDWallpapers = Get-ChildItem -Path $LocalHDWallpapersPath -Recurse -Filter *.jpg
	foreach ($LocalHDWallpaper in $LocalHDWallpapers) {
		# Take ownership
		$CurrentOwner = Get-Item -Path $LocalHDWallpaper.FullName | Get-NTFSOwner
		if ($CurrentOwner.Owner -notlike $NewOwner) {
			Write-LogFile -Name "SetDefaultWallpaper" -Location WindowsTemp -Value "Setting new owner of '$($NewOwner)' on: $($LocalHDWallpaper.FullName)"
			Set-NTFSOwner -Path $LocalHDWallpaper.FullName -Account $NewOwner -ErrorAction Stop
		}

		# Grant NT AUTHORITY\SYSTEM Full Control access
		try {
			Write-LogFile -Name "SetDefaultWallpaper" -Location WindowsTemp -Value "Granting '$($SystemContext)' Full Control on: $($LocalHDWallpaper.FullName)"
			Add-NTFSAccess -Path $LocalHDWallpaper.FullName -Account $SystemContext -AccessRights FullControl -AccessType Allow -ErrorAction Stop
			Write-LogFile -Name "SetDefaultWallpaper" -Location WindowsTemp -Value "Granting '$($NewOwner)' Full Control on: $($LocalHDWallpaper.FullName)"
			Add-NTFSAccess -Path $LocalHDWallpaper.FullName -Account $NewOwner -AccessRights FullControl -AccessType Allow -ErrorAction Stop
		}
		catch [System.Exception] {
			Write-LogFile -Name "SetDefaultWallpaper" -Location WindowsTemp -Value "Unable to grant required Full Control permissions on: $($LocalHDWallpaper.FullName)" ; break
		}

		# Remove default wallpaper
		try {
			Write-LogFile -Name "SetDefaultWallpaper" -Location WindowsTemp -Value "Removing default wallpaper: $($LocalHDWallpaper.FullName)"
			Remove-Item -Path $LocalHDWallpaper.FullName -Force -ErrorAction Stop
		}
		catch [System.Exception] {
			Write-LogFile -Name "SetDefaultWallpaper" -Location WindowsTemp -Value "Unable to remove default wallpaper: $($LocalHDWallpaper.FullName)" ; break
		}
	}

	# Copy default wallpapers
	foreach ($HDWallpaper in $HDWallpapers) {
		try {
			Write-LogFile -Name "SetDefaultWallpaper" -Location WindowsTemp -Value "Copying '$($HDWallpaper.FullName)' wallpaper to: $($LocalHDWallpapersPath)"
			Copy-Item -Path $HDWallpaper.FullName -Destination $LocalHDWallpapersPath -Force -ErrorAction Stop
		}
		catch [System.Exception] {
			Write-LogFile -Name "SetDefaultWallpaper" -Location WindowsTemp -Value "Unable to copy default wallpaper '$($HDWallpaper.FullName)' to: $($LocalHDWallpapersPath)" ; break
		}
	}
}
else {
	Write-LogFile -Name "SetDefaultWallpaper" -Location WindowsTemp -Value "Unable to locate wallpapers in 4K root folder when processing, skipping the 4K wallpapers"
}