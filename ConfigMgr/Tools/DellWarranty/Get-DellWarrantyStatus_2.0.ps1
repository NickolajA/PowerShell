[CmdLetBinding()]
param(
    [parameter(Mandatory=$true, HelpMessage="Name of the Site server with the SMS Provider")]
    [ValidateNotNullOrEmpty()]
    [string]$SiteServer,
    [parameter(Mandatory=$true, HelpMessage="Name of the device that will be checked for warranty")]
    [ValidateNotNullOrEmpty()]
    [string]$DeviceName,
    [parameter(Mandatory=$true, HelpMessage="ResourceID of the device")]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceID
)
Begin {
    # Determine SiteCode from SMS Provider
    try {
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
            }
        }
    }
    catch [Exception] {
        Throw "Unable to determine SiteCode"
    }
}
Process {
    #Functions
    function Load-Form {
        $Form.Controls.AddRange(@(
            $BlogLink,
            $ButtonGet,
            $TBComputerName,
            $TBServiceTag,
            $TBModel,
            $GBServiceTag,
            $GBComputerName,
            $GBModel,
            $DataGridView
        ))
        $Form.Add_Shown({$Form.Activate()})
        [void]$Form.ShowDialog()
    }

    function Prompt-MessageBox {
        param(
            [Parameter(Mandatory=$true)]
            [string]$Message,
            [Parameter(Mandatory=$true)]
            [string]$WindowTitle,
            [Parameter(Mandatory=$true)]
            [System.Windows.Forms.MessageBoxButtons]$Buttons = [System.Windows.Forms.MessageBoxButtons]::OK,
            [Parameter(Mandatory=$true)]
            [System.Windows.Forms.MessageBoxIcon]$Icon = [System.Windows.Forms.MessageBoxIcon]::None
        )
        return [System.Windows.Forms.MessageBox]::Show($Message, $WindowTitle, $Buttons, $Icon)
    }

    function Get-AssetInformation {
        param(
            [Parameter(Mandatory=$true)]
            [alias("SerialNumber")]
            [string]$ServiceTag
        )
        $WebService = New-WebServiceProxy -Uri "http://xserv.dell.com/services/AssetService.asmx?WSDL" -UseDefaultCredential
        $AssetInformation = $WebService.GetAssetInformation(([GUID]::NewGuid()).Guid,"Dell Warranty",$ServiceTag)
        $AssetHeaderData = $AssetInformation | Select-Object -Property AssetHeaderData
        $Entitlements = $AssetInformation | Select-Object -Property Entitlements
        foreach ($Entitlement in $Entitlements.Entitlements | Where-Object { ($_.ServiceLevelCode -ne "D") }) {
            if (($Entitlement.ServiceLevelDescription -ne $null) -or ($Entitlement.ServiceLevelCode -ne $null)) {
		        $DataGridView.Rows.Add(
			        $Entitlement.ServiceLevelDescription,
                    (Get-Date -Year ($Entitlement.StartDate.Year) -Month ($Entitlement.StartDate.Month) -Day ($Entitlement.StartDate.Day)).ToShortDateString(),
                    (Get-Date -Year ($Entitlement.EndDate.Year) -Month ($Entitlement.EndDate.Month) -Day ($Entitlement.EndDate.Day)).ToShortDateString(),
                    $Entitlement.DaysLeft, 
                    $Entitlement.EntitlementType
                )
            }
        }
    }

    function Get-DeviceComputerSystemInfo {
        param(
            [Parameter(Mandatory=$true)]
            [string]$ResourceID,
            [Parameter(Mandatory=$true)]
            [ValidateSet("Model","SerialNumber")]
            [string]$Property
        )
        switch ($Property) {
            "Model" { $DeviceQuery = "SELECT * FROM SMS_G_System_COMPUTER_SYSTEM WHERE ResourceID like '$($ResourceID)'" }
            "SerialNumber" { $DeviceQuery = "SELECT * FROM SMS_G_System_PC_BIOS WHERE ResourceID like '$($ResourceID)'" }
        }
        $DeviceComputerSystem = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Query $DeviceQuery -ComputerName $SiteServer -ErrorAction SilentlyContinue
        if ($DeviceComputerSystem -ne $null) {
            return $DeviceComputerSystem
        }
    }

    function Validate-DeviceHardwareInventory {
        param(
            [Parameter(Mandatory=$true)]
            [string]$ResourceID
        )
        $DeviceQuery = "SELECT * FROM SMS_G_System_COMPUTER_SYSTEM WHERE ResourceID like '$($ResourceID)'"
        $DeviceValidation = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Query $DeviceQuery -ComputerName $SiteServer -ErrorAction SilentlyContinue
        if ($DeviceValidation -eq $null) {
            $ButtonClicked = Prompt-MessageBox -Message "No valid hardware inventory found for $($Script:DeviceName)" -WindowTitle "Hardware inventory error" -Buttons OK -Icon Error
            if ($ButtonClicked -eq "OK") {
                $Form.Dispose()
                $Form.Close()
            }
        }
        else {
            return $true
        }
    }

    function Show-Warranty {
        $ButtonGet.Enabled = $false
        if ($DataGridView.RowCount -ge 1) {
            $DataGridView.Rows.Clear()
        }
        $TBModel.ResetText()
        $TBServiceTag.ResetText()
        if ((Validate-DeviceHardwareInventory -ResourceID $ResourceID) -eq $true) {
            $SerialNumber = Get-DeviceComputerSystemInfo -ResourceID $ResourceID -Property SerialNumber | Select-Object -ExpandProperty SerialNumber
            if ($SerialNumber.Length -eq 7) {
                $Model = Get-DeviceComputerSystemInfo -ResourceID $ResourceID -Property Model | Select-Object -ExpandProperty Model
                $TBServiceTag.Text = $SerialNumber
                $TBModel.Text = $Model
                [System.Windows.Forms.Application]::DoEvents()
                Get-AssetInformation -ServiceTag $SerialNumber
            }
            else {
                $ButtonClicked = Prompt-MessageBox -Message "A non-Dell service tag was found for $($Script:DeviceName)" -WindowTitle "Service tag error" -Buttons OK -Icon Error
                if ($ButtonClicked -eq "OK") {
                    $Form.Dispose()
                    $Form.Close()
                }
            }
        }
        $ButtonGet.Enabled = $true
    }

    #Assemblies
    Add-Type -AssemblyName "System.Drawing"
    Add-Type -AssemblyName "System.Windows.Forms"

    #Form
    $Form = New-Object System.Windows.Forms.Form    
    $Form.Size = New-Object System.Drawing.Size(600,315)  
    $Form.MinimumSize = New-Object System.Drawing.Size(600,315)
    $Form.MaximumSize = New-Object System.Drawing.Size(600,315)
    $Form.SizeGripStyle = "Hide"
    $Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHome + "\powershell.exe")
    $Form.Text = "Dell Warranty Status 2.0"

    #Group boxes
    $GBComputerName = New-Object System.Windows.Forms.GroupBox
    $GBComputerName.Location = New-Object System.Drawing.Size(10,10)
    $GBComputerName.Size = New-Object System.Drawing.Size(160,50)
    $GBComputerName.Text = "Device name"
    $GBServiceTag = New-Object System.Windows.Forms.GroupBox
    $GBServiceTag.Location = New-Object System.Drawing.Size(180,10)
    $GBServiceTag.Size = New-Object System.Drawing.Size(100,50)
    $GBServiceTag.Text = "Service tag"
    $GBModel = New-Object System.Windows.Forms.GroupBox
    $GBModel.Location = New-Object System.Drawing.Size(290,10)
    $GBModel.Size = New-Object System.Drawing.Size(170,50)
    $GBModel.Text = "Model"

    #Textboxes
    $TBComputerName = New-Object System.Windows.Forms.TextBox
    $TBComputerName.Location = New-Object System.Drawing.Size(20,30)
    $TBComputerName.Size = New-Object System.Drawing.Size(140,20)
    $TBComputerName.Text = $DeviceName
    $TBComputerName.ReadOnly = $true
    $TBServiceTag = New-Object System.Windows.Forms.TextBox
    $TBServiceTag.Location = New-Object System.Drawing.Size(190,30)
    $TBServiceTag.Size = New-Object System.Drawing.Size(80,20)
    $TBServiceTag.ReadOnly = $true
    $TBModel = New-Object System.Windows.Forms.TextBox
    $TBModel.Location = New-Object System.Drawing.Size(300,30)
    $TBModel.Size = New-Object System.Drawing.Size(150,20)
    $TBModel.ReadOnly = $true

    #Buttons
    $ButtonGet = New-Object System.Windows.Forms.Button
    $ButtonGet.Location = New-Object System.Drawing.Size(475,23)
    $ButtonGet.Size = New-Object System.Drawing.Size(100,30)
    $ButtonGet.Text = "Show Warranty"
    $ButtonGet.Add_Click({Show-Warranty})

    # Link
    $OpenLink = {[System.Diagnostics.Process]::Start("http://www.scconfigmgr.com")}
    $BlogLink = New-Object System.Windows.Forms.LinkLabel
    $BlogLink.Location = New-Object System.Drawing.Size(9,255) 
    $BlogLink.Size = New-Object System.Drawing.Size(150,25)
    $BlogLink.Text = "www.scconfigmgr.com"
    $BlogLink.Add_Click($OpenLink)

    #Gridview
    $DataGridView = New-Object System.Windows.Forms.DataGridView
    $DataGridView.Location = New-Object System.Drawing.Size(10,70)
    $DataGridView.Size = New-Object System.Drawing.Size(565,180)
    $DataGridView.AllowUserToAddRows = $false
    $DataGridView.AllowUserToDeleteRows = $false
    $DataGridView.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
    $DataGridView.ColumnCount = 5
    $DataGridView.ColumnHeadersVisible = $true
    $DataGridView.Columns[0].Name = "Warranty Type"
    $DataGridView.Columns[0].AutoSizeMode = "Fill"
    $DataGridView.Columns[1].Name = "Start Date"
    $DataGridView.Columns[1].AutoSizeMode = "Fill"
    $DataGridView.Columns[2].Name = "End Date"
    $DataGridView.Columns[2].AutoSizeMode = "Fill"
    $DataGridView.Columns[3].Name = "Days Left"
    $DataGridView.Columns[3].AutoSizeMode = "Fill"
    $DataGridView.Columns[4].Name = "Status"
    $DataGridView.Columns[4].AutoSizeMode = "Fill"
    $DataGridView.ColumnHeadersHeightSizeMode = "DisableResizing"
    $DataGridView.AllowUserToResizeRows = $false
    $DataGridView.RowHeadersWidthSizeMode = "DisableResizing"
    $DataGridView.RowHeadersVisible = $false
    $DataGridView.Anchor = "Top, Bottom, Left, Right"
    $DataGridView.Name = "DGVWarranty"
    $DataGridView.ReadOnly = $true
    $DataGridView.BackGroundColor = "White"
    $DataGridView.TabIndex = "5"

    #Load the form
    Load-Form
}