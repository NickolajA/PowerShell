<#
.SYNOPSIS
    Set password never expires policy for an user in Azure AD
.DESCRIPTION
    Use this script for setting the password never expires policy to either true or false in Azure AD
.PARAMETER UserPrincipalName
    Specify the user principal name to amend the password expire policy on
.PARAMETER PasswordNeverExpires
    Specify whether the password expire policy should be true or false
.EXAMPLE
    .\Set-AADUserPasswordExpiresPolicy.ps1 -UserPrincipalName 'user@tenant.onmicrosoft.com' -PasswordNeverExpires $true
.NOTES
    Script name: Set-AADUserPasswordExpiresPolicy.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    Created:     2015-12-23
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Specify the user principal name to amend the password expire policy on")]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern("^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$")]
    [string]$UserPrincipalName,
    [parameter(Mandatory=$true, HelpMessage="Specify whether the password expire policy should be true or false")]
    [ValidateNotNullOrEmpty()]
    [bool]$PasswordNeverExpires
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
    # Validate user principal name exists
    $User = Get-MsolUser -UserPrincipalName $UserPrincipalName -ErrorAction Stop
    if ($User -ne $null) {
        # Set password expires policy for user principal name
        try {
            Set-MsolUser -UserPrincipalName $UserPrincipalName -PasswordNeverExpires $PasswordNeverExpires -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message "Unable to change the password expires policy for user '$($UserPrincipalName)'" ; break
        }
        $UserPasswordNeverExpires = Get-MsolUser -UserPrincipalName $UserPrincipalName -ErrorAction Stop | Select-Object -Property PasswordNeverExpires
        $PSObject = [PSCustomObject]@{
            UserPrincipalName = $UserPrincipalName
            DisplayName = $User.DisplayName
            PasswordNeverExpires = $UserPasswordNeverExpires.PasswordNeverExpires
        }
        Write-Output -InputObject $PSObject
    }
    else {
        Write-Warning -Message "Specified user principal name was not found" ; break
    }
}