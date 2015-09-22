param(
[parameter(Mandatory=$false)]
$SiteServer,
[parameter(Mandatory=$false)]
$TaskSequence
)

function Load-Form {
    $Form.Controls.AddRange(@($DGVPackageRef, $DGVPackageDP, $ButtonValidate, $ButtonRedist, $OutputBox, $GBPackageRef, $GBPackageDP, $GBPackageOption, $GBPackageInfo))
    $ButtonValidate.Enabled = $false
    $ButtonRedist.Enabled = $false
	$Form.Add_Shown({$Form.Activate()})
    $Form.Add_Shown({Get-TSReferences})
	[void]$Form.ShowDialog()
}

function Get-CMSiteCode {
    $CMSiteCode = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer | Select-Object -ExpandProperty SiteCode
    return $CMSiteCode
}

function Get-TSReferences {
    Write-OutputBox -OutputBoxMessage "Loading package references for task sequence: $($TaskSequence)" -Type "INFO: "
    $TSPackageID = Get-WmiObject -Namespace "root\SMS\site_$($Global:SiteCode)" -Class SMS_TaskSequencePackage -ComputerName $SiteServer -Filter "Name like '$($TaskSequence)'" | Select-Object -ExpandProperty PackageID
    $TSReferences = Get-WmiObject -Namespace "root\SMS\site_$($Global:SiteCode)" -Class SMS_TaskSequencePackageReference -ComputerName $SiteServer -Filter "PackageID like '$($TSPackageID)'"
    $TSReferencesSorted = $TSReferences | Sort-Object -Property ObjectName
    $TSReferencesSorted | ForEach-Object {
        switch ($_.ObjectType) {
            0 { $CurrentPackageType = "Package" }
            3 { $CurrentPackageType = "Driver Package" }
            257 { $CurrentPackageType = "OS Image Package" }
            258 { $CurrentPackageType = "Boot Image" }
            259 { $CurrentPackageType = "OS Install Package" }
            512 { $CurrentPackageType = "Application" }
        }
        $DGVPackageRef.Rows.Add($_.ObjectName, $_.NumberSuccess, $_.NumberInProgress, $_.NumberErrors, $_.RefPackageID, $CurrentPackageType)
        $DGVPackageRef.ClearSelection()
    }
}

function Get-PackageDPDetails {
    param(
    [parameter(Mandatory=$true)]
    [string]$Value
    )
    if ($DGVPackageDP.Rows.Count -ge 1) {
        $DGVPackageDP.Rows.Clear()
        $DGVPackageDP.Refresh()
    }
    Write-OutputBox -OutputBoxMessage "Loading Distribution Points for PackageID: $($SelectedPackageID)" -Type "INFO: "
    $DPs = Get-WmiObject -Namespace "root\SMS\site_$($Global:SiteCode)" -Class SMS_DistributionDPStatus -ComputerName $SiteServer -Filter "PackageID like '$($Value)'" | Select-Object NALPath, MessageState
    $DPs | ForEach-Object {
        $TrimmedServerNALPath = ($_.NALPath).Split(']')[0].TrimStart('["Display=')
        $CurrentServerNALPath = $TrimmedServerNALPath.SubString(0,$TrimmedServerNALPath.Length-2)
        switch ($_.MessageState) {
            1 { $CurrentMessageState = "Success" }
            2 { $CurrentMessageState = "In Progress" }
            3 { $CurrentMessageState = "Error" }
        }
        $DGVPackageDP.Rows.Add($CurrentServerNALPath, $CurrentMessageState)
    }
}

function Redistribute-Package {
    param(
    [parameter(Mandatory=$true)]
    $PackageID,
    [parameter(Mandatory=$true)]
    [ValidateSet("Package","Driver Package","OS Image Package","Boot Image","OS Install Image","Application")]
    $PackageType,
    [parameter(Mandatory=$true)]
    $PackageName
    )
    switch ($PackageType) {
        "Package" { $SMSClass = "SMS_Package" }
        "Driver Package" { $SMSClass = "SMS_DriverPackage" }
        "OS Image Package" { $SMSClass = "SMS_ImagePackage" }
        "OS Install Package" { $SMSClass = "SMS_OperatingSystemInstallPackage" }
        "Boot Image" { $SMSClass = "SMS_BootImagePackage" }
    }
    try {
        $WmiObject = Get-WmiObject -Namespace "root\SMS\site_$($Global:SiteCode)" -Class $SMSClass -ComputerName $SiteServer -Filter "PackageID = '$($PackageID)'"
        $WmiObject.RefreshPkgSource()
        Write-OutputBox -OutputBoxMessage "Successfully started to redistribute $($PackageType.ToLower()): '$($PackageName)'" -Type "INFO: "
    }
    catch {
        Write-OutputBox -OutputBoxMessage "$($_.Exception.Message)" -Type "ERROR: "
    }
}

function Validate-Package {
    param(
    [parameter(Mandatory=$true)]
    $PackageID,
    [parameter(Mandatory=$true)]
    [ValidateSet("Package","Driver Package","OS Image Package","Boot Image","OS Install Image","Application")]
    $PackageType,
    [parameter(Mandatory=$true)]
    $PackageName
    )
    switch ($PackageType) {
        "Package" { $SMSClass = "SMS_Package" }
        "Driver Package" { $SMSClass = "SMS_DriverPackage" }
        "OS Image Package" { $SMSClass = "SMS_ImagePackage" }
        "OS Install Package" { $SMSClass = "SMS_OperatingSystemInstallPackage" }
        "Boot Image" { $SMSClass = "SMS_BootImagePackage" }
    }
    try {
        $DPPackageNALs = (Get-WmiObject -Namespace "root\SMS\site_$($Global:SiteCode)" -Class SMS_DistributionPoint -ComputerName $SiteServer -Filter "PackageID = '$($PackageID)'").ServerNALPath
        $DPPackageNALs | ForEach-Object {
            $DPName = ($_).Split(']')[0].TrimStart('["Display=')
            $ValidateExecution = Invoke-WmiMethod -Namespace "root\SMS\site_$($Global:SiteCode)" -Class SMS_DistributionPoint -Name VerifyPackage -ArgumentList ($_, "CAS0000C") -ComputerName $SiteServer
            if ($ValidateExecution.ReturnValue -eq 0) {
                Write-OutputBox -OutputBoxMessage "Successfully started validating '$($PackageName)' on DP: $($DPName)" -Type "INFO: "
            }
        }
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
	[string]$Type
	)
	Process {
		if ($OutputBox.Text.Length -eq 0) {
			$OutputBox.Text = "$($Type)$($OutputBoxMessage)"
			[System.Windows.Forms.Application]::DoEvents()
            $OutputBox.ScrollToCaret()
		}
		else {
			$OutputBox.AppendText("`n$($Type)$($OutputBoxMessage)")
			[System.Windows.Forms.Application]::DoEvents()
            $OutputBox.ScrollToCaret()
		}
	}
}

# Global variables
$Global:SiteCode = Get-CMSiteCode

# Assemblies
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

# Form
$Form = New-Object System.Windows.Forms.Form    
$Form.Size = New-Object System.Drawing.Size(950,815)  
$Form.MinimumSize = New-Object System.Drawing.Size(950,815)
$Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon(($env:SMS_ADMIN_UI_PATH).SubString(0,$env:SMS_ADMIN_UI_PATH.Length-5) + "\Microsoft.ConfigurationManagement.exe")
$Form.Text = "Task Sequence References Tool 1.0"
$Form.ControlBox = $true
$Form.TopMost = $true

# OutputBox
$OutputBox = New-Object System.Windows.Forms.RichTextBox 
$OutputBox.Location = New-Object System.Drawing.Size(20,590) 
$OutputBox.Size = New-Object System.Drawing.Size(750,150)
$OutputBox.Anchor = "Bottom, Left, Right"
$OutputBox.Font = "Courier New"
$OutputBox.BackColor = "white"
$OutputBox.ReadOnly = $true
$OutputBox.MultiLine = $True

# Buttons
$ButtonValidate = New-Object System.Windows.Forms.Button
$ButtonValidate.Location = New-Object System.Drawing.Size(800,30)
$ButtonValidate.Size = New-Object System.Drawing.Size(110,30)
$ButtonValidate.Text = "Validate"
$ButtonValidate.Anchor = "Right, Top, Bottom"
$ButtonValidate.Add_SizeChanged({$ButtonValidate.Size = New-Object System.Drawing.Size(110,30)})
$ButtonValidate.Add_MouseClick({
    $SelectedPackageIDValidate = $DGVPackageRef.Rows[$DGVPackageRef.SelectedCells[0].RowIndex].Cells[4].Value
    $SelectedPackageTypeValidate = $DGVPackageRef.Rows[$DGVPackageRef.SelectedCells[0].RowIndex].Cells[5].Value
    $SelectedPackageNameValidate = $DGVPackageRef.Rows[$DGVPackageRef.SelectedCells[0].RowIndex].Cells[0].Value
    Validate-Package -PackageID $SelectedPackageIDValidate -PackageType "$($SelectedPackageTypeValidate)" -PackageName "$($SelectedPackageNameValidate)"
})
$ButtonRedist = New-Object System.Windows.Forms.Button
$ButtonRedist.Location = New-Object System.Drawing.Size(800,70)
$ButtonRedist.Size = New-Object System.Drawing.Size(110,30)
$ButtonRedist.Text = "Redistribute"
$ButtonRedist.Anchor = "Right, Top, Bottom"
$ButtonRedist.Add_SizeChanged({$ButtonRedist.Size = New-Object System.Drawing.Size(110,30)})
$ButtonRedist.Add_MouseClick({
    $SelectedPackageIDRedist = $DGVPackageRef.Rows[$DGVPackageRef.SelectedCells[0].RowIndex].Cells[4].Value
    $SelectedPackageTypeRedist = $DGVPackageRef.Rows[$DGVPackageRef.SelectedCells[0].RowIndex].Cells[5].Value
    $SelectedPackageNameRedist = $DGVPackageRef.Rows[$DGVPackageRef.SelectedCells[0].RowIndex].Cells[0].Value
    Redistribute-Package -PackageID $SelectedPackageIDRedist -PackageType "$($SelectedPackageTypeRedist)" -PackageName "$($SelectedPackageNameRedist)"
})

# DataGriView
$DGVPackageRef = New-Object System.Windows.Forms.DataGridView
$DGVPackageRef.Location = New-Object System.Drawing.Size(20,30)
$DGVPackageRef.Size = New-Object System.Drawing.Size(750,270)
$DGVPackageRef.Anchor = "Top, Bottom, Left, Right"
$DGVPackageRef.ColumnCount = 6
$DGVPackageRef.ColumnHeadersVisible = $true
$DGVPackageRef.Columns[0].Name = "Package"
$DGVPackageRef.Columns[0].AutoSizeMode = "Fill"
$DGVPackageRef.Columns[1].Name = "Success"
$DGVPackageRef.Columns[1].Width = 60
$DGVPackageRef.Columns[2].Name = "In Progress"
$DGVPackageRef.Columns[2].Width = 70
$DGVPackageRef.Columns[3].Name = "Failed"
$DGVPackageRef.Columns[3].Width = 60
$DGVPackageRef.Columns[4].Name = "Package ID"
$DGVPackageRef.Columns[4].Width = 70
$DGVPackageRef.Columns[5].Name = "Package Type"
$DGVPackageRef.Columns[5].Width = 110
$DGVPackageRef.AllowUserToAddRows = $false
$DGVPackageRef.AllowUserToDeleteRows = $false
$DGVPackageRef.ReadOnly = $True
$DGVPackageRef.MultiSelect = $false
$DGVPackageRef.ColumnHeadersHeightSizeMode = "DisableResizing"
$DGVPackageRef.RowHeadersWidthSizeMode = "DisableResizing"
$DGVPackageRef.RowHeadersVisible = $false
$DGVPackageRef.Add_CellContentClick({
    if ($DGVPackageRef.CurrentCellAddress.X -eq 0) {
        if ($DGVPackageRef.Rows[$DGVPackageRef.SelectedCells[0].RowIndex].Cells[5].Value -like "Application") {
            $ButtonValidate.Enabled = $false
            $ButtonRedist.Enabled = $false
        }
        else {
            $ButtonValidate.Enabled = $true
            $ButtonRedist.Enabled = $true
        }
        $SelectedPackageID = $DGVPackageRef.Rows[$DGVPackageRef.SelectedCells[0].RowIndex].Cells[4].Value
        $GBPackageDP.Text = "Distribution Status for selected package: $($DGVPackageRef.Rows[$DGVPackageRef.SelectedCells[0].RowIndex].Cells[0].Value)"
        Get-PackageDPDetails -Value $SelectedPackageID
    }
})
$DGVPackageDP = New-Object System.Windows.Forms.DataGridView
$DGVPackageDP.Location = New-Object System.Drawing.Size(20,335)
$DGVPackageDP.Size = New-Object System.Drawing.Size(750,220)
$DGVPackageDP.Anchor = "Bottom, Left, Right"
$DGVPackageDP.ColumnCount = 2
$DGVPackageDP.ColumnHeadersVisible = $true
$DGVPackageDP.Columns[0].Name = "Distribution Point"
$DGVPackageDP.Columns[0].AutoSizeMode = "Fill"
$DGVPackageDP.Columns[1].Name = "Distribution Status"
$DGVPackageDP.Columns[1].Width = 100
$DGVPackageDP.AllowUserToAddRows = $false
$DGVPackageDP.AllowUserToDeleteRows = $false
$DGVPackageDP.ReadOnly = $True
$DGVPackageDP.MultiSelect = $false
$DGVPackageDP.ColumnHeadersHeightSizeMode = "DisableResizing"
$DGVPackageDP.RowHeadersWidthSizeMode = "DisableResizing"
$DGVPackageDP.RowHeadersVisible = $false
$DGVPackageDP.Add_SelectionChanged({
    $DGVPackageDP.ClearSelection()
})

# Group Boxes
$GBPackageRef = New-Object System.Windows.Forms.GroupBox
$GBPackageRef.Location = New-Object System.Drawing.Size(10,10) 
$GBPackageRef.Size = New-Object System.Drawing.Size(770,300)
$GBPackageRef.Anchor = "Top, Bottom, Left, Right"
$GBPackageRef.Text = "Packages referenced in the task sequence: $($TaskSequence)"
$GBPackageRef.Name = "PackageRef"
$GBPackageDP = New-Object System.Windows.Forms.GroupBox
$GBPackageDP.Location = New-Object System.Drawing.Size(10,315) 
$GBPackageDP.Size = New-Object System.Drawing.Size(770,250)
$GBPackageDP.Anchor = "Bottom, Left, Right"
$GBPackageDP.Text = "Distribution Status for selected package"
$GBPackageDP.Name = "PackageDP"
$GBPackageInfo = New-Object System.Windows.Forms.GroupBox
$GBPackageInfo.Location = New-Object System.Drawing.Size(10,570) 
$GBPackageInfo.Size = New-Object System.Drawing.Size(770,180)
$GBPackageInfo.Anchor = "Bottom, Left, Right"
$GBPackageInfo.Text = "Information"
$GBPackageInfo.Name = "PackageInfo"
$GBPackageOption = New-Object System.Windows.Forms.GroupBox
$GBPackageOption.Location = New-Object System.Drawing.Size(790,10) 
$GBPackageOption.Size = New-Object System.Drawing.Size(130,100)
$GBPackageOption.Anchor = "Right, Top"
$GBPackageOption.Text = "Package Options"
$GBPackageOption.Name = "PackageDP"

# Load Form
Load-Form