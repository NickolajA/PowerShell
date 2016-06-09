<#
.SYNOPSIS
    Dynamically determine a list of Applications that should be installed during a Task Sequence in ConfigMgr.

.DESCRIPTION
    This script will dynamically determine what Applications that should be installed during a Task Sequence in ConfigMgr, based upon a RuleVariableName variable list
    defined in e.g. CustomSettings.ini or with Task Sequences Variables. All variables that match what's specified for the RuleVariableName parameter will be
    reconstructed as a new base variable list with the name specified in the BaseVariableName parameter. This script is capable of renumbering the new base variable list
    if the rule variable is not sequenced properly, e.g. 001, 002, 004, 012.

    The script have been created so that it works natively in ConfigMgr without any required parameter input, but you have the option to define the variable names
    that should be used.

    Example of rule variables in a CustomSettings.ini:

    [Default]
    APPLICATIONS001=Application 01
    APPLICATIONS002=Application 02
    APPLICATIONS004=Application 04

    Will be reconstructed into base variables likes below:
    COALESCEDAPPS01=Application 01
    COALESCEDAPPS02=Application 02
    COALESCEDAPPS03=Application 04

.PARAMETER RuleVariableName
    Specify the name of the variable used in CustomSettings.ini for dynamic Application installations. Default is 'APPLICATIONS'.

.PARAMETER BaseVariableName
    Specify the name of the base variable referenced in the Install Applications Task Sequence step. Default is 'COALESCEDAPPS'.

.PARAMETER Length
    Specify the suffix number length of the rule variable from e.g. CustomSettings.ini. Value of 3 should be used when the suffix is e.g. 001. Default is '3'.

.EXAMPLE
    Execute with native ConfigMgr functionality:
    .\Set-DynamicApplicationsList.ps1

    Define a custom rule variable 'APPS' specified e.g. CustomSettings.ini:
    .\Set-DynamicApplicationsList.ps1 -RuleVariable APPS

    Define a custom rule variable 'APPS' specified e.g. CustomSettings.ini with a custom base variable 'APP' defined in the Install Application task sequence step:
    .\Set-DynamicApplicationsList.ps1 -RuleVariable APPS -BaseVariableName APP

.NOTES
    FileName:    Set-DynamicApplicationsList.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    Created:     2016-06-06
    Updated:     2016-06-06
    Version:     1.0.0
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$false, HelpMessage="Specify the name of the variable used in CustomSettings.ini for dynamic Application installations. Default is 'APPLICATIONS'.")]
    [ValidateNotNullOrEmpty()]
    [string]$RuleVariableName = "APPLICATIONS",

    [parameter(Mandatory=$false, HelpMessage="Specify the name of the base variable referenced in the Install Applications Task Sequence step. Default is 'COALESCEDAPPS'.")]
    [ValidateNotNullOrEmpty()]
    [string]$BaseVariableName = "COALESCEDAPPS",

    [parameter(Mandatory=$false, HelpMessage="Specify the suffix number length of the rule variable from e.g. CustomSettings.ini. Value of 3 should be used when the suffix is e.g. 001. Default is '3'.")]
    [ValidateNotNullOrEmpty()]
    [string]$Length = 3
)
Begin {
    # Construct TSEnvironment object
    try {
        $TSEnvironment = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to construct Microsoft.SMS.TSEnvironment object" ; exit 1
    }

    # Read current TSEnvironment variables
    $TSEnvironmentVariables = $TSEnvironment.GetVariables()
}
Process {
    # Functions
    function Write-CMLogEntry {
	    param(
		    [parameter(Mandatory=$true, HelpMessage="Value added to the smsts.log file")]
		    [ValidateNotNullOrEmpty()]
		    [string]$Value,

		    [parameter(Mandatory=$true, HelpMessage="Severity for the log entry. 1 for Informational, 2 for Warning and 3 for Error.")]
		    [ValidateNotNullOrEmpty()]
            [ValidateSet("1", "2", "3")]
		    [string]$Severity
	    )
	    # Determine log file location
        $LogFilePath = Join-Path -Path $Script:TSEnvironment.Value("_SMSTSLogPath") -ChildPath "DynamicApplicationsList.log"

        # Construct time stamp for log entry
        $Time = -join @((Get-Date -Format "HH:mm:ss.fff"), "+", (Get-WmiObject -Class Win32_TimeZone | Select-Object -ExpandProperty Bias))

        # Construct date for log entry
        $Date = (Get-Date -Format "MM-dd-yyyy")

        # Construct context for log entry
        $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

        # Construct final log entry
        $LogText = "<![LOG[$($Value)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""DynamicApplicationsList"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
	
	    # Add value to log file
        try {
	        Add-Content -Value $LogText -LiteralPath $LogFilePath -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message "Unable to append log entry to smsts.log file"
        }
    }

    # Write start of processing to log file
    Write-CMLogEntry -Value "Start reconstruction of TSEnvironment variables matching '$($RuleVariableName)' rule variable name" -Severity 1

    # Construct ArrayList for matched variables
    $RuleVariableList = New-Object -TypeName System.Collections.ArrayList

    # Determine TSEnvironment variables that matches input from RuleVariableName parameter
    if ($TSEnvironmentVariables -ne $null) {
        foreach ($TSEnvironmentVariable in $TSEnvironmentVariables) {
            if ($TSEnvironmentVariable.SubString(0, $TSEnvironmentVariable.Length - $Length) -like $RuleVariableName) {
                Write-CMLogEntry -Value "Matched '$($TSEnvironmentVariable)' TSEnvironment variable, adding to BaseVariable array list for reconstruction" -Severity 1
                $RuleVariableList.Add(@{$TSEnvironmentVariable = $TSEnvironment.Value($TSEnvironmentVariable)}) | Out-Null
            }
        }
    }
    else {
        Write-CMLogEntry -Value "Unable to retrieve TSEnvironment variables" -Severity 3 ; exit 1
    }

    # Counter used for reconstructing base variables numbering
    $BaseCount = 1
    
    # Process variables determined to be reconstructed
    if ($RuleVariableList.Count -ge 1) {
        # Construct ArrayList for base variables
        $BaseVariableList = New-Object -TypeName System.Collections.ArrayList

        # Enumerate each hash-table object and add modified value to ArrayList
        foreach ($BaseVariable in $RuleVariableList) {
            # Contruct new BaseVariable with value from original variable
            $NewBaseVariableName = -join @($BaseVariableName, ("{0:00}" -f $BaseCount))
            Write-CMLogEntry -Value "Constructed new base variable '$($NewBaseVariableName)'" -Severity 1
            $BaseVariableList.Add(@{$NewBaseVariableName = $TSEnvironment.Value($BaseVariable.Keys)}) | Out-Null

            # Increment variable count
            $BaseCount++
        }
    }
    else {
        Write-CMLogEntry -Value "No matches found for specified RuleVariableName" -Severity 3 ; exit 1
    }

    # Define reconstructed base variables in the TSEnvironment
    if ($BaseVariableList.Count -ge 1) {
        foreach ($BaseVariable in $BaseVariableList) {
            # Set new TSEnvironment variables
            Write-CMLogEntry -Value "Setting TSEnvironment base variable '$($BaseVariable.Keys)' with value '$($BaseVariable.Values)'" -Severity 1
            $TSEnvironment.Value("$($BaseVariable.Keys)") = "$($BaseVariable.Values)"
        }
    }
    else {
        Write-CMLogEntry -Value "Unable to determine reconstructed base variables" -Severity 3 ; exit 1
    }
}