[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$false, HelpMessage="Site server where the SMS Provider is installed")]
    [ValidateNotNullOrEmpty()]
    [string]$SiteServer,
    [parameter(Mandatory=$false, HelpMessage="Specify the PackageID or CI Unique Name of the object to check if referenced in any task sequence")]
    [ValidateNotNullOrEmpty()]
    [string]$ObjectID
)
Begin {
    # Load Assemblies
    Add-Type -AssemblyName "System.Drawing"
    Add-Type -AssemblyName "System.Windows.Forms"
    
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
        throw "Unable to determine SiteCode"
    }
}
Process {
    # Functions
    function Load-Form {
        $Form.Controls.AddRange(@(
            $DataGridView,
            $BlogLink
        ))
	    $Form.Add_Shown({Get-ReferencedTaskSequence ; $Form.Activate()})
	    [void]$Form.ShowDialog()
    }

    function Get-ReferencedTaskSequence {
        if ($ObjectID.Length -gt 8) {
            $ObjectID = $ObjectID.Split("/")[0] + "/" + $ObjectID.Split("/")[1]
        }
        $TaskSequences = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_TaskSequencePackageReference -ComputerName $SiteServer -Filter "ObjectID like '$($ObjectID)'"
        foreach ($TaskSequence in $TaskSequences) {
            $TaskSequenceData = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_TaskSequencePackage -ComputerName $SiteServer -Filter "PackageID like '$($TaskSequence.PackageID)'" | Select-Object -Property Name, PackageID
            $DataGridView.Rows.Add($TaskSequenceData.Name, $TaskSequenceData.PackageID)
        }
    }

    # Forms
    $Form = New-Object -TypeName System.Windows.Forms.Form    
    $Form.Size = New-Object -TypeName System.Drawing.Size(800,350)  
    $Form.MinimumSize = New-Object -TypeName System.Drawing.Size(800,350)
    $Form.MaximumSize = New-Object -TypeName System.Drawing.Size(800,350)
    $Form.SizeGripStyle = "Hide"
    $Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHome + "\powershell.exe")
    $Form.Text = "Referenced Task Sequence Information"
    $Form.ControlBox = $true
    $Form.TopMost = $true

    # Link
    $OpenLink = {[System.Diagnostics.Process]::Start("http://www.scconfigmgr.com")}
    $BlogLink = New-Object System.Windows.Forms.LinkLabel
    $BlogLink.Location = New-Object System.Drawing.Size(9,289) 
    $BlogLink.Size = New-Object System.Drawing.Size(150,25)
    $BlogLink.Text = "www.scconfigmgr.com"
    $BlogLink.Add_Click($OpenLink)

    #Gridview
    $DataGridView = New-Object System.Windows.Forms.DataGridView
    $DataGridView.Location = New-Object System.Drawing.Size(10,10)
    $DataGridView.Size = New-Object System.Drawing.Size(760,275)
    $DataGridView.AllowUserToAddRows = $false
    $DataGridView.AllowUserToDeleteRows = $false
    $DataGridView.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
    $DataGridView.ColumnCount = 2
    $DataGridView.ColumnHeadersVisible = $true
    $DataGridView.Columns[0].Name = "Task Sequence name"
    $DataGridView.Columns[0].AutoSizeMode = "Fill"
    $DataGridView.Columns[1].Name = "PackageID"
    $DataGridView.Columns[1].Width = "150"
    $DataGridView.ColumnHeadersHeightSizeMode = "DisableResizing"
    $DataGridView.AllowUserToResizeRows = $false
    $DataGridView.RowHeadersWidthSizeMode = "DisableResizing"
    $DataGridView.RowHeadersVisible = $false
    $DataGridView.Anchor = "Top, Bottom, Left, Right"
    $DataGridView.Name = "DGVWarranty"
    $DataGridView.ReadOnly = $true
    $DataGridView.BackGroundColor = "White"
    $DataGridView.TabIndex = "5"

    # Load Form
    Load-Form
}