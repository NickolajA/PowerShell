[CmdletBinding(SupportsShouldProcess=$true)]
param(
[parameter(Mandatory=$true)]
$DriveLetter,
[parameter(Mandatory=$true)]
$ShareName,
[parameter(Mandatory=$true)]
$ADGroup,
[parameter(Mandatory=$false)]
[switch]$CreateDFS
)

$ErrorActionPreference = "Stop"

# Load assembly to get Active Directory domain
try {
    [System.Reflection.Assembly]::LoadWithPartialName("System.DirectoryServices") | Out-Null
}
catch {
    Write-Error $_.Exception
}

# Get Active Directory domain
try {
    $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain() | Select-Object -ExpandProperty Name
}
catch {
    Write-Error $_.Exception
}

# Install DFS Role and Management tools
if ($CreateDFS -eq $true) {
    $DFSRoles = @("FS-DFS-Namespace", "RSAT-DFS-Mgmt-Con")
    $DFSRoles | ForEach-Object {
        Install-WindowsFeature $_ | Out-Null
    }
}

# Create Source content folder structure
$FolderStructure = @(
    "$($DriveLetter)\$($ShareName)",
    "$($DriveLetter)\$($ShareName)\Apps",
    "$($DriveLetter)\$($ShareName)\Pkgs",
    "$($DriveLetter)\$($ShareName)\SUM",
    "$($DriveLetter)\$($ShareName)\SUM\ADRs",
    "$($DriveLetter)\$($ShareName)\OSD",
    "$($DriveLetter)\$($ShareName)\OSD\BootImages",
    "$($DriveLetter)\$($ShareName)\OSD\CSettings",
    "$($DriveLetter)\$($ShareName)\OSD\DriverSources",
    "$($DriveLetter)\$($ShareName)\OSD\DriverPackages",
    "$($DriveLetter)\$($ShareName)\OSD\OSImages",
    "$($DriveLetter)\$($ShareName)\OSD\MDT",
    "$($DriveLetter)\$($ShareName)\OSD\MDT\Settings",
    "$($DriveLetter)\$($ShareName)\OSD\MDT\Toolkit"
)
$FolderStructure | ForEach-Object {
    try {
        if (-not(Test-Path -Path $_ -ErrorAction SilentlyContinue)) {
            Write-Output "INFO: Creating folder $($_)"
            New-Item -Path $_ -ItemType Directory | Out-Null
        }
    }
    catch {
        Write-Error $_.Exception
    }
}

# Configure the Source content folder NTFS permissions
try {
    $ACLObject = Get-Acl "$($DriveLetter)\$($ShareName)"
    $ACLObject.SetAccessRuleProtection($True, $False)
    $RuleObject = New-Object System.Security.AccessControl.FileSystemAccessRule("$($ADGroup)","FullControl","ContainerInherit,ObjectInherit","None","Allow")
    $ACLObject.AddAccessRule($RuleObject)
    $RuleObject = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM","FullControl","ContainerInherit,ObjectInherit","None","Allow")
    $ACLObject.AddAccessRule($RuleObject)
    $RuleObject = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators","FullControl","ContainerInherit,ObjectInherit","None","Allow")
    $ACLObject.AddAccessRule($RuleObject)
    $RuleObject = New-Object System.Security.AccessControl.FileSystemAccessRule("Authenticated Users",@("ReadData","AppendData","Synchronize"),"None","None","Allow")
    $ACLObject.AddAccessRule($RuleObject)
    $RuleObject = New-Object System.Security.AccessControl.FileSystemAccessRule("CREATOR OWNER","FullControl","ContainerInherit,ObjectInherit","InheritOnly","Allow")
    Set-Acl "$($DriveLetter)\$($ShareName)" $ACLObject
}
catch {
    Write-Warning $_.Exception
}

# Share the Source content root folder
try {
    if ($ShareName.Substring(($ShareName.Length-1)) -match "$") {
        $Data = $ShareName.Substring(0,($ShareName.Length-1))
    }
    $SecurityDescriptor = ([WmiClass]"\\$($env:COMPUTERNAME)\root\cimv2:Win32_SecurityDescriptor").CreateInstance()
    $ACE = ([WmiClass]"\\$($env:COMPUTERNAME)\root\cimv2:Win32_ACE").CreateInstance()
    $Trustee = ([WmiClass]"\\$($env:COMPUTERNAME)\root\cimv2:Win32_Trustee").CreateInstance()
    $Trustee.Name = "Everyone"
    $Trustee.Domain = $null
    $ACE.AccessMask = 2032127
    $ACE.AceFlags = 3 
    $ACE.AceType = 0
    $ACE.Trustee = $Trustee 
    $SecurityDescriptor.DACL += $ACE.PsObject.BaseObject 
    $WMIConnection = [WmiClass]"\\$($env:COMPUTERNAME)\root\cimv2:Win32_Share"
    $ObjectParams = $WMIConnection.psbase.GetMethodParameters("Create")
    $ObjectParams.Path = "$($DriveLetter)\$($Data)$"
    $ObjectParams.Name = "$($Data)$"
    $ObjectParams.Type = 0
    $ObjectParams.MaximumAllowed = 100
    $ObjectParams.Access = $SecurityDescriptor
    $WMIConnection.InvokeMethod("Create",$ObjectParams,$null) | Out-Null
    $GetShareObject = Get-WmiObject -Namespace "root\cimv2" -Class "Win32_Share" | Where-Object { $_.Name -like "$($Data)$" }
    if ($GetShareObject) {
        Write-Output "INFO: Successfully shared \\$($env:COMPUTERNAME)\$($Data)$"
    }
}
catch {
    Write-Warning $_.Exception
}

# Create a new DFS Namespace root
if ($PSBoundParameters["CreateDFS"].IsPresent) {
    try {
        New-DfsnRoot -Path "\\$($Domain)\$($Data)$" -TargetPath "\\$($env:COMPUTERNAME)\$($Data)$" -Type DomainV2 -State Online | Out-Null
    }
    catch {
        Write-Warning $_.Exception
    }
}