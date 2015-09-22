function Load-Form {
    $ButtonDelete.Enabled = $false
    $ButtonDelete.Visible = $true
    $ButtonRestart.Enabled = $false
    $ButtonRestart.Visible = $false
    $Form.Controls.Add($RBLocal)
    $Form.Controls.Add($RBRemote)
    $Form.Controls.Add($BlogLink)
    $Form.Controls.Add($TBPackageID)
    $Form.Controls.Add($TBComputer)
    $Form.Controls.Add($GBPackageID)
    $Form.Controls.Add($GBComputer)
    $Form.Controls.Add($ButtonSearch)
    $Form.Controls.Add($ButtonDelete)
    $Form.Controls.Add($ButtonRestart)
    $Form.Controls.Add($OutputBox)
    $Form.Controls.Add($DGVResults)
	$Form.Add_Shown({$Form.Activate()})
	[void]$Form.ShowDialog()
}

function Start-Search {
    Begin {
        try {
            $OutputBox.ResetText()
            $DGVResults.Rows.Clear()
            $DGVResults.Refresh()
        }
        catch {
            Write-OutputBox -OutputBoxMessage "$($_.Exception.Message)" -Type "ERROR: "
        }
    }
    Process {
        try {
            switch ($RBLocal.Checked) {
                $true {$Global:ComputerName = $env:COMPUTERNAME}
                $false {$Global:ComputerName = $TBComputer.Text}
                Default {$Global:ComputerName = $env:COMPUTERNAME}
            }
            if ($TBPackageID.Text.Length -ge 3) {
                Write-OutputBox -OutputBoxMessage "Running against computer: $($Global:ComputerName)" -Type "INFO: "
                $WMIObject = Get-WmiObject -Namespace "root\CCM\Scheduler" -Class CCM_Scheduler_History -ComputerName $Global:ComputerName -ErrorAction Stop | Where-Object {$_.ScheduleID -like "*$($TBPackageID.Text)*"} | Select-Object ScheduleID
                if ($WMIObject) {
                    $WMIObject | ForEach-Object {
                        $DGVResults.Rows.Add(([string]$_.ScheduleID)) | Out-Null
                        $DGVResults.Rows[0].Cells[0].Selected = $false
                    }
                $RowCount = $DGVResults.Rows.Count
                Write-OutputBox -OutputBoxMessage "Found $($RowCount) objects" -Type "INFO: "
                }
                else {
                    Write-OutputBox -OutputBoxMessage "No scheduled objects was found" -Type "WARNING: "
                }
            }
            else {
                Write-OutputBox -OutputBoxMessage "Please enter a PackageID with atleast 3 characters" -Type "WARNING: "
            }
        }
        catch {
            Write-OutputBox -OutputBoxMessage "$($_.Exception.Message)" -Type "ERROR: "
        }
    }
}

function Delete-Object {
    param(
    $Object,
    $CurrentCellValue
    )
    Process {
        if (-not($Object -eq $null)) {
            try {
                Write-OutputBox -OutputBoxMessage "Attempting to remove $($Object)" -Type "INFO: "
                Remove-WmiObject -InputObject $Object -ErrorAction Stop
                if (-not(Get-WmiObject -Namespace "root\CCM\Scheduler" -Class CCM_Scheduler_History -ComputerName $Global:ComputerName -ErrorAction SilentlyContinue | Where-Object {$_.ScheduleID -like "*$($CurrentCellValue)*"})) {
                    Write-OutputBox -OutputBoxMessage "Object was successfully removed" -Type "INFO: "
                    $ButtonDelete.Visible = $false
                    $ButtonDelete.Enabled = $false
                    $ButtonRestart.Visible = $true
                    $ButtonRestart.Enabled = $true
                    $DGVResults.Rows.Clear()
                    $DGVResults.Refresh()
                }
            }
            catch {
                Write-OutputBox -OutputBoxMessage "$($_.Exception.Message)" -Type "ERROR: "
            }
        }
        else {
            Write-OutputBox -OutputBoxMessage "No object has been selected" -Type "WARNING: "
        }
    }
}

function Restart-SMSAgent {
    try {
        $WarningPreference = "SilentlyContinue"
        $ButtonRestart.Enabled = $false
        Get-Service -Name "CCMExec" -ComputerName $Global:ComputerName | Restart-Service
        do {
            [System.Windows.Forms.Application]::DoEvents()
        }
        until ((Get-Service -Name "CCMExec" -ComputerName $Global:ComputerName).Status -eq "Running")
        if ((Get-Service -Name "CCMExec" -ComputerName $Global:ComputerName).Status -eq "Running") {
             Write-OutputBox -OutputBoxMessage "Successfully restarted the 'SMS Agent' service" -Type "INFO: "
        }
        $WarningPreference = "Continue"
        $ButtonRestart.Visible = $false
        $ButtonRestart.Enabled = $false
        $ButtonDelete.Visible = $true
        $ButtonDelete.Enabled = $false
    }
    catch {
        Write-OutputBox -OutputBoxMessage "$($_.Exception.Message)" -Type "ERROR: "
    }
}

function Write-OutputBox {
	param(
	[parameter(Mandatory=$true)]
	[string]$OutputBoxMessage,
	[ValidateSet("WARNING: ","ERROR: ","INFO: ")]
	[string]$Type,
    [switch]$NoNewLine
	)
	Process {
        $DateTime = (Get-Date).ToLongTimeString()
        if ($NoNewLine -eq $true) {
		    if ($OutputBox.Text.Length -eq 0) {
			    $OutputBox.Text = "$($OutputBoxMessage)"
			    [System.Windows.Forms.Application]::DoEvents()
                $OutputBox.SelectionStart = $OutputBox.Text.Length
                $OutputBox.ScrollToCaret()
		    }
		    else {
			    $OutputBox.AppendText("$($OutputBoxMessage)")
			    [System.Windows.Forms.Application]::DoEvents()
                $OutputBox.SelectionStart = $OutputBox.Text.Length
                $OutputBox.ScrollToCaret()
		    }
        }
        else {
		    if ($OutputBox.Text.Length -eq 0) {
			    $OutputBox.Text = "$($DateTime) $($Type)$($OutputBoxMessage)"
			    [System.Windows.Forms.Application]::DoEvents()
                $OutputBox.SelectionStart = $OutputBox.Text.Length
                $OutputBox.ScrollToCaret()
		    }
		    else {
			    $OutputBox.AppendText("`n$($DateTime) $($Type)$($OutputBoxMessage)")
			    [System.Windows.Forms.Application]::DoEvents()
                $OutputBox.SelectionStart = $OutputBox.Text.Length
                $OutputBox.ScrollToCaret()
		    }        
        }
	}
}

# Assemblies
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

# Form
$Form = New-Object System.Windows.Forms.Form    
$Form.Size = New-Object System.Drawing.Size(600,440)  
$Form.MinimumSize = New-Object System.Drawing.Size(600,440)
$Form.MaximumSize = New-Object System.Drawing.Size(600,440)
$Form.SizeGripStyle = "Hide"
$Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHome + "\powershell.exe")
$Form.Text = "Re-run Task Sequence Tool 1.0"
$Form.ControlBox = $true
$Form.TopMost = $true

# Textbox
$TBPackageID = New-Object System.Windows.Forms.TextBox
$TBPackageID.Location = New-Object System.Drawing.Size(15,27)
$TBPackageID.Size = New-Object System.Drawing.Size(145,20)
$TBPackageID.TabIndex = 1
$TBComputer = New-Object System.Windows.Forms.TextBox
$TBComputer.Location = New-Object System.Drawing.Size(310,27)
$TBComputer.Size = New-Object System.Drawing.Size(145,20)
$TBComputer.Enabled = $false

# Button
$ButtonSearch = New-Object System.Windows.Forms.Button 
$ButtonSearch.Location = New-Object System.Drawing.Size(470,20) 
$ButtonSearch.Size = New-Object System.Drawing.Size(100,30) 
$ButtonSearch.Text = "Search"
$ButtonSearch.TabIndex = 2
$ButtonSearch.Add_Click({Start-Search})
$ButtonDelete = New-Object System.Windows.Forms.Button 
$ButtonDelete.Location = New-Object System.Drawing.Size(470,195) 
$ButtonDelete.Size = New-Object System.Drawing.Size(100,30) 
$ButtonDelete.Text = "Delete"
$ButtonDelete.TabIndex = 3
$ButtonDelete.Add_Click({Delete-Object -Object $Global:ScheduledObject -CurrentCellValue $Global:CurrentCellValue})
$ButtonRestart = New-Object System.Windows.Forms.Button 
$ButtonRestart.Location = New-Object System.Drawing.Size(470,195) 
$ButtonRestart.Size = New-Object System.Drawing.Size(100,30) 
$ButtonRestart.Text = "Restart Agent"
$ButtonRestart.Add_Click({Restart-SMSAgent})

# Groupbox
$GBPackageID = New-Object System.Windows.Forms.GroupBox
$GBPackageID.Location = New-Object System.Drawing.Size(10,10) 
$GBPackageID.Size = New-Object System.Drawing.Size(155,45) 
$GBPackageID.Text = "PackageID"
$GBComputer = New-Object System.Windows.Forms.GroupBox
$GBComputer.Location = New-Object System.Drawing.Size(170,10) 
$GBComputer.Size = New-Object System.Drawing.Size(295,45) 
$GBComputer.Text = "Computer options"

# Radiobutton
$RBLocal = New-Object System.Windows.Forms.RadioButton
$RBLocal.Location = New-Object System.Drawing.Size(180,29)
$RBLocal.Size = New-Object System.Drawing.Size(50,15)
$RBLocal.Text = "Local"
$RBLocal.Checked = $true
$RBLocal.Add_Click({
    $TBComputer.Enabled = $false
    $TBComputer.ResetText()
})
$RBRemote = New-Object System.Windows.Forms.RadioButton
$RBRemote.Location = New-Object System.Drawing.Size(240,29)
$RBRemote.Size = New-Object System.Drawing.Size(65,15)
$RBRemote.Text = "Remote"
$RBRemote.Add_Click({
    $TBComputer.Enabled = $true
})

# Outputbox
$OutputBox = New-Object System.Windows.Forms.RichTextBox 
$OutputBox.Location = New-Object System.Drawing.Size(10,235) 
$OutputBox.Size = New-Object System.Drawing.Size(560,135)
$OutputBox.Font = "Courier New"
$OutputBox.BackColor = "white"
$OutputBox.ReadOnly = $true
$OutputBox.MultiLine = $true
$OutputBox.TabIndex = "5"

# Global variables
$Global:ScheduledObject = New-Object System.Management.ManagementObject
$Global:CurrentCellValue = ""
$Global:ComputerName = ""

#DataGriView
$DGVResults = New-Object System.Windows.Forms.DataGridView
$DGVResults.Location = New-Object System.Drawing.Size(10,65)
$DGVResults.Size = New-Object System.Drawing.Size(559,120)
$DGVResults.ColumnCount = 1
$DGVResults.ColumnHeadersVisible = $true
$DGVResults.Columns[0].Name = "WMI Object"
$DGVResults.Columns[0].AutoSizeMode = "Fill"
$DGVResults.AllowUserToAddRows = $false
$DGVResults.AllowUserToDeleteRows = $false
$DGVResults.ReadOnly = $True
$DGVResults.ColumnHeadersHeightSizeMode = "DisableResizing"
$DGVResults.RowHeadersWidthSizeMode = "DisableResizing"
$DGVResults.Add_CellClick({
    try {
        if ($_.RowIndex -ge "0") {
            $WMISelectedObject = $DGVResults.CurrentCell.Value
            $Global:CurrentCellValue = $DGVResults.CurrentCell.Value
            $WMIObjectRemove = Get-WmiObject -Namespace "root\CCM\Scheduler" -Class CCM_Scheduler_History -ComputerName $Global:ComputerName -ErrorAction Stop | Where-Object {$_.ScheduleID -like "*$($WMISelectedObject)*"} 
            Write-OutputBox -OutputBoxMessage "Selected the '$($WMIObjectRemove)' schedule object" -Type "INFO: "
            $Global:ScheduledObject = $WMIObjectRemove
            $ButtonDelete.Visible = $true
            $ButtonDelete.Enabled = $true
        }
    }
    catch {
        Write-OutputBox -OutputBoxMessage "$($_.Exception.Message)" -Type "ERROR: "
    }
})

# Link
$OpenLink = {[System.Diagnostics.Process]::Start("http://www.scconfigmgr.com")}
$BlogLink = New-Object System.Windows.Forms.LinkLabel
$BlogLink.Location = New-Object System.Drawing.Size(10,377) 
$BlogLink.Size = New-Object System.Drawing.Size(150,25)
$BlogLink.Text = "www.scconfigmgr.com"
$BlogLink.Add_Click($OpenLink)
$BlogLink.TabIndex = 6

# Load form
Load-Form