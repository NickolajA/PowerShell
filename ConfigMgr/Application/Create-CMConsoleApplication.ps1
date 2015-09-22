# Import ConfigMgr PowerShell module
Import-Module -Name ConfigurationManager

# Set PSDrive
Set-Location -Path P01:

# Define Application properties
$ApplicationName = "ConfigMgr 2012 R2 SP1 CU1 Console"
$ApplicationDescription = "Created with PowerShell"
$ApplicationSoftwareVersion = "5.0.8239.1206"
$ApplicationPublisher = "Microsoft"
$ApplicationPath = "\\CM01\Source$\Apps\CM2012R2SP1Console\AdminConsole.msi"
$DPGroupName = "All DPs"

# Create Applicaton
$ApplicationArguments = @{
    Name = $ApplicationName
    Description = $ApplicationDescription
    Publisher = $ApplicationPublisher
    SoftwareVersion = $ApplicationSoftwareVersion
    ReleaseDate = (Get-Date)
    LocalizedApplicationName = $ApplicationName
}
New-CMApplication @ApplicationArguments

# Create DeploymentType
$DeploymentTypeArguments = @{
    ApplicationName = $ApplicationName
    DeploymentTypeName = $ApplicationName
    InstallationFileLocation = $ApplicationPath
    ForceforUnknownPublisher = $true
    MsiInstaller = $true
    InstallationBehaviorType = "InstallForSystem"
    InstallationProgram = "cscript.exe InstallConfigMgrConsole.vbs"
    OnSlowNetworkMode = "DoNothing"
}
Add-CMDeploymentType @DeploymentTypeArguments

# Distribute content to DPG
$ContentDistributionArguments = @{
    ApplicationName = $ApplicationName
    DistributionPointGroupName = $DPGroupName
}
Start-CMContentDistribution @ContentDistributionArguments