[CmdletBinding()]
param(
[parameter(Mandatory=$true)]
[string]$SiteServer,
[parameter(Mandatory=$true)]
[string]$SiteCode
)

function Load-Form {
    $Form.Controls.AddRange(@($SBStatus, $CBAuto, $CBManual, $DGVAuto, $DGVManual, $ButtonStart, $ButtonClear, $ButtonAuto, $ButtonManual, $RTBInput, $OutputBox, $GBOutputBox, $GBInput, $GBAuto, $GBManual))
    $ButtonAuto.Enabled = $false
    $ButtonManual.Enabled = $false
	$Form.Add_Shown({Get-CMCollections})
    $Form.Add_Shown({
        $Form.Activate()
        $RTBInput.Select()
    })
	[void]$Form.ShowDialog()
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

function Get-CMCollections {
    $Collections = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer -Filter "Name like '%- Scheduled' OR Name like '%- Manual' OR Name like '%- Run now'"
    $SortedCollections = $Collections | Sort-Object -Property Name
    Write-OutputBox -OutputBoxMessage "Processing available collections" -Type "INFO: "
    $ButtonStart.Enabled = $false
    foreach ($Collection in $SortedCollections) {
        $CBAuto.Items.Add($Collection.Name)
        $CBManual.Items.Add($Collection.Name)
    }
    $ButtonStart.Enabled = $true
    $CollectionCount = ($Collections | Measure-Object).Count
    Write-OutputBox -OutputBoxMessage "Processed $($CollectionCount) collections" -Type "INFO: "
}

function Get-CMDeviceCollectionMembership {
    param(
    [parameter(Mandatory=$true)]
    [string]$ResourceID
    )
    $GetDeviceCollectionMembership = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_FullCollectionMembership -ComputerName $SiteServer -Filter "ResourceID='$($ResourceID)' AND (CollectionID='GT000049' OR CollectionID='GT00002D')"
    if ($GetDeviceCollectionMembership -ne $null) {
        if ($GetDeviceCollectionMembership.CollectionID -like "GT000049") {
            if ($ButtonAuto.Enabled -eq $false) {
                $ButtonAuto.Enabled = $true
            }
            $DGVAuto.Rows.Add($GetDeviceCollectionMembership.Name)
        }
        if ($GetDeviceCollectionMembership.CollectionID -like "GT00002D") {
            if ($ButtonManual.Enabled -eq $false) {
                $ButtonManual.Enabled = $true
            }
            $DGVManual.Rows.Add($GetDeviceCollectionMembership.Name)
        }
    }
}

function Get-CMDevice {
    param(
    [parameter(Mandatory=$true)]
    [string]$DeviceName,
    [parameter(Mandatory=$true)]
    [int]$Count,
    [parameter(Mandatory=$true)]
    [int]$TotalCount
    )
    $GetDevice = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_R_System -ComputerName $SiteServer -Filter "Name='$($DeviceName)'"
    if ($GetDevice -ne $null) {
        if ($GetDevice.Obsolete -eq 0) {
            Write-OutputBox -OutputBoxMessage "Found device: $($GetDevice.Name)" -Type "INFO: "
            $SBPProcessingCount.Text = "Processing device $($Count) of $($TotalCount)"
            Get-CMDeviceCollectionMembership -ResourceID $GetDevice.ResourceID
        }
    }
    else {
        Write-OutputBox -OutputBoxMessage "Not found: $($DeviceName)" -Type "WARNING: "
    }
}

function Add-DirectMembership {
    param(
    [parameter(Mandatory=$true)]
    [string]$DeviceName,
    [parameter(Mandatory=$true)]
    [string]$CollectionName
    )
    if ((Get-DeviceMembership -DeviceName $DeviceName -CollectionName $CollectionName) -eq $false) {
        $ResourceID = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_R_System -ComputerName $SiteServer -Filter "Name='$($DeviceName)'" | Select-Object -ExpandProperty ResourceID
        $CollectionQuery = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer -Filter "Name='$($CollectionName)'"
        $NewRule = ([WMIClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_CollectionRuleDirect").CreateInstance()
        $NewRule.ResourceClassName = "SMS_R_SYSTEM"
        $NewRule.ResourceID = $ResourceID
        $NewRule.Rulename = $DeviceName
        $CollectionQuery.AddMemberShipRule($NewRule) | Out-Null
        if ($Error[0]) {
            $Global:ProcessedError++
            Write-OutputBox -OutputBoxMessage "Error adding $($DeviceName) to '$($CollectionName)'" -Type "ERROR: "
        }
        else {
            $Global:ProcessedSuccess++
            Write-OutputBox -OutputBoxMessage "Successfully added $($DeviceName) to '$($CollectionName)'" -Type "INFO: "
        }
    }
    else {
        $Global:ProcessedWarning++
        Write-OutputBox -OutputBoxMessage "$($DeviceName) is already a member of '$($CollectionName)'" -Type "WARNING: "
    }
}

function Get-DeviceMembership {
    param(
    [parameter(Mandatory=$true)]
    [string]$DeviceName,
    [parameter(Mandatory=$true)]
    [string]$CollectionName
    )
    $CollectionID = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer -Filter "Name='$($CollectionName)'" | Select-Object  -ExpandProperty CollectionID
    $DeviceCollectionMembershipQuery = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_FullCollectionMembership -ComputerName $SiteServer -Filter "Name='$($DeviceName)' AND CollectionID='$($CollectionID)'" -ErrorAction SilentlyContinue
    if ($DeviceCollectionMembershipQuery) {
        return $true
    }
    else {
        return $false
    }
}

function Start-AddDeviceToCollection {
    param(
    [parameter(Mandatory=$true)]
    [string]$CollectionName,
    [parameter(Mandatory=$true)]
    [ValidateSet("Auto","Manual")]
    [string]$Type
    )
    if ($Type -like "Auto") {
        for ($RowCount = 0; $RowCount -lt $DGVAuto.RowCount; $RowCount++) {
            $ButtonAuto.Enabled = $false
            $SBPProcessingCount.Text = "Processing device $($RowCount+1) of $($DGVAuto.RowCount)"
            Write-OutputBox -OutputBoxMessage "Adding '$($DGVAuto.Rows[$RowCount].Cells["Device"].Value)' to collection: '$($CollectionName)'" -Type "INFO: "
            Add-DirectMembership -DeviceName "$($DGVAuto.Rows[$RowCount].Cells["Device"].Value)" -CollectionName $CollectionName
        }
        $ButtonAuto.Enabled = $true
        $SBPProcessingCount.Text = ""
    }
    if ($Type -like "Manual") {
        for ($RowCount = 0; $RowCount -lt $DGVManual.RowCount; $RowCount++) {
            $ButtonManual.Enabled = $false
            $SBPProcessingCount.Text = "Processing device $($RowCount+1) of $($DGVManual.RowCount)"
            Write-OutputBox -OutputBoxMessage "Adding '$($DGVManual.Rows[$RowCount].Cells["Device"].Value)' to collection: '$($CollectionName)'" -Type "INFO: "
            Add-DirectMembership -DeviceName "$($DGVManual.Rows[$RowCount].Cells["Device"].Value)" -CollectionName $CollectionName
        }
        $ButtonManual.Enabled = $true
        $SBPProcessingCount.Text = ""
    }
    $RowCount = 0
    Write-OutputBox -OutputBoxMessage "Showing results:" -Type "INFO: "
    Write-OutputBox -OutputBoxMessage "Success: $($Global:ProcessedSuccess)" -Type "INFO: "
    Write-OutputBox -OutputBoxMessage "Warning: $($Global:ProcessedWarning)" -Type "INFO: "
    Write-OutputBox -OutputBoxMessage "Error: $($Global:ProcessedError)" -Type "INFO: "
}

function Start-Search {
    $ButtonStart.Enabled = $false
    $SBPStatus.Text = "Processing"
    $CurrentCount = 0
    $Devices = $RTBInput.Text
    $DeviceArray = $Devices.Split("`n")
    if ($DeviceArray -ne $null) {
        foreach ($Device in $DeviceArray) {
            $CurrentCount++
            Get-CMDevice -DeviceName $Device -Count $CurrentCount -TotalCount ($DeviceArray | Measure-Object).Count
        }
    }
    else {
        Write-OutputBox -OutputBoxMessage "No devices has been added to the list" -Type "WARNING: "
    }
    $ButtonStart.Enabled = $true
    $SBPStatus.Text = "Ready"
    $SBPProcessingCount.Text = ""
}

function Start-Clear {
    $RTBInput.ResetText()
    $DGVAuto.Rows.Clear()
    $DGVManual.Rows.Clear()
    $OutputBox.ResetText()
    if ($ButtonAuto.Enabled -eq $true) {
        $ButtonAuto.Enabled = $false
    }
    if ($ButtonManual.Enabled -eq $true) {
        $ButtonManual.Enabled = $false
    }
}

# Global variables
$Global:ProcessedSuccess = 0
$Global:ProcessedWarning = 0
$Global:ProcessedError = 0

# Assemblies
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

# Form
$Form = New-Object System.Windows.Forms.Form    
$Form.Size = New-Object System.Drawing.Size(950,700)  
$Form.MinimumSize = New-Object System.Drawing.Size(950,700)
$Form.MaximumSize = New-Object System.Drawing.Size(950,700)
$Form.SizeGripStyle = "Hide"
$Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHome + "\powershell.exe")
$Form.Text = "Add Devices to Collection 1.0"
$Form.ControlBox = $true
$Form.TopMost = $true

# StatusBar
$SBPStatus = New-Object Windows.Forms.StatusBarPanel
$SBPStatus.Text = "Ready"
$SBPStatus.Width = "100"
$SBPTotalCount = New-Object Windows.Forms.StatusBarPanel
$SBPTotalCount.Text = ""
$SBPTotalCount.Width = "100"
$SBPProcessingCount = New-Object Windows.Forms.StatusBarPanel
$SBPProcessingCount.Text = ""
$SBPProcessingCount.Width = "740"
$SBStatus = New-Object Windows.Forms.StatusBar
$SBStatus.ShowPanels = $true
$SBStatus.SizingGrip = $false
$SBStatus.AutoSize = "Full"
$SBStatus.Panels.AddRange(@($SBPStatus, $SBPTotalCount, $SBPProcessingCount))

# GrouBox
$GBOutputBox = New-Object System.Windows.Forms.GroupBox
$GBOutputBox.Location = New-Object System.Drawing.Size(10,480) 
$GBOutputBox.Size = New-Object System.Drawing.Size(920,150) 
$GBOutputBox.Text = "Logging"
$GBInput = New-Object System.Windows.Forms.GroupBox
$GBInput.Location = New-Object System.Drawing.Size(10,10) 
$GBInput.Size = New-Object System.Drawing.Size(220,460) 
$GBInput.Text = "Device List"
$GBAuto = New-Object System.Windows.Forms.GroupBox
$GBAuto.Location = New-Object System.Drawing.Size(240,10) 
$GBAuto.Size = New-Object System.Drawing.Size(340,460) 
$GBAuto.Text = "Auto"
$GBManual = New-Object System.Windows.Forms.GroupBox
$GBManual.Location = New-Object System.Drawing.Size(590,10) 
$GBManual.Size = New-Object System.Drawing.Size(340,460) 
$GBManual.Text = "Manual"

# Button
$ButtonStart = New-Object System.Windows.Forms.Button 
$ButtonStart.Location = New-Object System.Drawing.Size(125,427)
$ButtonStart.Size = New-Object System.Drawing.Size(95,30) 
$ButtonStart.Text = "Start"
$ButtonStart.TabIndex = 1
$ButtonStart.Add_Click({Start-Search})
$ButtonClear = New-Object System.Windows.Forms.Button 
$ButtonClear.Location = New-Object System.Drawing.Size(20,427)
$ButtonClear.Size = New-Object System.Drawing.Size(95,30) 
$ButtonClear.Text = "Clear"
$ButtonClear.TabIndex = 2
$ButtonClear.Add_Click({Start-Clear})
$ButtonAuto = New-Object System.Windows.Forms.Button 
$ButtonAuto.Location = New-Object System.Drawing.Size(475,427)
$ButtonAuto.Size = New-Object System.Drawing.Size(95,30) 
$ButtonAuto.Text = "Add"
$ButtonAuto.TabIndex = 1
$ButtonAuto.Add_MouseClick({
    if ($CBAuto.SelectedItem -ne $null) {
        Start-AddDeviceToCollection -CollectionName "$($CBAuto.SelectedItem)" -Type "Auto"
    }
    else {
        Write-OutputBox -OutputBoxMessage "No collection was selected from the drop down list" -Type "WARNING: "
    }
})
$ButtonManual = New-Object System.Windows.Forms.Button 
$ButtonManual.Location = New-Object System.Drawing.Size(825,427)
$ButtonManual.Size = New-Object System.Drawing.Size(95,30) 
$ButtonManual.Text = "Add"
$ButtonManual.TabIndex = 1
$ButtonManual.Add_MouseClick({
    if ($CBManual.SelectedItem -ne $null) {
        Start-AddDeviceToCollection -CollectionName $CBManual.SelectedItem -Type "Manual"
    }
    else {
        Write-OutputBox -OutputBoxMessage "No collection was selected from the drop down list" -Type "WARNING: "
    }
})

# ComboBox
$CBAuto = New-Object System.Windows.Forms.ComboBox
$CBAuto.Location = New-Object System.Drawing.Size(250,395)
$CBAuto.Size = New-Object System.Drawing.Size(320,20)
$CBAuto.DropDownStyle = "DropDownList"
$CBAuto.DropDownHeight = "250"
$CBManual = New-Object System.Windows.Forms.ComboBox
$CBManual.Location = New-Object System.Drawing.Size(600,395)
$CBManual.Size = New-Object System.Drawing.Size(320,20)
$CBManual.DropDownStyle = "DropDownList"
$CBManual.DropDownHeight = "250"

# RichTextBox
$OutputBox = New-Object System.Windows.Forms.RichTextBox
$OutputBox.Location = New-Object System.Drawing.Size(20,500)
$OutputBox.Size = New-Object System.Drawing.Size(900,120)
$OutputBox.Font = "Courier New"
$OutputBox.BackColor = "white"
$OutputBox.ReadOnly = $true
$OutputBox.MultiLine = $True
$RTBInput = New-Object System.Windows.Forms.RichTextBox
$RTBInput.Location = New-Object System.Drawing.Size(20,27)
$RTBInput.Size = New-Object System.Drawing.Size(200,390)
$RTBInput.TabIndex = 1
$RTBInput.Add_TextChanged({
    $InputText = $RTBInput.Text
    $InputText = $InputText.Split("`n")
    $InputCount = ($InputText | Measure-Object).Count
    $SBPTotalCount.Text = "Row count: $($InputCount)"
})

# DataGriView
$DGVAuto = New-Object System.Windows.Forms.DataGridView
$DGVAuto.Location = New-Object System.Drawing.Size(250,30)
$DGVAuto.Size = New-Object System.Drawing.Size(320,360)
$DGVAuto.Anchor = "Top, Bottom, Left, Right"
$DGVAuto.ColumnCount = 1
$DGVAuto.ColumnHeadersVisible = $true
$DGVAuto.Columns[0].Name = "Device"
$DGVAuto.Columns[0].AutoSizeMode = "Fill"
$DGVAuto.AllowUserToAddRows = $false
$DGVAuto.AllowUserToDeleteRows = $false
$DGVAuto.ReadOnly = $true
$DGVAuto.MultiSelect = $false
$DGVAuto.ColumnHeadersHeightSizeMode = "DisableResizing"
$DGVAuto.RowHeadersWidthSizeMode = "DisableResizing"
$DGVAuto.RowHeadersVisible = $false
$DGVManual = New-Object System.Windows.Forms.DataGridView
$DGVManual.Location = New-Object System.Drawing.Size(600,30)
$DGVManual.Size = New-Object System.Drawing.Size(320,360)
$DGVManual.Anchor = "Top, Bottom, Left, Right"
$DGVManual.ColumnCount = 1
$DGVManual.ColumnHeadersVisible = $true
$DGVManual.Columns[0].Name = "Device"
$DGVManual.Columns[0].AutoSizeMode = "Fill"
$DGVManual.AllowUserToAddRows = $false
$DGVManual.AllowUserToDeleteRows = $false
$DGVManual.ReadOnly = $true
$DGVManual.MultiSelect = $false
$DGVManual.ColumnHeadersHeightSizeMode = "DisableResizing"
$DGVManual.RowHeadersWidthSizeMode = "DisableResizing"
$DGVManual.RowHeadersVisible = $false

# Load Form
Load-Form