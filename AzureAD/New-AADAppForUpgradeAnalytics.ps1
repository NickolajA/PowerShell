<#
.SYNOPSIS
    Use this script to create an Azure AD application required for setting up the connection between ConfigMgr and Upgrade Analytics.

.DESCRIPTION
    This script requires the Azure Resource Manager module to be installed. Use 'Install-Module AzureRM' to install it.

.PARAMETER AppDisplayName
    Name of the Azure AD application to be created.

.PARAMETER ResourceGroupName
    Name of a Resource Group in Azure that the OMS workspace used for Upgrade Analytics belongs to.

.PARAMETER AzureSubscriptionId
    Azure subscription Id, can be retrieved by running the Get-AzureRmSubscription cmdlet.

.EXAMPLE
    .\New-AADAppForUpgradeAnalytics.ps1 -AppDisplayName "ConfigMgrUpgradeAnalytics" -ResourceGroupName "UpgradeAnalytics" -AzureSubscriptionId "<insertyourID>"

.NOTES
    FileName:    New-AADAppForUpgradeAnalytics.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    Created:     2016-11-22
    Updated:     2016-11-22
    
    Version history:
    1.0.0 - (2016-11-22) Script created
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Name of the Azure AD application to be created.")]
    [ValidateNotNullOrEmpty()]
    [string]$AppDisplayName,

    [parameter(Mandatory=$true, HelpMessage="Name of a Resource Group in Azure that the OMS workspace used for Upgrade Analytics belongs to.")]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [parameter(Mandatory=$true, HelpMessage="Azure subscription Id, can be retrieved by running the Get-AzureRmSubscription cmdlet.")]
    [ValidateNotNullOrEmpty()]
    [string]$AzureSubscriptionId
)
Begin {
    # Authenticate against an Azure subscription
    try {
        Write-Verbose -Message "Aquiring required credentials for logging on to Azure"
        $AzureLogin = Login-AzureRmAccount -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-Warning -Message $_.Exception.Message ; break
    }
}
Process {
    # Functions
    function New-SecretKey {
        param(
            [parameter(Mandatory=$true)]
            [int]$Length,

            [parameter(Mandatory=$true)]
            [int]$SpecialCharacters
        )
        try {
            # Load required assembly
            Add-Type -AssemblyName "System.Web" -ErrorAction Stop

            # Generate password
            $Password = [Web.Security.Membership]::GeneratePassword($Length, $SpecialCharacters)

            # return password
            return $Password
        }
        catch [System.Exception] {
            Write-Warning -Message $_.Exception.Message ; break
        }
    }

    # Validate Azure context
    try {
        Write-Verbose -Message "Validating Azure context"
        $AzureContext = Get-AzureRmContext -ErrorAction Stop
        if ($AzureContext -ne $null) {
            # Validate Azure subscription Id
            Write-Verbose -Message "Attempting to locate subscription for '$($AzureSubscriptionId)'"
            $AzureSubscription = Get-AzureRmSubscription -SubscriptionId $AzureSubscriptionId -ErrorAction Stop
            if ($AzureSubscription -ne $null) {
                # Validate Resource Group exists
                try {
                    Write-Verbose -Message "Attempting to locate resource group '$($ResourceGroupName)'"
                    $AzureResourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction Stop
                    if ($AzureResourceGroup -ne $null) {
                        # Create new Azure AD Application
                        try {
                            # Generate secret key
                            $AppPassword = New-SecretKey -Length 24 -SpecialCharacters 3

                            Write-Verbose -Message "Creating new Azure AD application '$($AppDisplayName)'"
                            $AADApplicationArgs = @{
                                DisplayName = $AppDisplayName
                                HomePage = "https://localhost:8000"
                                IdentifierUris = "https://localhost:8001"
                                Password = $AppPassword
                                ErrorAction = "Stop"
                            }
                            $AADApplication = New-AzureRmADApplication @AADApplicationArgs
                        }
                        catch [System.Exception] {
                            Write-Warning -Message $_.Exception.Message ; break
                        }

                        # Create a new Service Principal for the application
                        try {
                            Write-Verbose -Message "Creating new service principal for application with Id '$($AADApplication.ApplicationId)'"
                            $AADServicePrincipal = New-AzureRmADServicePrincipal -ApplicationId $AADApplication.ApplicationId -ErrorAction Stop
                        }
                        catch [System.Exception] {
                            Write-Warning -Message $_.Exception.Message ; break
                        }
                        
                        # Create role assignment between application and resource group
                        try {
                            do {
                                # Validate that the service principal got created
                                Write-Verbose -Message "Attempting to locate service principal, retry in 15 seconds"
                                $ServicePrincipal = Get-AzureRmADServicePrincipal -ObjectId $AADServicePrincipal.Id

                                # Sleep for 15 seconds
                                Start-Sleep -Seconds 15
                            }
                            while ($ServicePrincipal -eq $null)

                            Write-Verbose -Message "Creating new role assignment between application Id '$($AADApplication.ApplicationId)' and resource group '$($AzureResourceGroup.ResourceGroupName)'"
                            $AzureRoleAssignmentArgs = @{
                                ResourceGroupName = $AzureResourceGroup.ResourceGroupName
                                ServicePrincipalName = $AADApplication.ApplicationId
                                RoleDefinitionName = "Contributor"
                                ErrorAction = "Stop"
                            }
                            $AzureRoleAssignment = New-AzureRmRoleAssignment @AzureRoleAssignmentArgs
                            Write-Verbose -Message "Successfully created Azure AD application and assigned Contributor role for specified resource group"
                        }
                        catch [System.Exception] {
                            Write-Warning -Message $_.Exception.Message ; break
                        }

                        # Return information required for ConfigMgr connection setup with Upgrade Analytics
                        $TenantName = (Get-AzureRmTenant -TenantId $AzureSubscription.TenantId).Domain
                        $ReturnData = [PSCustomObject]@{
                            Tenant = $TenantName
                            ClientID = $AADApplication.ApplicationId
                            SecretKey = $AppPassword
                        }
                        Write-Output -InputObject $ReturnData
                    }
                }
                catch [System.Exception] {
                    Write-Warning -Message $_.Exception.Message ; break
                }
            }
            else {
                Write-Warning -Message "Unable to locate Azure Subscription based of specified Subscription Id" ; break
            }
        }
    }
    catch [System.Exception] {
        Write-Warning -Message $_.Exception.Message ; break
    }
}