<#
.SYNOPSIS
    Amends Membership Query Rules for all collections in Configuration Manager 2012.
.DESCRIPTION
    Use this script if you need to amend parts of the WQL query statement of Membership Query Rules on all collections in Configuration Manager 2012. 
    The script is built to enumerate all collections in SMS_Collections and amend those Rules that are detected as Query Rules only if the the 
    string specified for Match parameter is matched in the QueryExpression property.    
.PARAMETER SiteServer
    Primary Site server name
.PARAMETER Locate
    Value in WQL query statement to locate
.PARAMETER Replace
    Value in WQL query statement to replace the found value with
.PARAMETER UpdateMembership
    When specified a collection membership update cycle will be invoked for the current collection being processed if it's about to be amended
.EXAMPLE
    Update all Collection Membership Query Rules that matches 'CONTOSO' in the WQL query statement with 'FABRIKAM' on a Primary Site server called 'CM01':

    .\Update-CMCollectionQueryRule.ps1 -SiteServer CM01 -Locate "CONTOSO" -Replace "FABRIKAM"
.NOTES
    Script name: Update-CMCollectionQueryRule.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    DateCreated: 2014-10-24
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed")]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 2})]
    [string]$SiteServer,
    [parameter(Mandatory=$true, HelpMessage="Value in WQL query statement to look for")]
    [string]$Locate,
    [parameter(Mandatory=$true, HelpMessage="Value in WQL query statement to replace the matched value with")]
    [string]$Replace,
    [parameter(Mandatory=$false, HelpMessage="When specified a collection membership update cycle will be invoked for the current collection being processed if it's about to be amended")]
    [switch]$UpdateMembership
)
Begin {
    # Get current location
    $CurrentLocation = Get-Location
    # Determine SiteCode from WMI
    try {
        Write-Verbose "Determining SiteCode for Site Server: '$($SiteServer)'"
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
                Write-Debug "SiteCode: $($SiteCode)"
            }
        }
    }
    catch [Exception] {
        Throw "Unable to determine SiteCode"
    }
}
Process {
    Write-Verbose -Message "Enumerating all Collections"
    $Collections = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer
    foreach ($Collection in $Collections) {
        Write-Verbose -Message "Processing Collection: '$($Collection.Name)'"
        # Get instance and it's lazy properties
        $Collection.Get()
        foreach ($Rule in $Collection.CollectionRules) {
            if ($Rule.__CLASS -like "SMS_CollectionRuleQuery") {
                if ($Rule.QueryExpression -match $Locate) {
                    Write-Verbose -Message "Rule '$($Rule.RuleName)' has been validated as a matched QueryRule"
                    $NewQueryExpression = $Rule.QueryExpression -replace "$($Locate)","$($Replace)"
                    $NewRuleName = $Rule.RuleName
                    Write-Verbose -Message "Stored the values from rule '$($Rule.RuleName)' in memory"
                    # Delete the matched QueryRule by calling the DeleteMembershipRule method
                    if ($PSCmdlet.ShouldProcess("RuleName: '$($Rule.RuleName)'","DeleteMembershipRule")) {
                        $RemoveRule = $Collection.DeleteMembershipRule($Rule)
                    }
                    if ($RemoveRule.ReturnValue -eq 0) {
                        Write-Verbose -Message "Rule '$($Rule.RuleName)' was successfully removed"
                    }
                    else {
                        Throw "Unable to remove current rule '$($Rule.RuleName)'"
                    }
                    # Create a new QueryRule by creating a new instance in the SMS_CollectionRuleQuery class with amended properties from the deleted QueryRule
                    Write-Verbose -Message "Stored QueryRule expression: `n$($Rule.QueryExpression)"
                    try {
                        if ($PSCmdlet.ShouldProcess("RuleName: '$($NewRuleName)'","CreateMembershipRule")) {
                            $NewRule = ([WmiClass]"\\$($SiteServer)\root\SMS\site_$($SiteCode):SMS_CollectionRuleQuery").CreateInstance()
                            $NewRule.QueryExpression = $NewQueryExpression
                            $NewRule.RuleName = $NewRuleName
                            $Collection.CollectionRules = $NewRule
                            $Collection.Put() | Out-Null
                            if (($Collection.CollectionRules | Where-Object { ($_.RuleName -like "$($NewRuleName)") -and ($_.__CLASS -like "SMS_CollectionRuleQuery") } | Measure-Object).Count -eq 1) {
                                Write-Verbose -Message "Amended QueryRule expression: `n$($NewQueryExpression)"
                                Write-Verbose -Message "Successfully created a new QueryRule named '$($NewRuleName)' on collection '$($Collection.Name)'"
                                # Update Collection Membership if UpdateMembership parameter is specified
                                if ($PSBoundParameters["UpdateMembership"]) {
                                    $InvokeMethod = $Collection.RequestRefresh()
                                    if ($InvokeMethod.ReturnValue -eq 0) {
                                        Write-Verbose -Message "Invoking Collection Membership Update method for Collection: $($Collection.Name)"
                                    }
                                    else {
                                        Write-Warning -Message "Failed to invoke Collection Membership Update method for Collection: $($Collection.Name)"
                                    }
                                }
                            }
                        }
                    }
                    catch {
                        Throw "Failed to create a new QueryRule instance"
                    }
                }
            }
        }
    }
}