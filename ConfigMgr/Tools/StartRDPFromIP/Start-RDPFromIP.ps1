param(
[parameter(Mandatory=$true)]
$ResourceID,
[parameter(Mandatory=$true)]
$SiteServer
)

function Load-Form {
    $Form.Controls.Add($ComboBox)
    $Form.Controls.Add($Button)
	$Form.Add_Shown({$Form.Activate()})
    $Form.Add_Shown({Get-IPAddresses})
	[void]$Form.ShowDialog()
}

function Get-CMSiteCode {
    $CMSiteCode = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer | Select-Object -ExpandProperty SiteCode
    return $CMSiteCode
}

function Get-IPAddresses {
    $IPAddresses = Get-WmiObject -Namespace "root\SMS\site_$(Get-CMSiteCode)" -Class SMS_R_System -ComputerName $SiteServer -Filter "ResourceID like '$($ResourceID)'" | Select-Object -ExpandProperty IPAddresses
    $IPAddresses | ForEach-Object {
        $ComboBox.Items.Add("$($_)")
        Write-Output $_
    }
}

function Start-RDP {
    Invoke-Expression -Command "mstsc.exe /v:$($ComboBox.SelectedItem)"
    $Form.Close()
}

# Assemblies
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

# Form
$Form = New-Object System.Windows.Forms.Form    
$Form.Size = New-Object System.Drawing.Size(350,100)  
$Form.MinimumSize = New-Object System.Drawing.Size(350,100)
$Form.MaximumSize = New-Object System.Drawing.Size(350,100)
$Form.SizeGripStyle = "Hide"
$Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHome + "\powershell.exe")
$Form.Text = "Select an IP address"
$Form.ControlBox = $true
$Form.TopMost = $true

# Check Boxes
$ComboBox = New-Object System.Windows.Forms.ComboBox
$ComboBox.Location = New-Object System.Drawing.Size(10,20)
$ComboBox.Size = New-Object System.Drawing.Size(200,30)
$ComboBox.DropDownStyle = "DropDownList"
$ComboBox.Add_SelectedValueChanged({$Button.Enabled = $true})

# Buttons
$Button = New-Object System.Windows.Forms.Button
$Button.Location = New-Object System.Drawing.Size(220,18)
$Button.Size = New-Object System.Drawing.Size(100,25)
$Button.Text = "Select"
$Button.Enabled = $false
$Button.Add_Click({Start-RDP})

# Load Form
Load-Form