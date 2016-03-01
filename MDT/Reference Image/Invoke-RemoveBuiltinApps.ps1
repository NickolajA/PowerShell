# Get a list of all apps
$AppArrayList = Get-AppxPackage -PackageTypeFilter Bundle | Select-Object -Property Name, PackageFullName | Sort-Object -Property Name

# Loop through the list of apps
foreach ($App in $AppArrayList) {
    # Exclude essential Windows apps
    if (($App.Name -in "Microsoft.WindowsCalculator","Microsoft.WindowsStore","Microsoft.Appconnector","Microsoft.WindowsCommunicationsApps","Microsoft.WindowsSoundRecorder")) {
        Write-Output -InputObject "Skipping essential Windows app: $($App.Name)"
    }
    # Remove AppxPackage and AppxProvisioningPackage
    else {
        # Gather package names
        $AppPackageFullName = Get-AppxPackage -Name $App.Name | Select-Object -ExpandProperty PackageFullName
        $AppProvisioningPackageName = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $App.Name } | Select-Object -ExpandProperty PackageName
        # Attempt to remove AppxPackage
        try {
            Write-Output -InputObject "Removing AppxPackage: $AppPackageFullName"
            Remove-AppxPackage -Package $AppPackageFullName -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message $_.Exception.Message
        }
        # Attempt to remove AppxProvisioningPackage
        try {
            Write-Output -InputObject "Removing AppxProvisioningPackage: $AppProvisioningPackageName"
            Remove-AppxProvisionedPackage -PackageName $AppProvisioningPackageName -Online -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message $_.Exception.Message
        }
    }
}