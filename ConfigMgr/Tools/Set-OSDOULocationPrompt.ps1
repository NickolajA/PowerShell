param(
[parameter(Mandatory=$true)]
[string]$RBOptionFirst,
[parameter(Mandatory=$true)]
[string]$RBOptionSecond,
[parameter(Mandatory=$true)]
[string]$DomainName,
[parameter(Mandatory=$true)]
[string]$DomainSuffix,
[parameter(Mandatory=$true)]
[string[]]$LocationList
)
 
function Load-Form {
    $Form.Controls.AddRange(@($RBOption1, $RBOption2, $ComboBox, $Button, $GBSystem, $GBLocation))
    $ComboBox.Items.AddRange($LocationList)
    $Form.Add_Shown({$Form.Activate()})
    [void]$Form.ShowDialog()
}
 
function Set-OULocation {
    param(
    [parameter(Mandatory=$true)]
    $Location
    )
    if ($RBOption1.Checked -eq $true) {
        $OULocation = "LDAP://OU=$($RBOptionFirst),OU=$($Location),DC=$($DomainName),DC=$($DomainSuffix)"
    }
    if ($RBOption2.Checked -eq $true) {
        $OULocation = "LDAP://OU=$($RBOptionSecond),OU=$($Location),DC=$($DomainName),DC=$($DomainSuffix)"
    }
    $TSEnvironment = New-Object -COMObject Microsoft.SMS.TSEnvironment 
    $TSEnvironment.Value("OSDDomainOUName") = "$($OULocation)"
    $Form.Close()
}
 
# Assemblies
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
 
# Form
$Form = New-Object System.Windows.Forms.Form    
$Form.Size = New-Object System.Drawing.Size(260,220)  
$Form.MinimumSize = New-Object System.Drawing.Size(260,220)
$Form.MaximumSize = New-Object System.Drawing.Size(260,220)
$Form.SizeGripStyle = "Hide"
$Form.StartPosition = "CenterScreen"
$Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHome + "\powershell.exe")
$Form.Text = "Choose a location"
$Form.ControlBox = $false
$Form.TopMost = $true
 
# Group boxes
$GBSystem = New-Object System.Windows.Forms.GroupBox
$GBSystem.Location = New-Object System.Drawing.Size(10,10)
$GBSystem.Size = New-Object System.Drawing.Size(220,60)
$GBSystem.Text = "Select system"
$GBLocation = New-Object System.Windows.Forms.GroupBox
$GBLocation.Location = New-Object System.Drawing.Size(10,80)
$GBLocation.Size = New-Object System.Drawing.Size(220,60)
$GBLocation.Text = "Select location"
 
# Radio buttons
$RBOption1 = New-Object System.Windows.Forms.RadioButton
$RBOption1.Location = New-Object System.Drawing.Size(20,33)
$RBOption1.Size = New-Object System.Drawing.Size(100,20)
$RBOption1.Text = "$($RBOptionFirst)"
$RBOption1.Add_MouseClick({$ComboBox.Enabled = $true})
$RBOption2 = New-Object System.Windows.Forms.RadioButton
$RBOption2.Location = New-Object System.Drawing.Size(120,33)
$RBOption2.Size = New-Object System.Drawing.Size(100,20)
$RBOption2.Text = "$($RBOptionSecond)"
$RBOption2.Add_MouseClick({$ComboBox.Enabled = $true})
 
# Combo Boxes
$ComboBox = New-Object System.Windows.Forms.ComboBox
$ComboBox.Location = New-Object System.Drawing.Size(20,105)
$ComboBox.Size = New-Object System.Drawing.Size(200,30)
$ComboBox.DropDownStyle = "DropDownList"
$ComboBox.Add_SelectedValueChanged({$Button.Enabled = $true})
$ComboBox.Enabled = $false
 
# Buttons
$Button = New-Object System.Windows.Forms.Button
$Button.Location = New-Object System.Drawing.Size(140,145)
$Button.Size = New-Object System.Drawing.Size(80,25)
$Button.Text = "OK"
$Button.Enabled = $false
$Button.Add_Click({Set-OULocation -Location $ComboBox.SelectedItem.ToString()})
 
# Load Form
Load-Form