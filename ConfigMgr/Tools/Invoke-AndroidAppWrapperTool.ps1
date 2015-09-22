Begin {
    try {
        # Load Assemblies
        Add-Type -AssemblyName "System.Drawing" -ErrorAction Stop
        Add-Type -AssemblyName "System.Windows.Forms" -ErrorAction Stop

        # Import Intune App Wrapping Tool PowerShell module
        $ModulePath = Join-Path -Path "$($env:SystemDrive)\Program Files (x86)\Microsoft Intune Mobile Application Management\Android\App Wrapping Tool\" -ChildPath "IntuneAppWrappingTool.psm1"
        #Import-Module -Name $ModulePath -ErrorAction Stop
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        Write-Warning -Message $_.Exception.Message ; break
    }
}
Process {
    function Load-Form {
        $Form.Controls.AddRange(@(
            
        ))
	    $Form.Add_Shown({$Form.Activate()})
	    [void]$Form.ShowDialog()
    }

    # Forms
    $Form = New-Object -TypeName System.Windows.Forms.Form    
    $Form.Size = New-Object -TypeName System.Drawing.Size(650,350)  
    $Form.MinimumSize = New-Object -TypeName System.Drawing.Size(650,350)
    $Form.MaximumSize = New-Object -TypeName System.Drawing.Size(650,350)
    $Form.SizeGripStyle = "Hide"
    $Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHome + "\powershell.exe")
    $Form.Text = "Android App Wrapper Tool"
    $Form.ControlBox = $true
    $Form.TopMost = $true

    # Load Form
    Load-Form
}