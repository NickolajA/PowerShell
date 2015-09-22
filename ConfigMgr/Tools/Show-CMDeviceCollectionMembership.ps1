[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$false, HelpMessage="Site server where the SMS Provider is installed")]
    [string]$SiteServer = "CAS01",
    [parameter(Mandatory=$false, HelpMessage="ResourceID of the device")]
    [string]$ResourceID = "16777224"
)
Begin {
    # Determine SiteCode from WMI
    try {
        Write-Verbose "Determining SiteCode for Site Server: '$($SiteServer)'"
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

    # Create IconExtractor class
    # Code from: http://social.technet.microsoft.com/Forums/en/winserverpowershell/thread/16444c7a-ad61-44a7-8c6f-b8d619381a27
    $IconExtractor = @"
    using System;
    using System.Drawing;
    using System.Runtime.InteropServices;

    namespace System {
	    public class IconExtractor {
            public static Icon Extract(string file, int number, bool largeIcon) {
                IntPtr large;
	            IntPtr small;
	            ExtractIconEx(file, number, out large, out small, 1);
	            try {
	                return Icon.FromHandle(largeIcon ? large : small);
	            }
	            catch {
	                return null;
	            }
            }
	        [DllImport("Shell32.dll", EntryPoint = "ExtractIconExW", CharSet = CharSet.Unicode, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
	        private static extern int ExtractIconEx(string sFile, int iIndex, out IntPtr piLargeVersion, out IntPtr piSmallVersion, int amountIcons);
	    }
    }
"@ # This row show not be indented or contain any spaces

    # Load Assemblies
    Add-Type -AssemblyName "System.Drawing"
    Add-Type -AssemblyName "System.Windows.Forms"
    Add-Type -TypeDefinition $IconExtractor -ReferencedAssemblies "System.Drawing"
}
Process {
    # Functions
    function Load-Form {
        $Form.Controls.AddRange(@(
            $TreeView,
            $GroupBox
        ))
	    $Form.Add_Shown({
            Build-TreeView -ResourceID $ResourceID
            $Form.Activate()
        })
	    [void]$Form.ShowDialog()
    }

    function Get-CollectionName {
        param(
            [parameter(Mandatory=$true)]
            [string]$CollectionID
        )
        $Collection = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer -Filter "CollectionID like '$($CollectionID)'"
        if ($Collection -ne $null) {
            return $Collection.Name
        }
    }

    function Set-NodeCollection {
        param(
            [parameter(Mandatory=$true)]
            [int]$ContainerNodeID,
            [parameter(Mandatory=$true)]
            $Node
        )
        $NodeCollections = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_ObjectContainerItem -ComputerName $SiteServer -Filter "ContainerNodeID = $($ContainerNodeID) AND ObjectType = 5000"
        foreach ($NodeCollection in $NodeCollections) {
            if ($NodeCollection.InstanceKey -in $DeviceCollectionIDs) {
                $CollectionName = Get-CollectionName -CollectionID $NodeCollection.InstanceKey
                $CollNode = $Node.Nodes.Add($CollectionName)
                $CollNode.ImageIndex = 2
                $CollNode.Expand()
                $Script:ExpandNode = $true
                #Expand-TreeNode -ParentNode $Node
            }
        }
    }

    function Expand-TreeNode {
        param(
            [parameter(Mandatory=$true)]
            $ParentNode
        )
        do {
            $Node = $ParentNode.Parent.Expand()
            Expand-TreeNode -ParentNode $Node
        }
        until ($Node.Parent -eq $null)
    }

    function Get-SubNode {
        param(
            [parameter(Mandatory=$true)]
            [int]$ParentContainerNodeID,
            [parameter(Mandatory=$true)]
            $ParentNode
        )
        $SubNodes = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_ObjectContainerNode -ComputerName $SiteServer -Filter "ParentContainerNodeID = $($ParentContainerNodeID) AND ObjectType = 5000"
        if ($SubNodes -ne $null) {
            foreach ($SubNode in ($SubNodes | Sort-Object -Property Name)) {
                $Script:ExpandNode = $false
                $Node = $ParentNode.Nodes.Add($SubNode.Name)
                $Node.ImageIndex = 1
                Get-SubNode -ParentContainerNodeID $SubNode.ContainerNodeID -ParentNode $Node
                Set-NodeCollection -ContainerNodeID $SubNode.ContainerNodeID -Node $Node
                if ($Script:ExpandNode -eq $true) {
                    $Node.Expand()
                }
            }
        }
    }

    function Build-TreeView {
        param(
            [parameter(Mandatory=$true)]
            $ResourceID
        )
        # Clear nodes
        $TreeView.Nodes.Clear()
        # Create the root node
        $RootNode = $TreeView.Nodes.Add("Root")
        $RootNode.ImageIndex = 1
        # Collection all CollectionIDs that the device is a member of
        $DeviceCollectionIDs = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_FullCollectionMembership -ComputerName $SiteServer -Filter "ResourceID like '$($ResourceID)'" | Select-Object -ExpandProperty CollectionID
        # Determine top level Container Node items for Device Collections
        $RootNodes = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_ObjectContainerNode -ComputerName $SiteServer -Filter "ParentContainerNodeID = 0 AND ObjectType = 5000"
        foreach ($Node in ($RootNodes | Sort-Object -Property Name)) {
            $CurrentNode = $RootNode.Nodes.Add($Node.Name)
            $CurrentNode.ImageIndex = 1
            Set-NodeCollection -ContainerNodeID $Node.ContainerNodeID -Node $CurrentNode
            Get-SubNode -ParentContainerNodeID $Node.ContainerNodeID -ParentNode $CurrentNode
        }
        $RootNode.Expand()
        #$TreeView.ExpandAll()
    }

    # Script variables
    $Script:ExpandNode = $false

    # Read images from Base64
    $BinaryFormatter = New-Object -TypeName System.Runtime.Serialization.Formatters.Binary.BinaryFormatter
	$MemoryStream = New-Object -TypeName System.IO.MemoryStream (,[byte[]][System.Convert]::FromBase64String(
        'AAEAAAD/////AQAAAAAAAAAMAgAAAFdTeXN0ZW0uV2luZG93cy5Gb3JtcywgVmVyc2lvbj00LjAu
        MC4wLCBDdWx0dXJlPW5ldXRyYWwsIFB1YmxpY0tleVRva2VuPWI3N2E1YzU2MTkzNGUwODkFAQAA
        ACZTeXN0ZW0uV2luZG93cy5Gb3Jtcy5JbWFnZUxpc3RTdHJlYW1lcgEAAAAERGF0YQcCAgAAAAkD
        AAAADwMAAABwCgAAAk1TRnQBSQFMAgEBBAEAAUABAAFAAQABEAEAARABAAT/AQkBAAj/AUIBTQE2
        AQQGAAE2AQQCAAEoAwABQAMAASADAAEBAQABCAYAAQgYAAGAAgABgAMAAoABAAGAAwABgAEAAYAB
        AAKAAgADwAEAAcAB3AHAAQAB8AHKAaYBAAEzBQABMwEAATMBAAEzAQACMwIAAxYBAAMcAQADIgEA
        AykBAANVAQADTQEAA0IBAAM5AQABgAF8Af8BAAJQAf8BAAGTAQAB1gEAAf8B7AHMAQABxgHWAe8B
        AAHWAucBAAGQAakBrQIAAf8BMwMAAWYDAAGZAwABzAIAATMDAAIzAgABMwFmAgABMwGZAgABMwHM
        AgABMwH/AgABZgMAAWYBMwIAAmYCAAFmAZkCAAFmAcwCAAFmAf8CAAGZAwABmQEzAgABmQFmAgAC
        mQIAAZkBzAIAAZkB/wIAAcwDAAHMATMCAAHMAWYCAAHMAZkCAALMAgABzAH/AgAB/wFmAgAB/wGZ
        AgAB/wHMAQABMwH/AgAB/wEAATMBAAEzAQABZgEAATMBAAGZAQABMwEAAcwBAAEzAQAB/wEAAf8B
        MwIAAzMBAAIzAWYBAAIzAZkBAAIzAcwBAAIzAf8BAAEzAWYCAAEzAWYBMwEAATMCZgEAATMBZgGZ
        AQABMwFmAcwBAAEzAWYB/wEAATMBmQIAATMBmQEzAQABMwGZAWYBAAEzApkBAAEzAZkBzAEAATMB
        mQH/AQABMwHMAgABMwHMATMBAAEzAcwBZgEAATMBzAGZAQABMwLMAQABMwHMAf8BAAEzAf8BMwEA
        ATMB/wFmAQABMwH/AZkBAAEzAf8BzAEAATMC/wEAAWYDAAFmAQABMwEAAWYBAAFmAQABZgEAAZkB
        AAFmAQABzAEAAWYBAAH/AQABZgEzAgABZgIzAQABZgEzAWYBAAFmATMBmQEAAWYBMwHMAQABZgEz
        Af8BAAJmAgACZgEzAQADZgEAAmYBmQEAAmYBzAEAAWYBmQIAAWYBmQEzAQABZgGZAWYBAAFmApkB
        AAFmAZkBzAEAAWYBmQH/AQABZgHMAgABZgHMATMBAAFmAcwBmQEAAWYCzAEAAWYBzAH/AQABZgH/
        AgABZgH/ATMBAAFmAf8BmQEAAWYB/wHMAQABzAEAAf8BAAH/AQABzAEAApkCAAGZATMBmQEAAZkB
        AAGZAQABmQEAAcwBAAGZAwABmQIzAQABmQEAAWYBAAGZATMBzAEAAZkBAAH/AQABmQFmAgABmQFm
        ATMBAAGZATMBZgEAAZkBZgGZAQABmQFmAcwBAAGZATMB/wEAApkBMwEAApkBZgEAA5kBAAKZAcwB
        AAKZAf8BAAGZAcwCAAGZAcwBMwEAAWYBzAFmAQABmQHMAZkBAAGZAswBAAGZAcwB/wEAAZkB/wIA
        AZkB/wEzAQABmQHMAWYBAAGZAf8BmQEAAZkB/wHMAQABmQL/AQABzAMAAZkBAAEzAQABzAEAAWYB
        AAHMAQABmQEAAcwBAAHMAQABmQEzAgABzAIzAQABzAEzAWYBAAHMATMBmQEAAcwBMwHMAQABzAEz
        Af8BAAHMAWYCAAHMAWYBMwEAAZkCZgEAAcwBZgGZAQABzAFmAcwBAAGZAWYB/wEAAcwBmQIAAcwB
        mQEzAQABzAGZAWYBAAHMApkBAAHMAZkBzAEAAcwBmQH/AQACzAIAAswBMwEAAswBZgEAAswBmQEA
        A8wBAALMAf8BAAHMAf8CAAHMAf8BMwEAAZkB/wFmAQABzAH/AZkBAAHMAf8BzAEAAcwC/wEAAcwB
        AAEzAQAB/wEAAWYBAAH/AQABmQEAAcwBMwIAAf8CMwEAAf8BMwFmAQAB/wEzAZkBAAH/ATMBzAEA
        Af8BMwH/AQAB/wFmAgAB/wFmATMBAAHMAmYBAAH/AWYBmQEAAf8BZgHMAQABzAFmAf8BAAH/AZkC
        AAH/AZkBMwEAAf8BmQFmAQAB/wKZAQAB/wGZAcwBAAH/AZkB/wEAAf8BzAIAAf8BzAEzAQAB/wHM
        AWYBAAH/AcwBmQEAAf8CzAEAAf8BzAH/AQAC/wEzAQABzAH/AWYBAAL/AZkBAAL/AcwBAAJmAf8B
        AAFmAf8BZgEAAWYC/wEAAf8CZgEAAf8BZgH/AQAC/wFmAQABIQEAAaUBAANfAQADdwEAA4YBAAOW
        AQADywEAA7IBAAPXAQAD3QEAA+MBAAPqAQAD8QEAA/gBAAHwAfsB/wEAAaQCoAEAA4ADAAH/AgAB
        /wMAAv8BAAH/AwAB/wEAAf8BAAL/AgAD//8A/wD/AP8ABQAk/wL0Bv8D9AP/DPQD/wp0BHMC/wp0
        BHMC/wPsAesBbQH3Av8BBwLsAesBcgFtAfQC/wwqA/8BdAGaA3kBegd5AXMC/wF0AZoDeQF6B3kB
        cwL/AfcBBwGYATQBVgH3Av8BvAHvAQcBVgE5AXIB9AL/AVEBHAF0A3MFUQEqA/8BeQKaBUsFmgF0
        Av8BeQyaAXQC/wHvAQcB7wJ4AZIC8QMHAXgBWAHrAfQC/wF0ApkCeQN0A1IBKgP/AXkCmgFLA1EB
        KgWaAXQC/wF5DJoBdAL/Ae8CBwHvAZIC7AFyAe0CBwLvAewB9AL/AZkCGgGgBJoCegF5AVID/wF5
        AaABmgF5AZkCeQFRBZoBdAL/AXkBoAuaAXQC/wEHAe8C9wLtAXgBNQF4Ae8D9wHsAfQC/wGZAhoB
        oASaAnoBeQFSA/8BeQGgAZoCmQGgAXkBUgWaAXQC/wF5AaALmgF0Av8BBwPvAfcB7QGYAXgBmQEH
        A+8B7AP/AZkCGgGgBJoCegF5AVID/wGZAaABmgGZAXkBmgF5AVIFmgF0Av8BmQGgC5oBdAL/AbwD
        8wG8AZIBBwHvAQcB8QLzAfIB7QP/AZkCGgGgBJoCegF5AVID/wGZAaABmgJ5AXQCUgWaAXQC/wGZ
        AaALmgF0Av8BvAEHAu8B9wPtAe8CBwLvAe0D/wGZARoBmgKZBnkBUgP/AZkBwwGaBHQBeQGgBJoB
        dAL/AZkBwwaaAaAEmgF0Av8CvAIHAvcCBwO8AgcBkgP/AZkBGgGZAxoDmgFSAXkBUgP/AZkBwwOa
        AqABmQWaAXQC/wGZAcMDmgKgAZkFmgF0Av8CvAHrAewCBwLzAfABvAHtAW0BBwH3A/8BmQEaAZkC
        9gTDAVIBeQFSA/8BmQWgAZoCdAV5Av8BmQWgAZoCdAV5Av8BvAEHApIB7wH3ApIB7wG8Ae8BkgHv
        AfcD/wGZAhoC9gTDAVgBeQFSA/8BmQGaBBoBdAOaApkBmgF5Av8BeQGaBBoBdAOaApkBmgF5Av8D
        9AHyAbwB8QK8Ae8B8AT0A/8BmQMaApkDeQFYAXkBUgP/ARsGeQGaAvYB1gG0AZoBmQL/AZkGeQGa
        AvYB1gG0AZoBeQX/AfQBvAH3ARIB7AHvAfAH/wFRARwBeQN0AVIEUQEqCf8BwwZ5AcMI/wGaBnkB
        mgX/AfQBvAEHAu8B9wHxB/8MUUL/AUIBTQE+BwABPgMAASgDAAFAAwABIAMAAQEBAAEBBgABARYA
        A///AAIACw=='
    ))

    # Forms
    $Form = New-Object -TypeName System.Windows.Forms.Form    
    $Form.Size = New-Object -TypeName System.Drawing.Size(350,450)  
    $Form.MinimumSize = New-Object -TypeName System.Drawing.Size(350,450)
    $Form.MaximumSize = New-Object -TypeName System.Drawing.Size([System.Int32]::MaxValue,[System.Int32]::MaxValue)
    $Form.SizeGripStyle = "Show"
    $Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHome + "\powershell.exe")
    $Form.Text = "Collection Membership"
    $Form.ControlBox = $true
    $Form.TopMost = $true

    # ImageList
    $ImageList = New-Object -TypeName System.Windows.Forms.ImageList
    $ImageList.ImageStream = $BinaryFormatter.Deserialize($MemoryStream)
    $ImageList.Images
	$BinaryFomatter = $null
	$MemoryStream = $null

    # TreeView
    $TreeView = New-Object -TypeName System.Windows.Forms.TreeView
    $TreeView.Location = New-Object -TypeName System.Drawing.Size(20,25)
    $TreeView.Size = New-Object -TypeName System.Drawing.Size(290,355)
    $TreeView.Anchor = "Top, Left, Bottom, Right"
    $TreeView.ImageList = $ImageList

    $GroupBox = New-Object -TypeName System.Windows.Forms.GroupBox
    $GroupBox.Location = New-Object -TypeName System.Drawing.Size(10,5)
    $GroupBox.Size = New-Object -TypeName System.Drawing.Size(310,385)
    $GroupBox.Anchor = "Top, Left, Bottom, Right"
    $GroupBox.Text = "Collections"

    # Load Form
    Load-Form
}