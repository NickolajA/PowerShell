<#
.SYNOPSIS
    Setup a trust between on-premise ADFS and Azure Active Directory
.DESCRIPTION
    This script will setup a trust between your on-premise Active Directory Federation Services and Azure Active Directory. It supports multiple top-level domains by specifying the SupportMultipleDomain parameter.
.PARAMETER Computer
    Specify the internal FQDN of the Primary ADFS server
.PARAMETER DomainName
    Specify the top-level domain that will be configured for federated authentication
.PARAMETER Method
    For a new domain use 'NewDomain' and if you've an existing domain use 'ConvertDomain'
.PARAMETER SupportMultipleDomain
    If you need support for multiple top-level domains, specify this switch
.PARAMETER ShowFederationProperties
    When using the ConvertDomain method, you can choose to show the Federation Properties once the conversion is complete
.EXAMPLE
    .\Set-AADFederationTrustForDomain.ps1 -Computer ADFS01.domain.local -DomainName domain.com -Method ConvertDomain -ShowFederationProperties
    Setup a trust between on-premise Primary ADFS server called 'ADFS01.domain.local' with Azure Active Directory for a domain called 'domain.com' where the domain will be converted to federation authentication:
.NOTES
    Script name: Set-AADFederationTrustForDomain.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    DateCreated: 2015-04-15
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Specify the internal FQDN of the Primary ADFS server")]
    [ValidateNotNullOrEmpty()]
    [string]$Computer,
    [parameter(Mandatory=$true, HelpMessage="Specify the top-level domain that will be configured for federated authentication")]
    [ValidateNotNullOrEmpty()]
    [string]$DomainName,
    [parameter(Mandatory=$true, HelpMessage="For a new domain use 'NewDomain' and if you've an existing domain use 'ConvertDomain'")]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("NewDomain","ConvertDomain")]
    [string]$Method,
    [parameter(Mandatory=$false, HelpMessage="If you need support for multiple top-level domains, specify this switch")]
    [ValidateNotNullOrEmpty()]
    [switch]$SupportMultipleDomain,
    [parameter(Mandatory=$false, HelpMessage="When using the ConvertDomain method, you can choose to show the Federation Properties once the conversion is complete")]
    [ValidateNotNullOrEmpty()]
    [switch]$ShowFederationProperties
)
Begin {
    # Import MSOnline module
    try {
        Import-Module MsOnline -ErrorAction Stop -Verbose:$false
    }
    catch [Exception] {
        Write-Warning -Message "Unable to load the Azure Active Directory PowerShell module" ; break
    }
}
Process {
    # Credentials for Microsoft Online Service
    $Credentials = Get-Credential -Message "Enter the username and password for the Microsoft Online Service"

    # Connect to Microsoft Online Service
    Connect-MsolService -Credential $Credentials

    # Create ADFS context (computer should be the internal FQDN of the Primary ADFS server)
    Set-MsolADFSContext -Computer $Computer

    switch ($Method) {
        "NewDomain" {
            try {
                # Add a new top-level domain for federated authentication
                $MsolFederatedDomainArgs = @{
                    DomainName = $DomainName
                    ErrorAction = Stop
                }
                if ($PSBoundParameters["SupportMultipleDomain"]) {
                    $MsolFederatedDomainArgs.Add("SupportMultipleDomain", $true)
                }
                New-MsolFederatedDomain @MsolFederatedDomainArgs
                Write-Output "Once you've created the DNS record and verified it's been propagated, re-run the script again with the same parameters"
            }
            catch [Exception] {
                Write-Warning -Message $_.Exception.Message
            }
        }
        "ConvertDomain" {
            try {
                # Convert top-level domain for federated authentication
                $MsolFederatedDomainArgs = @{
                    DomainName = $DomainName
                    ErrorAction = Stop
                }
                if ($PSBoundParameters["SupportMultipleDomain"]) {
                    $MsolFederatedDomainArgs.Add("SupportMultipleDomain", $true)
                }
                Convert-MsolDomainToFederated @MsolFederatedDomainArgs
                if ($PSBoundParameters["ShowFederationProperties"]) {
                    # Check Domain Federation properties
                    Get-MsolFederationProperty –DomainName $DomainName
                }
            }
            catch [Exception] {
                Write-Warning -Message $_.Exception.Message
            }
        }
    }
}