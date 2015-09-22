[CmdletBinding()]
param(
    [parameter(Mandatory=$true)]
    [string]$SiteServer,
    [parameter(Mandatory=$true)]
    [string]$MDTServer,
    [parameter(Mandatory=$true)]
    [string]$MDTDatabase
)

# Functions
function Load-Window {
    if ((Connect-CMSiteServer -CMSiteServer $SiteServer) -eq $true) {
        Connect-MDTDatabase -MDTServer $MDTServer -MDTDatabase $MDTDatabase
        if ($Global:MDTSQLConnection.State -like "Open") {
            Get-MDTRoles
            Get-CMCollections
            $SyncHash.Window.ShowDialog() | Out-Null
        }
        else {
            foreach ($Control in $SyncHash.Keys) {
                $SyncHash.$Control.IsEnabled = $false
            }
        }
    }
    else {
        foreach ($Control in $SyncHash.Keys) {
            $SyncHash.$Control.IsEnabled = $false
        }
    }
}

function Error-Provider {
    param(
    [parameter(Mandatory=$true)]
    $Control,
    [parameter(Mandatory=$true)]
    $Property,
    [parameter(Mandatory=$true)]
    [ValidateSet("Normal","Error")]
    $Option
    )
    if ($Option -like "Error") {
        $Control.$Property = "#FFFF5D5D"
    }
    if ($Option -like "Normal") {
        $Control.$Property = "#FFFFFF"
    }
}

function Clear-Form {
    Set-ProgressBarValue -Value Minimum
    Set-StatusBarText -Text ""
    $ComboBoxMDTRole.SelectedIndex = 0
    $ComboBoxCMCollection.SelectedIndex = 0
    $TextBoxComputerName.Clear()
    $TextBoxMACAddress.Clear()
    $TextBoxPrimaryUser.Clear()
    if ($TextBoxComputerName.Background -like "#FFFF5D5D") {
        $TextBoxComputerName.Background = "#FFFFFFFF"
    }
    if ($TextBoxMACAddress.Background -like "#FFFF5D5D") {
        $TextBoxMACAddress.Background = "#FFFFFFFF"
    }
    if ($TextBoxPrimaryUser.Background -like "#FFFF5D5D") {
        $TextBoxPrimaryUser.Background = "#FFFFFFFF"
    }
}

function Load-ComboBox {
    param(
    [parameter(Mandatory=$true)]
    [System.Windows.Controls.ComboBox]$ComboBox,
    [parameter(Mandatory=$true)]
    $Items,
    [parameter(Mandatory=$false)]
    [string]$SelectedIndex,
    [parameter(Mandatory=$false)]
    [switch]$Append
    )
    if (-not($PSBoundParameters["Append"])) {
        $ComboBox.Items.Clear()
    }
    if ($Items -is [array]) {
        foreach ($Item in $Items) {
            $ComboBox.Items.Add($Item) | Out-Null
        }
    }
    else {
        $ComboBox.Items.Add($Items) | Out-Null
    }
    if ($PSBoundParameters["SelectedIndex"]) {
        $ComboBox.SelectedIndex = $SelectedIndex
    }
}

function Set-ToolTipText {
    param(
    [parameter(Mandatory=$true)]
    $Control,
    [parameter(Mandatory=$true)]
    [ValidateSet("ToolTip")]
    $Property,
    [parameter(Mandatory=$true)]
    $Text
    )
    $Control.$Property = "$($Text)"
}

function Set-Controls {
    param(
    [parameter(Mandatory=$true)]
    [ValidateSet("True","False")]
    [bool]$IsEnabled
    )
    foreach ($Control in $SyncHash.Keys) {
        $SyncHash.$Control.IsEnabled = $IsEnabled
    }
}

function Set-StatusBarText {
    param(
    [parameter(Mandatory=$true)]
    $Text
    )
    $LabelStatusBar.Content = "$($Text)"
}

function Set-ProgressBarValue {
    param(
    [parameter(Mandatory=$true)]
    [ValidateSet("Increase","Decrease","Maximum","Minimum")]
    $Value
    )
    Begin {
        $MaxValue = $StatusBarProgressBarItem.Content.Maximum
        $MinValue = $StatusBarProgressBarItem.Content.Minimum
        $CurrentValue = $StatusBarProgressBarItem.Content.Value
    }
    Process {
        switch ($Value) {
            "Increase" {
                $CurrentValue++
                if ($CurrentValue -ge $MaxValue) {
                    $StatusBarProgressBarItem.Content.Value = "$($MaxValue)"
                }
                else {
                    $StatusBarProgressBarItem.Content.Value = "$($CurrentValue)"
                }
            }
            "Decrease" {
                if ($CurrentValue -ne $MinValue) {
                     $CurrentValue--
                     $StatusBarProgressBarItem.Content.Value = "$($CurrentValue)"
                }
            }
            "Maximum" { 
                $StatusBarProgressBarItem.Content.Value = "$($MaxValue)"
            }
            "Minimum" {
                $StatusBarProgressBarItem.Content.Value = "$($MinValue)"
            }
        }
    }
}

function Connect-CMSiteServer {
    param(
    [parameter(Mandatory=$true)]
    [string]$CMSiteServer
    )
    $ConnectSMSProvider = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $CMSiteServer -ErrorAction SilentlyContinue
    if (($ConnectSMSProvider | Measure-Object).Count -ge 1) {
        foreach ($Provider in $ConnectSMSProvider) {
            if ($Provider.ProviderForLocalSite -eq $true) {
                return $true
            }
        }
    }
    else {
        Write-Error -Message "Unable to connect to SMS Provider at '$($CMSiteServer)' - Namespace not found"
        return $false
    }
}

function Connect-MDTDatabase {
    param(
    [parameter(Mandatory=$true)]
    [string]$MDTServer,
    [parameter(Mandatory=$true)]
    [string]$MDTDatabase,
    [parameter(Mandatory=$false)]
    [string]$MDTInstance = ""
    )
    if ($Instance.Length -ge 1) {
        $MDTSQLConnectionString = "Server=$($MDTServer)\$($MDTInstance); Database='$($MDTDatabase)'; Integrated Security=True"
    }
    else {
        $MDTSQLConnectionString = "Server=$($MDTServer); Database='$($MDTDatabase)'; Integrated Security=True"
    }
    try {
        $Global:MDTSQLConnection = New-Object System.Data.SqlClient.SqlConnection
        $Global:MDTSQLConnection.ConnectionString = $MDTSQLConnectionString
        $Global:MDTSQLConnection.Open()
    }
    catch {
        Write-Error -Message "Unable to connect to: '$($MDTServer)' - Possible cause: current user does not have sysadmin permission in the database"
    }
}

function Close-MDTDatabase {
    if ($Global:MDTSQLConnection.State -like "Open") {
        $Global:MDTSQLConnection.Close()
    }
}

function Get-MDTRoles {
    if ($MDTSQLConnection.State -like "Open") {
        $MDTRoleQuery = "SELECT Role FROM RoleIdentity"
        $SQLDataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter($MDTRoleQuery, $Global:MDTSQLConnection)
        $SQLDataset = New-Object System.Data.DataSet
        $Execute = $SQLDataAdapter.Fill($SQLDataset, "Roles")
        $MDTRoles = $SQLDataset.Tables[0].Rows | Select-Object -ExpandProperty Role | Sort-Object
        Load-ComboBox -ComboBox $ComboBoxMDTRole -Items $MDTRoles -SelectedIndex 0
    }
}

function Get-CMSiteCode {
    try {
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                return $SiteCodeObject.SiteCode
            }
        }
    }
    catch [Exception] {
        Throw "Unable to determine SiteCode"
    }
}

function Get-CMCollections {
    $Collections = Get-WmiObject -Namespace "root\SMS\site_$(Get-CMSiteCode)" -Class SMS_Collection -ComputerName $SiteServer -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    $SortedCollections = $Collections | Sort-Object
    Load-ComboBox -ComboBox $ComboBoxCMCollection -Items $SortedCollections -SelectedIndex 0
}

function Get-CMPrimaryUser {
    param(
    [parameter(Mandatory=$true)]
    [string]$SiteServer,
    [parameter(Mandatory=$true)]
    [string]$SiteCode,
    [parameter(Mandatory=$true)]
    [string]$UserName
    )
    $UserName = $UserName.Replace("\","\\")
    $PrimaryUser = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_R_User -ComputerName $SiteServer -Filter "(UserName like '%$($UserName)%') OR (UniqueUserName like '$($UserName)%') OR (FullUserName like '%$($UserName)%')" -ErrorAction SilentlyContinue
    if (($PrimaryUser | Measure-Object).Count -eq 1) {
        $TextBoxPrimaryUser.Background = "#FFFFFF"
        $TextBoxPrimaryUser.Text = $PrimaryUser.UniqueUserName
        $ButtonPrimaryUserCheck.IsEnabled = $false
        $Global:PrimaryUserValidated = $true
    }
    elseif (($PrimaryUser | Measure-Object).Count -gt 1) {
        $TextBoxPrimaryUser.Background = "#FFFFFF"
        $TextBoxPrimaryUser.Text = $PrimaryUser[0].UniqueUserName
        $ButtonPrimaryUserCheck.IsEnabled = $false
        $Global:PrimaryUserValidated = $true
    }
    else {
        Error-Provider -Control $TextBoxPrimaryUser -Property "Background" -Option Error
        Set-ToolTipText -Control $TextBoxPrimaryUser -Property "ToolTip" -Text "ERROR: Specified user name was not found"
        $Global:PrimaryUserValidated = $false
    }
}

function New-MDTComputer {
    param(
    [parameter(Mandatory=$true)]
    [string]$MACAddress,
    [parameter(Mandatory=$true)]
    [string]$Description,
    [parameter(Mandatory=$true)]
    [string]$OSDComputerName
    )
    Set-StatusBarText -Text "Creating Computer Identity in the MDT database"
    $MDTSQLIdentityCommand = "INSERT INTO ComputerIdentity (AssetTag, SerialNumber, MacAddress, UUID, Description) VALUES ('$($AssetTag)', '$($SerialNumber)', '$($MACAddress)', '$($UUID)', '$($Description)') SELECT @@IDENTITY"
    $IdentityCommand = New-Object System.Data.SqlClient.SqlCommand($MDTSQLIdentityCommand, $Global:MDTSQLConnection)
    $Identity = $IdentityCommand.ExecuteScalar()
    Set-ProgressBarValue -Value Increase
    Set-StatusBarText -Text "Associating Computer name with Computer Identity"
    $MDTSQLSettingsCommand = "INSERT INTO Settings (Type, ID, OSDComputerName) VALUES ('C', '$($Identity)', '$($OSDComputerName)')"
    $SettingsCommand = New-Object System.Data.SqlClient.SqlCommand($MDTSQLSettingsCommand, $Global:MDTSQLConnection)
    $Execute = $SettingsCommand.ExecuteScalar()
    Set-ProgressBarValue -Value Increase
    Set-StatusBarText -Text "Associating Computer Indentity with specified Role"
    $MDTSQLSettingsRolesCommand = "INSERT INTO Settings_Roles (Type, ID, Sequence, Role) VALUES ('C', '$($Identity)', '1', '$($ComboBoxMDTRole.SelectedItem)')"
    $SettingsRolesCommand = New-Object System.Data.SqlClient.SqlCommand($MDTSQLSettingsRolesCommand, $Global:MDTSQLConnection)
    $Update = $SettingsRolesCommand.ExecuteScalar()
    Set-ProgressBarValue -Value Increase
}

function New-CMComputer {
    param(
    [parameter(Mandatory=$true)]
    [string]$SiteServer,
    [parameter(Mandatory=$true)]
    [string]$SiteCode,
    [parameter(Mandatory=$true)]
    [string]$CollectionName,
    [parameter(Mandatory=$true)]
    [string]$ComputerName,
    [parameter(Mandatory=$true)]
    [string]$MACAddress
    )
    Set-ProgressBarValue -Value Increase
    $CollectionQuery = Get-WmiObject -Namespace "Root\SMS\Site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer -Filter "Name='$($CollectionName)'"
    $WMIClass = ([WMIClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_Site")
    $NewEntry = $WMIClass.psbase.GetMethodParameters("ImportMachineEntry")
    $NewEntry.MACAddress = $MACAddress
    $NewEntry.NetbiosName = $ComputerName
    $NewEntry.OverwriteExistingRecord = $True
    $Resource = $WMIClass.psbase.InvokeMethod("ImportMachineEntry",$NewEntry,$null)
    if ($Resource.ReturnValue -eq 0) {
        Set-ProgressBarValue -Value Increase
        Set-StatusBarText -Text "Imported machine entry to Configmgr"
        $NewRule = ([WMIClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_CollectionRuleDirect").CreateInstance()
        $NewRule.ResourceClassName = "SMS_R_SYSTEM"
        $NewRule.ResourceID = $Resource.ResourceID
        $NewRule.Rulename = $ResourceName
        $AddMembership = $CollectionQuery.AddMemberShipRule($NewRule)
        if ($AddMembership.ReturnValue -eq 0) {
            Set-ProgressBarValue -Value Increase
            Set-StatusBarText -Text "Added machine entry to collection"
        }
        else {
            Set-ProgressBarValue -Value Maximum
            Set-StatusBarText -Text "ERROR: Failed to add machine entry to collection"
        }
    }
    else {
        Set-ProgressBarValue -Value Maximum
        Set-StatusBarText -Text "ERROR: Failed to import machine entry"
    }
}

function Create-UDA {
    param(
    [parameter(Mandatory=$true)]
    [string]$SiteServer,
    [parameter(Mandatory=$true)]
    [string]$SiteCode,
    [parameter(Mandatory=$true)]
    [string]$DeviceName,
    [parameter(Mandatory=$true)]
    [string]$UserName
    )
    $CMDeviceResourceID = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_R_System -ComputerName $SiteServer -Filter "Name like '$($DeviceName)'" | Select-Object -ExpandProperty ResourceID
    $UserName = $UserName.Replace("\","\\")
    $CMUserName = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_R_User -ComputerName $SiteServer -Filter "UniqueUserName like '%$($UserName)%'" | Select-Object -ExpandProperty Name
    [int]$SourceId = 2
    $WMIClass = [WmiClass]"\\$($SiteServer)\root\SMS\site_$($SiteCode):SMS_UserMachineRelationship"
    $NewRelation = $WMIClass.psbase.GetMethodParameters("CreateRelationship")
    $NewRelation.MachineResourceId = $CMDeviceResourceID
    $NewRelation.SourceId = $SourceId
    $NewRelation.TypeId = 1
    $NewRelation.UserAccountName = $CMUserName
    $Invoke = $WMIClass.psbase.InvokeMethod("CreateRelationship", $NewRelation, $null)
    if ($Invoke.ReturnValue -eq 0) {
        Set-ProgressBarValue -Value Increase
        Set-StatusBarText -Text "Created UDA relationship"
    }
    else {
        Set-ProgressBarValue -Value Maximum
        Set-StatusBarText -Text "ERROR: Failed to create an UDA relationship"
    }
}

function Update-CollectionMembership {
    param(
    [parameter(Mandatory=$true)]
    [string]$SiteServer,
    [parameter(Mandatory=$true)]
    [string]$SiteCode,
    [parameter(Mandatory=$true)]
    [string]$CollectionName
    )
    $CollectionQuery = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer -Filter "Name like '$($CollectionName)'" -ErrorAction SilentlyContinue
    $Refresh = $CollectionQuery.RequestRefresh()
    if ($Refresh.ReturnValue -eq 0) {
        Set-StatusBarText -Text "Updated '$($CollectionName)' membership"
    }
    else {
        Set-StatusBarText -Text "ERROR: Failed to update '$($CollectionName)'"
    }
}

function Validate-Data {
    if ($TextBoxPrimaryUser.Text.Length -ge 1) {
        if (($TextBoxComputerName.Text.Length -le 15) -and ($TextBoxComputerName.Text.Length -ge 1) -and ($TextBoxMACAddress.Text -match ('^[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}$')) -and ($TextBoxPrimaryUser.Text.Length -ge 3) -and ($Global:PrimaryUserValidated -eq $true)) {
            if ((Get-WmiObject -Namespace "root\SMS\site_$(Get-CMSiteCode)" -Class SMS_R_System -ComputerName $SiteServer -Filter "Name like '$($TextBoxComputerName.Text)'" -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
                Set-StatusBarText -Text "Initiating"
                Create-PrestagedComputer
            }
            else {
                Error-Provider -Control $TextBoxComputerName -Property "Background" -Option Error
                Set-StatusBarText -Text "ERROR: Computer name already exists"
            }
        }
        else {
            Set-StatusBarText -Text "ERROR: Incomplete form data submitted"
        }
    }
    else {
        if (($TextBoxComputerName.Text.Length -le 15) -and ($TextBoxMACAddress.Text -match ('^[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}$'))) {
            Set-StatusBarText -Text "Initiating"
            Create-PrestagedComputer
        }
        else {
            Set-StatusBarText -Text "ERROR: Incomplete form data submitted"
        }
    }
}

function Create-PrestagedComputer {
    Set-Controls -IsEnabled $false
    New-CMComputer -SiteServer $SiteServer -SiteCode $(Get-CMSiteCode) -CollectionName $ComboBoxCMCollection.SelectedItem -ComputerName $TextBoxComputerName.Text -MACAddress $TextBoxMACAddress.Text
    New-MDTComputer -MACAddress "$($TextBoxMACAddress.Text)" -Description "$($TextBoxComputerName.Text)" -OSDComputerName "$($TextBoxComputerName.Text)"
    if ($Global:PrimaryUserValidated -eq $true) {
        Create-UDA -SiteServer $SiteServer -SiteCode $(Get-CMSiteCode) -DeviceName $TextBoxComputerName.Text -UserName $TextBoxPrimaryUser.Text
    }
    Update-CollectionMembership -SiteServer $SiteServer -SiteCode $(Get-CMSiteCode) -CollectionName "All Systems"
    Set-StatusBarText -Text "Prestage sequence completed"
    Set-Controls -IsEnabled $true
}

# Global variables
$Global:PrimaryUserValidated = $null

# XAML layout
[xml]$XAML = @" 
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="Prestage Computer 1.0.0" Height="453" Width="533" ResizeMode="NoResize">
    <Grid>
        <GroupBox x:Name="GroupBoxComputerName" Header="Computer Details (Required)" HorizontalAlignment="Left" Margin="10,10,0,0" VerticalAlignment="Top" Height="104" Width="498"/>
        <GroupBox x:Name="GroupBoxMDTRole" Header="MDT Role (Required)" HorizontalAlignment="Left" Margin="10,193,0,0" VerticalAlignment="Top" Height="69" Width="498"/>
        <GroupBox x:Name="GroupBoxCMCollection" Header="ConfigMgr Collection (Required)" HorizontalAlignment="Left" Margin="10,267,0,0" VerticalAlignment="Top" Height="69" Width="498"/>
        <GroupBox x:Name="GroupBoxPrimaryUser" Header="Primary User (Optional)" HorizontalAlignment="Left" Margin="10,119,0,0" VerticalAlignment="Top" Height="69" Width="498"/>
        <Button x:Name="ButtonCreate" Content="Create" HorizontalAlignment="Left" Margin="430,353,0,0" VerticalAlignment="Top" Width="75" RenderTransformOrigin="0.173,0.15" TabIndex="7"/>
        <Button x:Name="ButtonPrimaryUserCheck" Content="Check" HorizontalAlignment="Left" Margin="340.333,147.33,0,0" VerticalAlignment="Top" Width="75" TabIndex="4"/>
        <Button x:Name="ButtonClear" Content="Clear" HorizontalAlignment="Left" Margin="340,353,0,0" VerticalAlignment="Top" Width="75" TabIndex="8"/>
        <TextBox x:Name="TextBoxComputerName" HorizontalAlignment="Left" Height="23" Margin="132.999,38.333,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="190" ToolTip="Specify a computer name, maximum of 15 characters (Required)" TabIndex="1"/>
        <TextBox x:Name="TextBoxMACAddress" HorizontalAlignment="Left" Height="23" Margin="132.999,69.333,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="190" ToolTip="Specify a MAC address in the following format: 00:00:5C:E4:22:01 (Required)" TabIndex="2"/>
        <TextBox x:Name="TextBoxPrimaryUser" HorizontalAlignment="Left" Height="23" Margin="133,146,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="190" ToolTip="Specify a user name that will be associated with this computer (Optional)" TabIndex="3"/>
        <Label x:Name="LabelComputerName" Content="Computer name:" HorizontalAlignment="Left" Margin="17.332,35.333,0,0" VerticalAlignment="Top" Width="101.333"/>
        <Label x:Name="LabelMACAddress" Content="MAC Address:" HorizontalAlignment="Left" Margin="17.332,66.333,0,0" VerticalAlignment="Top"/>
        <Label x:Name="LabelMDTRole" Content="Select role:" HorizontalAlignment="Left" Margin="20,219,0,0" VerticalAlignment="Top" Width="110" Height="28"/>        
        <Label x:Name="LabelCMCollection" Content="Select collection:" HorizontalAlignment="Left" Margin="20,293,0,0" VerticalAlignment="Top"/>
        <Label x:Name="LabelPrimaryUser" Content="Primary User:" HorizontalAlignment="Left" Margin="18,144,0,0" VerticalAlignment="Top" Width="101"/>
        <ComboBox x:Name="ComboBoxMDTRole" HorizontalAlignment="Left" Margin="135,221,0,0" VerticalAlignment="Top" Width="190" TabIndex="5"/>
        <ComboBox x:Name="ComboBoxCMCollection" HorizontalAlignment="Left" Margin="135,294,0,0" VerticalAlignment="Top" Width="290" TabIndex="6"/>
        <StatusBar x:Name="StatusBar" HorizontalAlignment="Left" Height="22" Margin="0,392,0,0" VerticalAlignment="Top" Width="529" BorderBrush="#FFABADB3" BorderThickness="0,1,0,0">
            <StatusBar.ItemsPanel>
                <ItemsPanelTemplate>
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="122"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                    </Grid>
                </ItemsPanelTemplate>
            </StatusBar.ItemsPanel>
            <StatusBarItem Margin="11,0,0,0">
                <ProgressBar Name="ProgressBarItem" Value="0" Width="150" Height="12"/>
            </StatusBarItem>
        </StatusBar>
        <Label x:Name="LabelStatusBar" Content="" HorizontalAlignment="Left" Margin="127,390,0,0" Width="300" Height="28" VerticalAlignment="Top" FontSize="11"/>
    </Grid>
</Window>
"@

# Load Windows Presentation Framework assembly
[void][System.Reflection.Assembly]::LoadWithPartialName("PresentationFramework")

# Load XAML data
$XAMLReader = New-Object -TypeName System.Xml.XmlNodeReader($XAML)

# Create a synchronized hashtable
$SyncHash = [hashtable]::Synchronized(@{}) 
$SyncHash.Window = [Windows.Markup.XamlReader]::Load($XAMLReader)

# Specify controls
$LabelComputerName = $SyncHash.LabelComputerName = $SyncHash.Window.FindName("LabelComputerName") 
$LabelMACAddress = $SyncHash.LabelMACAddress = $SyncHash.Window.FindName("LabelMACAddress") 
$LabelMDTRole = $SyncHash.LabelMDTRole = $SyncHash.Window.FindName("LabelMDTRole")
$LabelCMCollection = $SyncHash.LabelCMCollection = $SyncHash.Window.FindName("LabelCMCollection")
$LabelStatusBar = $SyncHash.LabelStatusBar = $SyncHash.Window.FindName("LabelStatusBar")
$TextBoxComputerName = $SyncHash.TextBoxComputerName = $SyncHash.Window.FindName("TextBoxComputerName") 
$TextBoxMACAddress = $SyncHash.TextBoxMACAddress = $SyncHash.Window.FindName("TextBoxMACAddress")
$TextBoxPrimaryUser = $SyncHash.TextBoxPrimaryUser = $SyncHash.Window.FindName("TextBoxPrimaryUser")
$ButtonCreate = $SyncHash.ButtonCreate = $SyncHash.Window.FindName("ButtonCreate") 
$ButtonClear = $SyncHash.ButtonClear = $SyncHash.Window.FindName("ButtonClear")
$ButtonPrimaryUserCheck = $SyncHash.ButtonPrimaryUserCheck = $SyncHash.Window.FindName("ButtonPrimaryUserCheck")
$ComboBoxMDTRole = $SyncHash.ComboBoxMDTRole = $SyncHash.Window.FindName("ComboBoxMDTRole")
$ComboBoxCMCollection = $SyncHash.ComboBoxCMCollection = $SyncHash.Window.FindName("ComboBoxCMCollection")
$StatusBar = $SyncHash.StatusBar = $SyncHash.Window.FindName("StatusBar")
$StatusBarProgressBarItem = $StatusBar.Items[0]

# Control properties
$StatusBarProgressBarItem.Content.Maximum = "6"
$StatusBarProgressBarItem.Content.Minimum = "0"
$ComboBoxMDTRole.MaxDropDownHeight = "245"
$ComboBoxCMCollection.MaxDropDownHeight = "245"

# Control Events
$ButtonCreateEvent = $ButtonCreate.Add_Click({
    Validate-Data
})
$ButtonClearEvent = $ButtonClear.Add_Click({
    Clear-Form
})
$ButtonPrimaryUserCheckEvent = $ButtonPrimaryUserCheck.Add_Click({
    if ($TextBoxPrimaryUser.Text.Length -ge 1) {
        Get-CMPrimaryUser -SiteServer $SiteServer -SiteCode $(Get-CMSiteCode) -UserName $TextBoxPrimaryUser.Text
    }
})
$TextBoxComputerNameEvent = $TextBoxComputerName.Add_TextChanged({
    if ($TextBoxComputerName.Text.Length -gt "15") {
        Error-Provider -Control $TextBoxComputerName -Property "Background" -Option Error
        Set-ToolTipText -Control $TextBoxComputerName -Property "ToolTip" -Text "ERROR: You can only enter a maximum of 15 characters"
    }
    else {
        Error-Provider -Control $TextBoxComputerName -Property "Background" -Option Normal
        Set-ToolTipText -Control $TextBoxComputerName -Property "ToolTip" -Text "Specify a computer name, maximum of 15 characters (Required)"
    }
})
$TextBoxMACAddressEvent = $TextBoxMACAddress.Add_TextChanged({
    if ($TextBoxMACAddress.Text -notmatch ('^[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}$')) {
        Error-Provider -Control $TextBoxMACAddress -Property "Background" -Option Error
        Set-ToolTipText -Control $TextBoxMACAddress -Property "ToolTip" -Text "ERROR: You need to enter a valid MAC Address in the correct format"
    }
    else {
        Error-Provider -Control $TextBoxMACAddress -Property "Background" -Option Normal
        Set-ToolTipText -Control $TextBoxMACAddress -Property "ToolTip" -Text "Specify a MAC address in the following format: 00:00:5C:E4:22:01 (Required)"
    }
})
$TextBoxPrimaryUserEvent = $TextBoxPrimaryUser.Add_GotFocus({
    if ($TextBoxPrimaryUser.Background.Color -like "#FFFF5D5D") {
        $TextBoxPrimaryUser.Background = "#FFFFFFFF"
        Set-ToolTipText -Control $TextBoxPrimaryUser -Property "ToolTip" -Text "Specify a user name that will be associated with this computer (Optional)"
    }
    if ($ButtonPrimaryUserCheck.IsEnabled -eq $false) {
        $ButtonPrimaryUserCheck.IsEnabled = $true
    }
})

# Load window
Load-Window