<#
.SYNOPSIS
    Convert a top-level verified domain name from managed to federated, and enable a trust between 
    on-premise Active Directory Federation Services and an Azure Active Directory tenant.

.DESCRIPTION
    This script will setup a trust between your on-premise Active Directory Federation Services and an Azure Active Directory tenant, by converting to from managed to federated. 
    It supports multiple top-level domains by specifying the SupportMultipleDomain parameter.

.PARAMETER Computer
    Specify the internal FQDN of the Primary ADFS server that will be used as context for configuration.

.PARAMETER DomainName
    Specify the top-level verified domain for your Azure Active Directory tenant that will be converted to federated authentication.

.PARAMETER SupportMultipleDomain
    Use this switch if you need support for multiple top-level domains.

.EXAMPLE
    Convert a managed domain name called 'domain.com' to federated authentication and use an on-premise Active Directory Federation Services primary server called 'ADFS01.domain.local' as the configuration context:
    .\Convert-AADDomainToFederated.ps1 -Computer ADFS01.domain.local -DomainName domain.com

    Convert a managed domain name called 'domain.com' to federated authentication with support for additional domains and use an on-premise Active Directory Federation Services primary server called 'ADFS01.domain.local' as the configuration context:
    .\Convert-AADDomainToFederated.ps1 -Computer ADFS01.domain.local -DomainName domain.com -SupportMultipleDomain

.NOTES
    FileName:    Convert-AADDomainToFederated.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    Created:     2015-08-12
    Updated:     2016-08-12
    Version:     1.0.0
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Specify the internal FQDN of the Primary ADFS server that will be used as context for configuration.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$Computer,

    [parameter(Mandatory=$true, HelpMessage="Specify the top-level verified domain for your Azure Active Directory tenant that will be converted to federated authentication.")]
    [ValidateNotNullOrEmpty()]
    [string]$DomainName,

    [parameter(Mandatory=$false, HelpMessage="Use this switch if you need support for multiple top-level domains.")]
    [ValidateNotNullOrEmpty()]
    [switch]$SupportMultipleDomain
)
Begin {
    # Import MSOnline module
    try {
        Import-Module -Name MsOnline -ErrorAction Stop -Verbose:$false
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to load the Azure Active Directory PowerShell module" ; break
    }
}
Process {
    # Get credentials for Microsoft Online Services
    $Credentials = Get-Credential -Message "Enter the username and password for a Global Admin account:" -Verbose:$false

    # Continue processing depending on whether credentials was specified or not
    if ($Credentials -ne $null) {
        # Connect to Microsoft Online Service
        try {
            Write-Verbose -Message "Attempting to connect to Microsoft Online Services"
            Connect-MsolService -Credential $Credentials -ErrorAction Stop -Verbose:$false
        }
        catch [System.Exception] {
            Write-Warning -Message "Unable to connect to Microsoft Online Services, error message was: $($_.Exception.Message)" ; break
        }

        # Create ADFS context (computer parameter should be the internal FQDN of the Primary ADFS server)
        try {
            Write-Verbose -Message "Setting on-premise Active Directory Federation Services computer context"
            if ($PSCmdlet.ShouldProcess($Computer, "Set context")) {
                Set-MsolADFSContext -Computer $Computer -ErrorAction Stop -Verbose:$false
            }
        }
        catch [System.Exception] {
            Write-Warning -Message "An issue occured while configuring ADFS computer context, error message was: $($_.Exception.Message)" ; break
        }

        # Get specified domain in order to validate that specified domain name exists, not already configured for federated authentication and has been verified
        try {
            Write-Verbose -Message "Retrieving domain name from Microsoft Online Services"
            $MsolDomain = Get-MsolDomain -DomainName $DomainName -ErrorAction Stop -Verbose:$false
        }
        catch [System.Exception] {
            Write-Warning -Message "An issue occured while retrieving domain from Microsoft Online Services, error message was: $($_.Exception.Message)" ; break
        }

        # Validate that the domain name has been verified
        if ($MsolDomain.Status -like "Verified") {
            if ($MsolDomain.Authentication -like "Managed") {
                try {
                    # Construct table of parameters for converting domain name to federated from standard
                    $MsolFederatedDomainArgs = @{
                        DomainName = $DomainName
                        ErrorAction = "Stop"
                        Verbose = $false
                    }

                    # Add support for multiple domains to parameter table
                    if ($PSBoundParameters.ContainsKey("SupportMultipleDomain")) {
                        $MsolFederatedDomainArgs.Add("SupportMultipleDomain", $true)
                    }

                    # Convert top-level domain name to federated authentication
                    Write-Verbose -Message "Converting domain name '$($MsolDomain.Name)' to federated authentication"
                    if ($PSCmdlet.ShouldProcess($DomainName, "Convert")) {
                        Convert-MsolDomainToFederated @MsolFederatedDomainArgs
                    }
                }
                catch [System.Exception] {
                    Write-Warning -Message "An issue occured while converting domain name to federated authentication, error message was: $($_.Exception.Message)"
                }

                # Output federation properties to pipeline if param is specified
                if ($PSBoundParameters.ContainsKey("ShowFederationProperties")) {
                    Get-MsolFederationProperty –DomainName $DomainName -Verbose:$false
                }
            }
            else {
                Write-Warning -Message "An issue occured while validating the domain name authentication configuration. Domain name '$($MsolDomain.Name)' is not currently set for Managed authentication" ; break
            }
        }
        else {
            Write-Warning -Message "An issue occured while validating if domain name has been verified. Domain name '$($MsolDomain.Name)' is not currently verified, please complete the verification process before you continue converting the domain name" ; break
        }
    }
    else {
        Write-Warning -Message "Unable construct credentials object, error message was: $($_.Exception.Message)" ; break
    }
}