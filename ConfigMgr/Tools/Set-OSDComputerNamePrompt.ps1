function Load-Form {
    $Form.Controls.Add($TBComputerName)
    $Form.Controls.Add($GBComputerName)
    $Form.Controls.Add($ButtonOK)
    $Form.Add_Shown({$Form.Activate()})
    [void] $Form.ShowDialog()
}

function Set-OSDComputerName {
    $ErrorProvider.Clear()
    if ($TBComputerName.Text.Length -gt 15) {
        $ErrorProvider.SetError($GBComputerName, "Computer name cannot be more than 15 characters")
    }
    else {
        $OSDComputerName = $TBComputerName.Text.Replace("[","").Replace("]","").Replace(":","").Replace(";","").Replace("|","").Replace("=","").Replace("+","").Replace("*","").Replace("?","").Replace("<","").Replace(">","").Replace("/","").Replace("\","").Replace(",","")
        $TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment 
        $TSEnv.Value("OSDComputerName") = "$($OSDComputerName)"
        $Form.Close()
    }
}

[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

$Global:ErrorProvider = New-Object System.Windows.Forms.ErrorProvider

$Form = New-Object System.Windows.Forms.Form    
$Form.Size = New-Object System.Drawing.Size(285,140)  
$Form.MinimumSize = New-Object System.Drawing.Size(285,140)
$Form.MaximumSize = New-Object System.Drawing.Size(285,140)
$Form.StartPosition = "CenterScreen"
$Form.SizeGripStyle = "Hide"
$Form.Text = "Enter Computer Name"
$Form.ControlBox = $false
$Form.TopMost = $true

$TBComputerName = New-Object System.Windows.Forms.TextBox
$TBComputerName.Location = New-Object System.Drawing.Size(25,30) 
$TBComputerName.Size = New-Object System.Drawing.Size(215,50)
$TBComputerName.TabIndex = "1"

$GBComputerName = New-Object System.Windows.Forms.GroupBox
$GBComputerName.Location = New-Object System.Drawing.Size(20,10) 
$GBComputerName.Size = New-Object System.Drawing.Size(225,50) 
$GBComputerName.Text = "Computer name:" 

$ButtonOK = New-Object System.Windows.Forms.Button 
$ButtonOK.Location = New-Object System.Drawing.Size(195,70) 
$ButtonOK.Size = New-Object System.Drawing.Size(50,20) 
$ButtonOK.Text = "OK"
$ButtonOK.TabIndex = "2"
$ButtonOK.Add_Click({Set-OSDComputerName})

Load-Form