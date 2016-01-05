[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Specify the Primary Site server")]
    [ValidateNotNullOrEmpty()]
    [string]$SiteServer
)
Begin {
    # Assemblies
    try {
        Add-Type -AssemblyName "System.Drawing" -ErrorAction Stop
        Add-Type -AssemblyName "System.Windows.Forms" -ErrorAction Stop
    }
    catch [System.UnauthorizedAccessException] {
	    Write-Warning -Message "Access denied when attempting to load required assemblies" ; break
    }
    catch [System.Exception] {
	    Write-Warning -Message "Unable to load required assemblies. Error message: $($_.Exception.Message). Line: $($_.InvocationInfo.ScriptLineNumber)" ; break
    }
}
Process {
    function Load-Form {
	    $Form.Add_Shown({$Form.Activate()})
	    $Form.ShowDialog() | Out-Null
    }

    # Forms
    $Form = New-Object System.Windows.Forms.Form    
    $Form.Size = New-Object System.Drawing.Size(350,100)  
    $Form.MinimumSize = New-Object System.Drawing.Size(350,100)
    $Form.MaximumSize = New-Object System.Drawing.Size(350,100)
    $Form.SizeGripStyle = "Hide"
    $Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHome + "\powershell.exe")
    $Form.Text = "Header"
    $Form.ControlBox = $true
    $Form.TopMost = $true

    # Load Form
    Load-Form
}