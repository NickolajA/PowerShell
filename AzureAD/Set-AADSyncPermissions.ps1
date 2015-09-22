<#
.SYNOPSIS
    Delegate required permissions for an AADSync service account or group when using Password Synchronization or Password Write-Back
.DESCRIPTION
    This script will delegate required permissions for an AADSync service account or group when using Password Synchronization or Password Write-Back
.PARAMETER IdentityName
    Specify the Display Name of a service account or group
.PARAMETER Inheritance
    Choose (All) for inheritance for this object and all descendents, or (Descendents) for all descendents only
.PARAMETER ObjectType
    By specifying an ObjectType, the permissions will only apply for the specified ObjectType, e.g. users
.EXAMPLE
    .\Set-AADSyncPermissions.ps1 -IdentityName "AADSync Service Account" -Inheritance All
     Delegate the required permissions for an AADSync service account with All inheritance:
.NOTES
    Script name: Set-AADSyncPermissions.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    DateCreated: 2015-03-23
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, ParameterSetName="AllObjectTypes", HelpMessage="Specify the features to delegate permissions for")]
    [parameter(Mandatory=$true, ParameterSetName="SpecificObjectTypes")]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("PasswordWriteBack","PasswordSynchronization","ExchangeHybrid")]
    [string[]]$Feature,
    [parameter(Mandatory=$true, ParameterSetName="AllObjectTypes", HelpMessage="Specify the Display Name of a service account or group")]
    [parameter(Mandatory=$true, ParameterSetName="SpecificObjectTypes")]
    [ValidateNotNullOrEmpty()]
    [string]$IdentityName,
    [parameter(Mandatory=$true, ParameterSetName="AllObjectTypes", HelpMessage="Choose (All) for inheritance for this object and all descendents, or (Descendents) for all descendents only")]
    [parameter(Mandatory=$true, ParameterSetName="SpecificObjectTypes")]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("All","Descendents")]
    [string]$Inheritance,
    [parameter(Mandatory=$true, ParameterSetName="SpecificObjectTypes", HelpMessage="By specifying an ObjectType, the permissions will only apply for the specified ObjectType, e.g. users")]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("user")]
    [string]$ObjectType

)
Begin {
    # Get current location
    $CurrentLocation = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    # Determine if we need to load the Active Directory PowerShell module
    if ($Host.Version -le "2.0") {
        try {
            Import-Module ActiveDirectory -ErrorAction Stop -Verbose:$false
        }
        catch [Exception] {
            Write-Warning -Message "Unable to load the Active Directory PowerShell module" ; break
        }
    }
    # Define RootDSE and Domain objects
    $RootDSE = Get-ADRootDSE -Verbose:$false
    $Domain = Get-ADDomain -Verbose:$false
    # Create a hashtables for GUID mapping and extended rights
    $GUIDMapping = New-Object -TypeName System.Collections.Hashtable
    $ExtendedRightsMapping = New-Object -TypeName System.Collections.Hashtable
    if (($PSBoundParameters["ObjectType"]) -or ($Feature -eq "ExchangeHybrid")) {
        # Add schema class and attribute GUIDs to the mapping hashtable
        $GUIDMappingObjects = Get-ADObject -SearchBase $RootDSE.schemaNamingContext -LDAPFilter "(schemaIDGUID=*)" -Properties ldapDisplayName, schemaIDGUID -Verbose:$false
        foreach ($GUIDMappingObject in $GUIDMappingObjects) {
            $GUIDMapping.Add(($GUIDMappingObject.ldapDisplayName), [System.GUID]$GUIDMappingObject.schemaIDGUID)
        }
    }
    # Add extended rights GUIDs to the mapping hashtable
    $ExtendedRightsObjects = Get-ADObject -SearchBase $RootDSE.configurationNamingContext -LDAPFilter "(&(objectClass=controlAccessRight)(rightsGUID=*))" -Properties displayName, rightsGUID -Verbose:$false
    foreach ($ExtendedRightsObject in $ExtendedRightsObjects) {
        $ExtendedRightsMapping.Add($ExtendedRightsObject.displayName, [System.GUID]$ExtendedRightsObject.rightsGUID)
    }
    # Change location to the Active Directory provider
    Set-Location -Path AD: -Verbose:$false
}
Process {
    function Set-ACLPermission {
        param(
            [parameter(Mandatory=$true, ParameterSetName="AccessRule")]
            [parameter(Mandatory=$true, ParameterSetName="ExtendedRights")]
            [ValidateSet("ExtendedRights","AccessRule")]
            [string]$Option,
            [parameter(Mandatory=$true, ParameterSetName="ExtendedRights")]
            [string[]]$ExtendedRights,
            [parameter(Mandatory=$true, ParameterSetName="AccessRule")]
            [string[]]$AccessRules
        )
        if ($Option -eq "ExtendedRights") {
            # Create ExtendedRights ArrayList
            $ExtendedRightsList = New-Object -TypeName System.Collections.ArrayList
            $ExtendedRightsList.AddRange(@($ExtendedRights)) | Out-Null
            foreach ($ExtendedRight in $ExtendedRightsList) {
                if ($Script:PSBoundParameters["ObjectType"]) {
                    # Construct ExtendedRightsAccessRule object
                    $ExtendedRightObject = New-Object -TypeName System.DirectoryServices.ExtendedRightAccessRule -ArgumentList ($SecurityIdentifier, "Allow", $ExtendedRightsMapping["$($ExtendedRight)"], "$($Inheritance)", $GUIDMapping["$($ObjectType)"])
                    Write-Verbose -Message "Constructed ExtendedRightAccessRule object for ObjectType '$($ObjectType)' and '$($ExtendedRight)' extended right"
                }
                else {
                    # Construct ExtendedRightsAccessRule object
                    $ExtendedRightObject = New-Object -TypeName System.DirectoryServices.ExtendedRightAccessRule -ArgumentList ($SecurityIdentifier, "Allow", $ExtendedRightsMapping["$($ExtendedRight)"], "$($Inheritance)")
                    Write-Verbose -Message "Constructed ExtendedRightAccessRule object for '$($ExtendedRight)' extended right"
                }
                # Add the ExtendedRightsAccessRule to the DACL
                $DACL.AddAccessRule($ExtendedRightObject)
            }
        }
        if ($Option -eq "AccessRule") {
            # Create AccessRule ArrayList
            $AccessRuleList = New-Object -TypeName System.Collections.ArrayList
            $AccessRuleList.AddRange(@($AccessRules)) | Out-Null
            # Construct ActiveDirectoryAccessRule object for minimum permissions for Object Type contact
            $AccessRuleObject = New-Object -TypeName System.DirectoryServices.ActiveDirectoryAccessRule -ArgumentList ($SecurityIdentifier, "ReadProperty,WriteProperty", "Allow", $GUIDMapping["proxyAddresses"], "Descendents", $GUIDMapping["contact"])
            Write-Verbose -Message "Constructed ActiveDirectoryAccessRule object with 'ReadProperty' and 'WriteProperty' for Object Type 'contact'"
            # Add the ActiveDirectoryAccessRule to the DACL
            $DACL.AddAccessRule($AccessRuleObject)
            # Construct ActiveDirectoryAccessRule object for minimum permissions for Object Type group
            $AccessRuleObject = New-Object -TypeName System.DirectoryServices.ActiveDirectoryAccessRule -ArgumentList ($SecurityIdentifier, "ReadProperty,WriteProperty", "Allow", $GUIDMapping["proxyAddresses"], "Descendents", $GUIDMapping["group"])
            Write-Verbose -Message "Constructed ActiveDirectoryAccessRule object with 'ReadProperty' and 'WriteProperty' for Object Type 'group'"
            # Add the ActiveDirectoryAccessRule to the DACL
            $DACL.AddAccessRule($AccessRuleObject)
            # Construct ActiveDirectoryAccessRule object for minimum permissions for Object Type user
            foreach ($AccessRule in $AccessRuleList) {
                $AccessRuleObject = New-Object -TypeName System.DirectoryServices.ActiveDirectoryAccessRule -ArgumentList ($SecurityIdentifier, "ReadProperty,WriteProperty", "Allow", $GUIDMapping["$($AccessRule)"], "Descendents", $GUIDMapping["user"])
                Write-Verbose -Message "Constructed ActiveDirectoryAccessRule object with 'ReadProperty' and 'WriteProperty' for attribute '$($AccessRule)' for Object Type 'users'"
                # Add the ActiveDirectoryAccessRule to the DACL
                $DACL.AddAccessRule($AccessRuleObject)
            }
        }
        # Apply the DACL
        if ($Script:PSCmdlet.ShouldProcess($Domain.DistinguishedName, "Set ACL permissions")) {
            try {
                Set-Acl -AclObject $DACL -Path (Join-Path -Path "AD:\" -ChildPath $Domain.DistinguishedName) -ErrorAction Stop -Verbose:$false
                Write-Verbose -Message "Successfully updated ACL for '$($Domain.DistinguishedName)'"
            }
            catch [Exception] {
                Write-Warning -Message "Unable to update ACL for identity '$($IdentityName)'"
                Set-Location -Path $CurrentLocation ; break
            }
        }
    }

    # Get the identity reference SID to delegate permissions to
    try {
        $IdentitySID = Get-ADObject -Filter "Name -like '$($IdentityName)'" -Properties objectSID -Verbose:$false | Select-Object -ExpandProperty objectSID
        if (($IdentitySID | Measure-Object).Count -eq 0) {
            Write-Warning -Message "Query for identity '$($IdentityName)' did not return any objects"
            Set-Location -Path $CurrentLocation ; break
        }
        elseif (($IdentitySID | Measure-Object).Count -eq 1) {
            Write-Verbose -Message "Validated specified identity '$($IdentityName)' with SID '$($IdentitySID)'"
        }
        else {
            Write-Warning -Message "Query for identity '$($IdentityName)' returned more than one object, please refine your identity"
            Set-Location -Path $CurrentLocation ; break
        }
    }
    catch [Exception] {
        Write-Warning -Message "Unable to determine Active Directory identity reference object from specified argument '$($IdentityName)'" ; break
    }
    # Get SID value of the specified Active Directory group
    $SecurityIdentifier = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList $IdentitySID
    # Get DACL on specified Organizational Unit
    try {
        $DACL = Get-Acl -Path ($Domain.DistinguishedName) -ErrorAction Stop -Verbose:$false
    }
    catch [Exception] {
        Write-Warning -Message "Unable to determine DACL for domain"
        Set-Location -Path $CurrentLocation ; break
    }
    # Enumerate through each feature
    foreach ($CurrentFeature in $Feature) {
        if ($CurrentFeature -eq "PasswordSynchronization") {
            # Allow for Replicating Directory Changes permissions
            Set-ACLPermission -Option ExtendedRights -ExtendedRights "Replicating Directory Changes", "Replicating Directory Changes All"
        }
        if ($CurrentFeature -eq "PasswordWriteBack") {
            # Allow for Reset and Change Password permissions
            Set-ACLPermission -Option ExtendedRights -ExtendedRights "Reset Password", "Change Password"
        }
        if ($CurrentFeature -eq "ExchangeHybrid") {
            # Allow minimum permission for Exchange Hybrid Deployment
            Set-ACLPermission -Option AccessRule -AccessRules "msExchArchiveStatus", "msExchBlockedSendersHash", "msExchSafeRecipientsHash", "msExchSafeSendersHash", "msExchUCVoiceMailSettings", "msExchUserHoldPolicies", "proxyAddresses"
        }
    }
}
End {
    # Return to previously location
    Set-Location -Path $CurrentLocation -Verbose:$false
}