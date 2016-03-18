<#
.SYNOPSIS
    Create service accounts as 'Global Admin' in an Azure AD tenant

.DESCRIPTION
    This script will create a new service account as 'Global Admin' in an Azure AD tenant

.PARAMETER UserPrincipalName
    Define user principal name for the service account. As a best practice, always use your tenant suffix and not a verified domain.

.PARAMETER DisplayName
    Define display name for the service account. FirstName and LastName parameters are built from the DisplayName by splitting on the space character.
    If you include multiple spaces in the DisplayName parameter, e.g. 'Service Account Name', FirstName will be 'Service' and LastName will be 'Account'.

.PARAMETER Password
    Define password for the service account.

.EXAMPLE
    Create a new service account called 'svc-ndes@tenant.onmicrosoft.com' as 'Global Admin' in an Azure AD tenant:
    .\New-AADServiceAccount.ps1 -UserPrincipalName "svc-ndes@tenant.onmicrosoft.com" -DisplayName "NDES ServiceAccount" -Password "P@ssw0rd1!"

.NOTES
    FileName:    New-AADServiceAccount.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    Created:     2016-03-18
    Updated:     N/A
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(
        Mandatory = $true, 
        HelpMessage = "Define user principal name for the service account. As a best practice, always use your tenant suffix and not a verified domain."
    )]
    [ValidateNotNullOrEmpty()]
    [string]$UserPrincipalName,

    [parameter(
        Mandatory = $true, 
        HelpMessage = "Define display name for the service account."
    )]
    [ValidateNotNullOrEmpty()]
    [string]$DisplayName,

    [parameter(
        Mandatory = $true, 
        HelpMessage = "Define a password for the service account."
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(8,16)]
    [string]$Password
)
Begin {
    # Load Microsoft Online Services module
    try {
        Import-Module -Name MSOnline -ErrorAction Stop -Verbose:$false
    }
    catch [System.Exception] {
        Write-Warning -Message $_.Exception.Message ; break
    }

    # Credentials for Microsoft Online Service
    if (($Credentials = Get-Credential -Message "Enter the username and password for a Microsoft Online Service") -eq $null) {
        Write-Warning -Message "Please specify a Global Administrator account and password" ; break
    }

    # Connect to Microsoft Online Service
    try {
        Connect-MsolService -Credential $Credentials -ErrorAction Stop -Verbose:$false
    }
    catch [System.Exception] {
        Write-Warning -Message $_.Exception.Message ; break
    }
}
Process {
    if ($PSBoundParameters["ShowProgress"]) {
        $UserCount = 0
    }

    # Process for each UserPrincipalName specified in parameter
    foreach ($CurrentUserPrincipalName in $UserPrincipalName) {
        try {
            $ValidateMsolUser = Get-MsolUser -UserPrincipalName $CurrentUserPrincipalName -ErrorAction SilentlyContinue
            if ($ValidateMsolUser -eq $null) {
                # Create Service Account
                $ServiceAccountArguments = @{
                    UserPrincipalName = $UserPrincipalName
                    DisplayName = $DisplayName
                    FirstName = $DisplayName.Split(" ")[0]
                    LastName = $DisplayName.Split(" ")[1]
                    Password = $Password
                    ForceChangePassword = $false
                    PasswordNeverExpires = $true
                    Verbose = $false
                    ErrorAction = "Stop"
                }
                New-MsolUser @ServiceAccountArguments | Out-Null
                Write-Verbose -Message "Successfully created service account '$($UserPrincipalName)'"

                # Add Service Account to Global Admin group
                $RoleMemberArguments = @{
                    RoleName = "Company Administrator"
                    RoleMemberEmailAddress = $UserPrincipalName
                    Verbose = $false
                    ErrorAction = "Stop"
                }
                Add-MsolRoleMember @RoleMemberArguments | Out-Null
                Write-Verbose -Message "Successfully added service account '$($UserPrincipalName)' as a member of 'Global Administrator'"
            }
            else {
                Write-Warning -Message "Specified UserPrincipalName already exists."
            }
        }
        catch [System.Exception] {
            Write-Warning -Message $_.Exception.Message ; break
        }
    }
}