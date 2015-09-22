#========================================================================
# Created on:   2014-01-14
# Created by:   Nickolaj Andersen
# Version:		1.2.1  
# Twitter:		@NickolajA
# Blog:			www.scconfigmgr.com
#========================================================================

#Functions
function Validate-OS {
    $ProductType = Get-WmiObject -Namespace "Root\CIMV2" -Class Win32_OperatingSystem | Select-Object -ExpandProperty ProductType
	if ($ProductType -eq 3) {
		Load-Form
	}
	else {
        if ($ProductType -eq 2) {
		    $ShellObject = New-Object -ComObject Wscript.Shell
		    $PopupValidate = $ShellObject.Popup("The detected server is a Domain Controller.`nThis program is not supported on this platform.",0,"Non-supported System",0)	
        }
        if ($ProductType -eq 1) {
		    $ShellObject = New-Object -ComObject Wscript.Shell
		    $PopupValidate = $ShellObject.Popup("The detected operating system is a Workstation OS.`nThis program is not supported on this platform.",0,"Non-supported System",0)	
        }
	}
}

function Load-Form {
	if ($host.Version -like "2.0") {
		Import-Module ServerManager
	}
	$Form.Controls.Add($LabelHeader)
	$Form.Controls.Add($BlogLink)
	$Form.Controls.Add($ButtonSecondarySite)
	$Form.Controls.Add($ButtonPrimarySite)
	$Form.Controls.Add($ButtonCAS)
	$Form.Controls.Add($ButtonMP)
    $Form.Controls.Add($ButtonAppCat)
	$Form.Controls.Add($ButtonDP)
    $Form.Controls.Add($ButtonEP)
	$Form.Controls.Add($ButtonExtendActiveDirectory)
	$Form.Controls.Add($ButtonWSUS)
	$Form.Controls.Add($ButtonADK)
    $Form.Controls.Add($ButtonSystemManagementContainer)
	$Form.Controls.Add($GBSites)
	$Form.Controls.Add($GBSiteSystemRoles)
	$Form.Controls.Add($GBOther)
	$Form.Add_Shown({$Form.Activate()})
	[void] $Form.ShowDialog()	
}

function Load-Start {
    $Form.Controls.Clear()
	$ProgressBar.Value = 0
	$TextBoxDC.Enabled = $true
    $TextBoxSMCRemote.Enabled = $false
    $CBSMCCreate.Checked = $false
    $TextBoxSMCRemote.ResetText()
    $TabControlSMC.Controls.Remove($TabPageSMCComputer)
    $TabControlSMC.Controls.Remove($TabPageSMCGroup)
    if ($ButtonBack.Location.Y -eq 385) {
        $ButtonBack.Location = New-Object System.Drawing.Size(563,420)
    }
    if ($OutputBox.Location.X -eq 380) {
        $OutputBox.Location = New-Object System.Drawing.Size(10,10)
        $OutputBox.Size = New-Object System.Drawing.Size(763,350)
    }
	$Form.Controls.Add($LabelHeader)
	$Form.Controls.Add($BlogLink)
	$Form.Controls.Add($ButtonSecondarySite)
	$Form.Controls.Add($ButtonPrimarySite)
	$Form.Controls.Add($ButtonCAS)
	$Form.Controls.Add($ButtonMP)
    $Form.Controls.Add($ButtonAppCat)
	$Form.Controls.Add($ButtonDP)
    $Form.Controls.Add($ButtonEP)
	$Form.Controls.Add($ButtonExtendActiveDirectory)
	$Form.Controls.Add($ButtonWSUS)
	$Form.Controls.Add($ButtonADK)
    $Form.Controls.Add($ButtonSystemManagementContainer)
	$Form.Controls.Add($GBSites)
	$Form.Controls.Add($GBSiteSystemRoles)
	$Form.Controls.Add($GBOther)
	Leave-WaterMarkStart -InputObject $TextBoxDC -Text $WaterMarkDC
    Leave-WaterMarkStart -InputObject $TextBoxWSUSSQLServer -Text $WaterMarkWSUSSQLServer
    Leave-WaterMarkStart -InputObject $TextBoxWSUSSQLInstance -Text $WaterMarkWSUSSQLInstance
}

function Load-CAS {
	$Form.Controls.Clear()
    $Form.Controls.Add($ButtonBack)
	$Form.Controls.Add($ProgressBar)
	$Form.Controls.Add($OutputBox)
	$Form.Controls.Add($ButtonInstallCAS)
	$OutputBox.ResetText()
	if ($ButtonInstallCAS.Enabled -eq $false) {
		$ButtonInstallCAS.Enabled = $true
	}
}

function Load-Primary {
	$Form.Controls.Clear()
    $Form.Controls.Add($ButtonBack)
	$Form.Controls.Add($ProgressBar)
	$Form.Controls.Add($OutputBox)
	$Form.Controls.Add($ButtonInstallPrimarySite)
	$OutputBox.ResetText()
	if ($ButtonInstallPrimarySite.Enabled -eq $false) {
		$ButtonInstallPrimarySite.Enabled = $true
	}	
}

function Load-Secondary {
	$Form.Controls.Clear()
    $Form.Controls.Add($ButtonBack)
	$Form.Controls.Add($ProgressBar)
	$Form.Controls.Add($OutputBox)
	$Form.Controls.Add($ButtonInstallSecondarySite)	
	$OutputBox.ResetText()
	if ($ButtonInstallSecondarySite.Enabled -eq $false) {
		$ButtonInstallSecondarySite.Enabled = $true
	}	
}

function Load-MP {
	$Form.Controls.Clear()
    $Form.Controls.Add($ButtonBack)
	$Form.Controls.Add($ProgressBar)
	$Form.Controls.Add($OutputBox)
	$Form.Controls.Add($ButtonInstallMP)	
	$OutputBox.ResetText()
	if ($ButtonInstallMP.Enabled -eq $false) {
		$ButtonInstallMP.Enabled = $true
	}	
}

function Load-AppCat {
	$Form.Controls.Clear()
    $Form.Controls.Add($ButtonBack)
	$Form.Controls.Add($ProgressBar)
	$Form.Controls.Add($OutputBox)
	$Form.Controls.Add($ButtonInstallAppCat)	
	$OutputBox.ResetText()
	if ($ButtonInstallAppCat.Enabled -eq $false) {
		$ButtonInstallAppCat.Enabled = $true
	}	
}

function Load-DP {
	$Form.Controls.Clear()
    $Form.Controls.Add($ButtonBack)
	$Form.Controls.Add($ProgressBar)
	$Form.Controls.Add($OutputBox)
	$Form.Controls.Add($ButtonInstallDP)	
	$OutputBox.ResetText()
	if ($ButtonInstallDP.Enabled -eq $false) {
		$ButtonInstallDP.Enabled = $true
	}	
}

function Load-EP {
	$Form.Controls.Clear()
    $Form.Controls.Add($ButtonBack)
	$Form.Controls.Add($ProgressBar)
	$Form.Controls.Add($OutputBox)
	$Form.Controls.Add($ButtonInstallEP)
    $Form.Controls.Add($RadioButtonEP)
    $Form.Controls.Add($RadioButtonEPP)	
    $Form.Controls.Add($GBEP)
	$OutputBox.ResetText()
    $RadioButtonEP.Checked = $true
	if ($ButtonInstallEP.Enabled -eq $false) {
		$ButtonInstallEP.Enabled = $true
	}
	if ($RadioButtonEP.Enabled -eq $false) {
		$RadioButtonEP.Enabled = $true
	}
	if ($RadioButtonEPP.Enabled -eq $false) {
		$RadioButtonEPP.Enabled = $true
	}
}

function Load-ExtendActiveDirectory {
	$Form.Controls.Clear()
    $Form.Controls.Add($ButtonBack)
	$Form.Controls.Add($ProgressBar)
	$Form.Controls.Add($OutputBox)
	$Form.Controls.Add($ButtonConnectDC)
	$Form.Controls.Add($TextBoxDC)
    $Form.Controls.Add($GBExtendAD)
	$OutputBox.ResetText()
	if ($ButtonExtendAD.Enabled -eq $false) {
		$ButtonExtendAD.Enabled = $true
	}
}

function Load-WSUS {
	$Form.Controls.Clear()
    $Form.Controls.Add($ButtonBack)
	$Form.Controls.Add($ProgressBar)
	$Form.Controls.Add($OutputBox)
    $Form.Controls.Add($RadioButtonWID)
    $Form.Controls.Add($RadioButtonSQL)
    $Form.Controls.Add($TextBoxWSUSSQLServer)
    $Form.Controls.Add($TextBoxWSUSSQLInstance)
    $Form.Controls.Add($GBWSUS)
    $Form.Controls.Add($GBWSUSSQL)
	$Form.Controls.Add($ButtonInstallWSUS)
    $RadioButtonWID.Checked = $true
	$OutputBox.ResetText()
	if ($ButtonInstallWSUS.Enabled -eq $false) {
		$ButtonInstallWSUS.Enabled = $true
	}
	if ($RadioButtonWID.Enabled -eq $false) {
		$RadioButtonWID.Enabled = $true
	}
	if ($RadioButtonSQL.Enabled -eq $false) {
		$RadioButtonSQL.Enabled = $true
	}
	if ($TextBoxWSUSSQLServer.Enabled -eq $true) {
		$TextBoxWSUSSQLServer.Enabled = $false
	}
	if ($TextBoxWSUSSQLInstance.Enabled -eq $true) {
		$TextBoxWSUSSQLInstance.Enabled = $false
	}	
}

function Load-ADK {
	$Form.Controls.Clear()
    $Form.Controls.Add($ButtonBack)
	$Form.Controls.Add($ProgressBar)
	$Form.Controls.Add($OutputBox)
	$Form.Controls.Add($ButtonInstallADK)
	$Form.Controls.Add($RadioButtonOnline)
	$Form.Controls.Add($RadioButtonOffline)
	$Form.Controls.Add($GBADK)
	$RadioButtonOnline.Checked = $true	
	$OutputBox.ResetText()
	if ($ButtonInstallADK.Enabled -eq $false) {
		$ButtonInstallADK.Enabled = $true
	}
	if ($RadioButtonOnline.Enabled -eq $false) {
		$RadioButtonOnline.Enabled = $true
	}
	if ($RadioButtonOffline.Enabled -eq $false) {
		$RadioButtonOffline.Enabled = $true
	}	
}

function Load-SystemManagementContainer {
	$Form.Controls.Clear()
    $Form.Controls.Add($TabControlSMC)
    $TabControlSMC.Controls.Add($TabPageSMCComputer)
    $TabControlSMC.Controls.Add($TabPageSMCGroup)
    if ($ButtonBack.Location.Y -eq 420) {
        $ButtonBack.Location = New-Object System.Drawing.Size(563,385) 
    }
    $TabPageSMCComputer.Controls.Add($ButtonBack)
	$TabPageSMCComputer.Controls.Add($OutputBox)
	$TabPageSMCComputer.Controls.Add($ButtonConfigureSystemManagementContainerComputer)
    $TabPageSMCComputer.Controls.Add($TextBoxSMCLocal)
    $TabPageSMCComputer.Controls.Add($TextBoxSMCRemote)
    $TabPageSMCComputer.Controls.Add($RadioButtonSMCLocal)
    $TabPageSMCComputer.Controls.Add($RadioButtonSMCRemote)
    $TabPageSMCComputer.Controls.Add($CBSMCCreate)
    $TabPageSMCComputer.Controls.Add($LabelSMCCreate)
    $TabPageSMCComputer.Controls.Add($GBSystemManagementContainer)
    Validate-ADGroupSearch
    $TextBoxSMCGroupSearch.ResetText()
    $TextBoxSMCGroupResult.ResetText()
    $TabPageSMCGroup.Controls.Add($TextBoxSMCGroupSearch)
    $TabPageSMCGroup.Controls.Add($TextBoxSMCGroupResult)
    $TabPageSMCGroup.Controls.Add($DGVSMCGroup)
    $TabPageSMCGroup.Controls.Add($ButtonBackGroup)
    $TabPageSMCGroup.Controls.Add($ButtonSystemManagementContainerGroupSearch)
    $TabPageSMCGroup.Controls.Add($ButtonConfigureSystemManagementContainerGroup)
    $TabPageSMCGroup.Controls.Add($GBSystemManagementContainerGroup)
    $TabPageSMCGroup.Controls.Add($GBSystemManagementContainerGroupSearch)
	$OutputBox.ResetText()
    $RadioButtonSMCLocal.Checked = $true
	if ($ButtonConfigureSystemManagementContainerComputer.Enabled -eq $false) {
		$ButtonConfigureSystemManagementContainerComputer.Enabled = $true
	}
	if ($ButtonConfigureSystemManagementContainerGroup.Enabled -eq $true) {
		$ButtonConfigureSystemManagementContainerGroup.Enabled = $false
	}
	if ($ButtonSystemManagementContainerGroupSearch.Enabled -eq $false) {
		$ButtonSystemManagementContainerGroupSearch.Enabled = $true
	}
    if ($TextBoxSMCGroupSearch.Enabled -eq $false) {
        $TextBoxSMCGroupSearch.Enabled -eq $true
    }
	if ($RadioButtonSMCLocal.Enabled -eq $false) {
		$RadioButtonSMCLocal.Enabled = $true
	}
	if ($RadioButtonSMCRemote.Enabled -eq $false) {
		$RadioButtonSMCRemote.Enabled = $true
	}
}

function Validate-RebootPending {
	param(
	[parameter(Mandatory=$true)]
	$ComputerName
	)
	$RebootPendingCBS = $null
	$RebootPendingWUAU = $null
	$GetOS = Get-WmiObject -Class Win32_OperatingSystem -Property BuildNumber,CSName -ComputerName $ComputerName
	$ConnectRegistry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]"LocalMachine",$ComputerName)   
	if ($GetOS.BuildNumber -ge 6001) {
		$RegistryCBS = $ConnectRegistry.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\").GetSubKeyNames() 
		$RebootPendingCBS = $RegistryCBS -contains "RebootPending"
	}
	$RegistryWUAU = $ConnectRegistry.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\").GetSubKeyNames()
	$RebootPendingWUAU = $RegistryWUAU -contains "RebootRequired" 
	$RegistryPFRO = $ConnectRegistry.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager\") 
	$RegistryValuePFRO = $RegistryPFRO.GetValue("PendingFileRenameOperations",$null) 
	if ($RegistryValuePFRO) {
		$RebootPendingPFRO = $true
	}
	if (($RebootPendingCBS) -or ($RebootPendingWUAU) -or ($RebootPendingPFRO)) {
		return $true	
	}
	else {
		return $false
	}	
}

function Validate-CASInstall {
	$CASErrorHandler = 0
	if ((([System.Environment]::OSVersion.Version).Build -lt 6001) -or ([System.Environment]::Is64BitOperatingSystem -eq $false)) {
		$CASErrorHandler++
	}
	if ($CASErrorHandler -gt 0) {
		Write-OutputBox -OutputBoxMessage "Unsupported Operating System detected. Windows Server 2008 64-bit and later is supported" -Type "ERROR: "
		$ButtonInstallCAS.Enabled = $false
	}
	else {
		$GetComputerName = $env:COMPUTERNAME
		$ValidateCASRebootPending = Validate-RebootPending -ComputerName $GetComputerName
		if ($ValidateCASRebootPending) {
			$ButtonInstallCAS.Enabled = $false
			Write-OutputBox -OutputBoxMessage "A reboot is pending, please restart the system." -Type "WARNING: "
		}
		else {
			Install-CAS
		}
	}
}

function Validate-PrimaryInstall {
	$PrimaryErrorHandler = 0
	if ((([System.Environment]::OSVersion.Version).Build -lt 6001) -or ([System.Environment]::Is64BitOperatingSystem -eq $false)) {
		$PrimaryErrorHandler++
	}
	if ($PrimaryErrorHandler -gt 0) {
		Write-OutputBox -OutputBoxMessage "Unsupported Operating System detected. Windows Server 2008 64-bit and later is supported" -Type "ERROR: "
		$ButtonInstallPrimarySite.Enabled = $false
	}
	else {
		$GetComputerName = $env:COMPUTERNAME
		$ValidatePrimaryRebootPending = Validate-RebootPending -ComputerName $GetComputerName
		if ($ValidatePrimaryRebootPending) {
			$ButtonInstallPrimarySite.Enabled = $false
			Write-OutputBox -OutputBoxMessage "A reboot is pending, please restart the system." -Type "WARNING: "
		}
		else {
			Install-Primary
		}
	}	
}

function Validate-SecondaryInstall {
	$SecondaryErrorHandler = 0
	if ((([System.Environment]::OSVersion.Version).Build -lt 6001) -or ([System.Environment]::Is64BitOperatingSystem -eq $false)) {
		$SecondaryErrorHandler++
	}
	if ($SecondaryErrorHandler -gt 0) {
		Write-OutputBox -OutputBoxMessage "Unsupported Operating System detected. Windows Server 2008 64-bit and later is supported" -Type "ERROR: "
		$ButtonInstallSecondarySite.Enabled = $false
	}
	else {
		$GetComputerName = $env:COMPUTERNAME
		$ValidateSecondaryRebootPending = Validate-RebootPending -ComputerName $GetComputerName
		if ($ValidateSecondaryRebootPending) {
			$ButtonInstallSecondarySite.Enabled = $false
			Write-OutputBox -OutputBoxMessage "A reboot is pending, please restart the system." -Type "WARNING: "
		}
		else {
			Install-Secondary
		}
	}	
}

function Validate-MPInstall {
	$MPErrorHandler = 0
	if ((([System.Environment]::OSVersion.Version).Build -lt 6001) -or ([System.Environment]::Is64BitOperatingSystem -eq $false)) {
		$MPErrorHandler++
	}
	if ($MPErrorHandler -gt 0) {
		Write-OutputBox -OutputBoxMessage "Unsupported Operating System detected. Windows Server 2008 64-bit and later is supported" -Type "ERROR: "
		$ButtonInstallMP.Enabled = $false
	}
	else {
		$GetComputerName = $env:COMPUTERNAME
		$ValidateMPRebootPending = Validate-RebootPending -ComputerName $GetComputerName
		if ($ValidateMPRebootPending) {
			$ButtonInstallMP.Enabled = $false
			Write-OutputBox -OutputBoxMessage "A reboot is pending, please restart the system." -Type "WARNING: "
		}
		else {
			Install-MP
		}
	}	
}

function Validate-AppCatInstall {
	$AppCatErrorHandler = 0
	if ((([System.Environment]::OSVersion.Version).Build -lt 6001) -or ([System.Environment]::Is64BitOperatingSystem -eq $false)) {
		$AppCatErrorHandler++
	}
	if ($AppCatErrorHandler -gt 0) {
		Write-OutputBox -OutputBoxMessage "Unsupported Operating System detected. Windows Server 2008 64-bit and later is supported" -Type "ERROR: "
		$ButtonInstallAppCat.Enabled = $false
	}
	else {
		$GetComputerName = $env:COMPUTERNAME
		$ValidateAppCatRebootPending = Validate-RebootPending -ComputerName $GetComputerName
		if ($ValidateAppCatRebootPending) {
			$ButtonInstallAppCat.Enabled = $false
			Write-OutputBox -OutputBoxMessage "A reboot is pending, please restart the system." -Type "WARNING: "
		}
		else {
			Install-AppCat
		}
	}	
}

function Validate-DPInstall {
	$DPErrorHandler = 0
	if ((([System.Environment]::OSVersion.Version).Build -lt 6001) -or ([System.Environment]::Is64BitOperatingSystem -eq $false)) {
		$DPErrorHandler++
	}
	if ($DPErrorHandler -gt 0) {
		Write-OutputBox -OutputBoxMessage "Unsupported Operating System detected. Windows Server 2008 64-bit and later is supported" -Type "ERROR: "
		$ButtonInstallDP.Enabled = $false
	}
	else {
		$GetComputerName = $env:COMPUTERNAME
		$ValidateDPRebootPending = Validate-RebootPending -ComputerName $GetComputerName
		if ($ValidateDPRebootPending) {
			$ButtonInstallDP.Enabled = $false
			Write-OutputBox -OutputBoxMessage "A reboot is pending, please restart the system." -Type "WARNING: "
		}
		else {
			Install-DP
		}
	}	
}

function Validate-EPInstall {
	$EPErrorHandler = 0
	if ((([System.Environment]::OSVersion.Version).Build -lt 9200) -or ([System.Environment]::Is64BitOperatingSystem -eq $false)) {
		$EPErrorHandler++
	}
	if ($EPErrorHandler -gt 0) {
		Write-OutputBox -OutputBoxMessage "Unsupported Operating System detected. Windows Server 2012 and later is supported" -Type "ERROR: "
		$ButtonInstallEP.Enabled = $false
	}
	else {
		$GetComputerName = $env:COMPUTERNAME
		$ValidateEPRebootPending = Validate-RebootPending -ComputerName $GetComputerName
		if ($ValidateEPRebootPending) {
			$ButtonInstallEP.Enabled = $false
			Write-OutputBox -OutputBoxMessage "A reboot is pending, please restart the system." -Type "WARNING: "
		}
		else {
			Install-EP
		}
	}	
}

function Validate-DomainController {
    param(
   	[parameter(Mandatory=$true)]
   	$DCName
   	)
   	Process {
       	$SchemaMaster = ([System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()).SchemaRoleOwner.Name
        if (($DCName -like $SchemaMaster) -or ($DCName -like $SchemaMaster.Split(".")[0])) {
            Write-OutputBox -OutputBoxMessage "Specified server name is the Schema Master role owner" -Type "INFO: "
            return $true
        }
        elseif (($DCName -ne $SchemaMaster) -or ($DCName -ne $SchemaMaster.Split(".")[0])) {
           	Write-OutputBox -OutputBoxMessage "The specified server name is not the Schema Master role owner in the forest" -Type "ERROR: "
            return $false
       	}
       	else {
           	return $false
       	}
   	}
}

function Validate-ExtendActiveDirectory {
    $OutputBox.ResetText()
    $EADErrorHandler = 0
    $CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent() 
    $WindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($CurrentUser)
    if (-not($WindowsPrincipal.IsInRole("Schema Admins"))) {
        Write-OutputBox -OutputBoxMessage "Current user is not a member of the Schema Admins group" -Type "ERROR: "
    }
	if ($TextBoxDC.Text -eq $WaterMarkDC) {
		Write-OutputBox -OutputBoxMessage "Please enter a hostname of a domain controller" -Type "ERROR: "
	}
    if (-not(Test-Connection -ComputerName $TextBoxDC.Text -Count 1 -ErrorAction SilentlyContinue)) {
			Write-OutputBox -OutputBoxMessage "Unable to establish a connection to the server" -Type "ERROR: "
	}
    else {
        if (Validate-DomainController -DCName $TextBoxDC.Text) {
			Write-OutputBox -OutputBoxMessage "Successfully established a connection to the server" -Type "INFO: "
            $DCConnected = $true
	    }
    }
	if ($DCConnected) {
        $TextBoxDC.Enabled = $false
        $Form.Controls.Remove($ButtonConnectDC)
        $Form.Controls.Add($ButtonInstallExtendAD)
	}
}

function Validate-WSUS {
	$WSUSErrorHandler = 0
	if ((([System.Environment]::OSVersion.Version).Build -lt 9200) -or ([System.Environment]::Is64BitOperatingSystem -eq $false)) {
		$WSUSErrorHandler++
	}
	if ($WSUSErrorHandler -gt 0) {
		Write-OutputBox -OutputBoxMessage "Unsupported Operating System detected. Windows Server 2012 64-bit and later is supported" -Type "ERROR: "
		$ButtonInstallWSUS.Enabled = $false
	}
	else {
		$GetComputerName = $env:COMPUTERNAME
		$ValidateWSUSRebootPending = Validate-RebootPending -ComputerName $GetComputerName
		if ($ValidateWSUSRebootPending) {
			$ButtonInstallWSUS.Enabled = $false
			Write-OutputBox -OutputBoxMessage "A reboot is pending, please restart the system." -Type "WARNING: "
		}
		else {
            if (($TextBoxWSUSSQLServer.Text.Length -eq 0) -and ($RadioButtonSQL.Checked -eq $true)) {
                Write-OutputBox -OutputBoxMessage "Please enter a SQL Server computer name" -Type "ERROR: "
            }
            else {
                Install-WSUS
            }
		}
	}	
}

function Validate-ADK {
	$ADKErrorHandler = 0
	if ((([System.Environment]::OSVersion.Version).Build -lt 7600) -or ([System.Environment]::Is64BitOperatingSystem -eq $false)) {
		$ADKErrorHandler++
	}
	if ($ADKErrorHandler -gt 0) {
		Write-OutputBox -OutputBoxMessage "Unsupported Operating System detected. Windows Server 2008 R2 64-bit and later is supported" -Type "ERROR: "
		$ButtonInstallADK.Enabled = $false
	}
	else {
		$GetComputerName = $env:COMPUTERNAME
		$ValidateADKRebootPending = Validate-RebootPending -ComputerName $GetComputerName
		if ($ValidateADKRebootPending) {
			$ButtonInstallADK.Enabled = $false
			Write-OutputBox -OutputBoxMessage "A reboot is pending, please restart the system." -Type "WARNING: "
		}
		else {
			Install-ADK
		}
	}	
}

function Validate-SystemManagementContainerComputer {
    $OutputBox.ResetText()
	$SMCErrorHandler = 0
    $ShellObject = New-Object -ComObject Wscript.Shell
    $CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent() 
    $WindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($CurrentUser)
	if ((([System.Environment]::OSVersion.Version).Build -lt 7600) -or ([System.Environment]::Is64BitOperatingSystem -eq $false)) {
		$SMCErrorHandler = 1
	}
    if(-not($WindowsPrincipal.IsInRole("Domain Admins"))) {
        $SMCErrorHandler = 2
    }
	switch ($SMCErrorHandler) {
		1 { Write-OutputBox -OutputBoxMessage "Unsupported Operating System detected. Windows Server 2008 R2 64-bit and later is supported" -Type "ERROR: " ; $ButtonConfigureSystemManagementContainerComputer.Enabled = $false }
        2 { Write-OutputBox -OutputBoxMessage "The current user is not a member of Domain Admins, please run this script as a Domain Admin" -Type "ERROR: " ; $ButtonConfigureSystemManagementContainerComputer.Enabled = $false }
	}
    if ($SMCErrorHandler -eq 0) {  
        Configure-SystemManagementContainerComputer
    }
}

function Validate-SystemManagementContainerGroup {
	$SMCErrorHandler = 0
    $ShellObject = New-Object -ComObject Wscript.Shell
    $CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent() 
    $WindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($CurrentUser)
	if ((([System.Environment]::OSVersion.Version).Build -lt 7600) -or ([System.Environment]::Is64BitOperatingSystem -eq $false)) {
		$SMCErrorHandler = 1
	}
    if(-not($WindowsPrincipal.IsInRole("Domain Admins"))) {
        $SMCErrorHandler = 2
    }
	switch ($SMCErrorHandler) {
		1 { Write-OutputBox -OutputBoxMessage "Unsupported Operating System detected. Windows Server 2008 R2 64-bit and later is supported" -Type "ERROR: " ; $ButtonSystemManagementContainerGroupSearch.Enabled = $false ; $TextBoxSMCGroupSearch.Enabled = $false }
        2 { Write-OutputBox -OutputBoxMessage "The current user is not a member of Domain Admins, please run this script as a Domain Admin" -Type "ERROR: " ; $ButtonSystemManagementContainerGroupSearch.Enabled = $false ; $TextBoxSMCGroupSearch.Enabled = $false }
	}
    if ($SMCErrorHandler -eq 0) {  
        Configure-SystemManagementContainerGroup
    }
}

function Install-CAS {
	$InstallType = 1
	$OSBuild = ([System.Environment]::OSVersion.Version).Build
    if (($OSBuild -eq 7600) -or ($OSBuild -eq 7601)) {
		Write-OutputBox -OutputBoxMessage "Detected OS build version is $($OSBuild) running PowerShell version $($host.Version)"
		$WinFeatures = @("NET-Framework-Core","BITS","BITS-IIS-Ext","BITS-Compact-Server","RDC","WAS-Process-Model","WAS-Config-APIs","WAS-Net-Environment","Web-Server","Web-ISAPI-Ext","Web-ISAPI-Filter","Web-Net-Ext","Web-ASP-Net","Web-ASP","Web-Windows-Auth","Web-Basic-Auth","Web-URL-Auth","Web-IP-Security","Web-Scripting-Tools","Web-Mgmt-Service","Web-Stat-Compression","Web-Dyn-Compression","Web-Metabase","Web-WMI","Web-HTTP-Redirect","Web-Log-Libraries","Web-HTTP-Tracing")
	}
	if ($OSBuild -ge 9200) {
		Write-OutputBox -OutputBoxMessage "Detected OS build version is $($OSBuild) running PowerShell version $($host.Version)"
		$WinFeatures = @("NET-Framework-Core","BITS","BITS-IIS-Ext","BITS-Compact-Server","RDC","WAS-Process-Model","WAS-Config-APIs","WAS-Net-Environment","Web-Server","Web-ISAPI-Ext","Web-ISAPI-Filter","Web-Net-Ext","Web-Net-Ext45","Web-ASP-Net","Web-ASP-Net45","Web-ASP","Web-Windows-Auth","Web-Basic-Auth","Web-URL-Auth","Web-IP-Security","Web-Scripting-Tools","Web-Mgmt-Service","Web-Stat-Compression","Web-Dyn-Compression","Web-Metabase","Web-WMI","Web-HTTP-Redirect","Web-Log-Libraries","Web-HTTP-Tracing","UpdateServices-RSAT","UpdateServices-API","UpdateServices-UI")
	}
    $ProgressBar.Maximum = ($WinFeatures | Measure-Object).Count
    $ProgressPreference = "SilentlyContinue"
	$WarningPreference = "SilentlyContinue"	
    $ButtonBack.Enabled = $false
    $ButtonInstallCAS.Enabled = $false
	$WinFeatures | ForEach-Object {
        $CurrentFeature = $_
		$CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (-NOT(Get-WindowsFeature -Name $CurrentFeature | Select-Object Name,Installed | Where-Object { $_.Installed -like "true" })) {
        	Write-OutputBox -OutputBoxMessage "Installing role: $($CurrentFeatureDisplayName.DisplayName)"
			[System.Windows.Forms.Application]::DoEvents()
            if (([System.Environment]::OSVersion.Version).Build -lt 9200) {
   			    Add-WindowsFeature $CurrentFeature | Out-Null
            }
            if (([System.Environment]::OSVersion.Version).Build -ge 9200) {
                if ($CurrentFeature -eq "NET-Framework-Core") {
                    Add-WindowsFeature NET-Framework-Core -ErrorAction SilentlyContinue | Out-Null
                    if (Get-WindowsFeature -Name NET-Framework-Core | Select-Object Name,Installed | Where-Object { $_.Installed -like "false" }) {
                        Write-OutputBox -OutputBoxMessage "Failed to install $($CurrentFeatureDisplayName.DisplayName)" -Type "ERROR: "

                        do {
                            if (([System.Environment]::OSVersion.Version).Build -eq 9600) {
			                    $SetupDLLocation = Read-FolderBrowserDialog -Message "Browse the Windows Server 2012 R2 installation media for the '<drive-letter>:\sources\sxs' folder."
                            }
                            if (([System.Environment]::OSVersion.Version).Build -eq 9200) {
                                $SetupDLLocation = Read-FolderBrowserDialog -Message "Browse the Windows Server 2012 installation media for the '<drive-letter>:\sources\sxs' folder."
                            }
		                }
                        until (($SetupDLLocation.Length -gt 0) -and (Test-Path -Path "$($SetupDLLocation.SubString(0,2))\sources\sxs" -ErrorAction SilentlyContinue))
                        Write-OutputBox -OutputBoxMessage "Installing role with specified source location: $($CurrentFeatureDisplayName.DisplayName)"
                        Add-WindowsFeature NET-Framework-Core -Source $SetupDLLocation
                    }
                }
                else {
			        Start-Job -Name $CurrentFeature -ScriptBlock {
    			        param(
        			        [parameter(Mandatory=$true)]
        			        $CurrentFeature
    			        )
    			        Add-WindowsFeature $CurrentFeature
			        } -ArgumentList $CurrentFeature | Out-Null
			        Wait-Job -Name $CurrentFeature
			        Remove-Job -Name $CurrentFeature
                }
            }
        }
        else {
            Write-OutputBox -OutputBoxMessage "Skipping role (already installed): $($CurrentFeatureDisplayName.DisplayName)"
        }
        $ProgressBar.PerformStep()
    }
	$ShellObject = New-Object -ComObject Wscript.Shell
	$PopupContinue = $ShellObject.Popup("Installation completed. Would you like to download the prerequisite files?`n(A connection to the internet connection is required)",0,"Prerequisites",1)
	if ($PopupContinue -eq 1) {
		Get-PrereqFiles
        Write-OutputBox -OutputBoxMessage "Starting verification that all features where successfully installed"
        $ErrorVerify = 0
        $ProgressBar.Value = 0
        $WinFeatures | ForEach-Object {
            $CurrentFeature = $_
            $CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
            if (Get-WindowsFeature $CurrentFeature | Where-Object { $_.Installed -eq $true}) {
                Write-OutputBox -OutputBoxMessage "Verified installed: $($CurrentFeatureDisplayName.DisplayName)"
                $ProgressBar.PerformStep()
            }
            else {
                $ErrorVerify++
                Write-OutputBox -OutputBoxMessage "Feature not installed: $($CurrentFeatureDisplayName.DisplayName)"
                $ProgressBar.PerformStep()
            }
        }
        if ($ErrorVerify -eq 0) {
    	    Write-OutputBox -OutputBoxMessage "Successfully installed all required Windows Features"
        }
        else {
            Write-OutputBox -OutputBoxMessage "One or more Windows Features was not installed"
        }
	}
	else {
		Write-OutputBox -OutputBoxMessage "Starting verification that all features where successfully installed"
        $ErrorVerify = 0
        $ProgressBar.Value = 0
        $WinFeatures | ForEach-Object {
            $CurrentFeature = $_
            $CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
            if (Get-WindowsFeature $CurrentFeature | Where-Object { $_.Installed -eq $true}) {
                Write-OutputBox -OutputBoxMessage "Verified installed: $($CurrentFeatureDisplayName.DisplayName)"
                $ProgressBar.PerformStep()
            }
            else {
                $ErrorVerify++
                Write-OutputBox -OutputBoxMessage "Feature not installed: $($CurrentFeatureDisplayName.DisplayName)"
                $ProgressBar.PerformStep()
            }
        }
        if ($ErrorVerify -eq 0) {
            Write-OutputBox -OutputBoxMessage "Successfully installed all required Windows Features"
        }
        else {
            Write-OutputBox -OutputBoxMessage "One or more Windows Features was not installed"
        }
		$ButtonBack.Enabled = $true
		$Form.Controls.Remove($ButtonInstallCAS)
    	$Form.Controls.Add($ButtonFinish)
	}
	$InstallType = 0
}

function Install-Primary {
	$InstallType = 2
	$OSBuild = ([System.Environment]::OSVersion.Version).Build
    if (($OSBuild -eq 7600) -or ($OSBuild -eq 7601)) {
		Write-OutputBox -OutputBoxMessage "Detected OS build version is $($OSBuild) running PowerShell version $($host.Version)"
		$WinFeatures = @("NET-Framework-Core","BITS","BITS-IIS-Ext","BITS-Compact-Server","RDC","WAS-Process-Model","WAS-Config-APIs","WAS-Net-Environment","Web-Server","Web-ISAPI-Ext","Web-ISAPI-Filter","Web-Net-Ext","Web-ASP-Net","Web-ASP","Web-Windows-Auth","Web-Basic-Auth","Web-URL-Auth","Web-IP-Security","Web-Scripting-Tools","Web-Mgmt-Service","Web-Stat-Compression","Web-Dyn-Compression","Web-Metabase","Web-WMI","Web-HTTP-Redirect","Web-Log-Libraries","Web-HTTP-Tracing")
	}
	if ($OSBuild -ge 9200) {
		Write-OutputBox -OutputBoxMessage "Detected OS build version is $($OSBuild) running PowerShell version $($host.Version)"
		$WinFeatures = @("NET-Framework-Core","BITS","BITS-IIS-Ext","BITS-Compact-Server","RDC","WAS-Process-Model","WAS-Config-APIs","WAS-Net-Environment","Web-Server","Web-ISAPI-Ext","Web-ISAPI-Filter","Web-Net-Ext","Web-Net-Ext45","Web-ASP-Net","Web-ASP-Net45","Web-ASP","Web-Windows-Auth","Web-Basic-Auth","Web-URL-Auth","Web-IP-Security","Web-Scripting-Tools","Web-Mgmt-Service","Web-Stat-Compression","Web-Dyn-Compression","Web-Metabase","Web-WMI","Web-HTTP-Redirect","Web-Log-Libraries","Web-HTTP-Tracing","UpdateServices-RSAT","UpdateServices-API","UpdateServices-UI")
	}
    $ProgressBar.Maximum = ($WinFeatures | Measure-Object).Count
    $ProgressPreference = "SilentlyContinue"
	$WarningPreference = "SilentlyContinue"	
    $ButtonBack.Enabled = $false
    $ButtonInstallPrimarySite.Enabled = $false
	$WinFeatures | ForEach-Object {
        $CurrentFeature = $_
		$CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (-NOT(Get-WindowsFeature -Name $CurrentFeature | Select-Object Name,Installed | Where-Object { $_.Installed -like "true" })) {
        	Write-OutputBox -OutputBoxMessage "Installing role: $($CurrentFeatureDisplayName.DisplayName)"
			[System.Windows.Forms.Application]::DoEvents()
            if (([System.Environment]::OSVersion.Version).Build -lt 9200) {
   			    Add-WindowsFeature $CurrentFeature | Out-Null
            }
            if (([System.Environment]::OSVersion.Version).Build -ge 9200) {
                if ($CurrentFeature -eq "NET-Framework-Core") {
                    Add-WindowsFeature NET-Framework-Core -ErrorAction SilentlyContinue | Out-Null
                    if (Get-WindowsFeature -Name NET-Framework-Core | Select-Object Name,Installed | Where-Object { $_.Installed -like "false" }) {
                        Write-OutputBox -OutputBoxMessage "Failed to install $($CurrentFeatureDisplayName.DisplayName)" -Type "ERROR: "

                        do {
                            if (([System.Environment]::OSVersion.Version).Build -eq 9600) {
			                    $SetupDLLocation = Read-FolderBrowserDialog -Message "Browse the Windows Server 2012 R2 installation media for the '<drive-letter>:\sources\sxs' folder."
                            }
                            if (([System.Environment]::OSVersion.Version).Build -eq 9200) {
                                $SetupDLLocation = Read-FolderBrowserDialog -Message "Browse the Windows Server 2012 installation media for the '<drive-letter>:\sources\sxs' folder."
                            }
		                }
                        until (($SetupDLLocation.Length -gt 0) -and (Test-Path -Path "$($SetupDLLocation.SubString(0,2))\sources\sxs" -ErrorAction SilentlyContinue))
                        Write-OutputBox -OutputBoxMessage "Installing role with specified source location: $($CurrentFeatureDisplayName.DisplayName)"
                        Add-WindowsFeature NET-Framework-Core -Source $SetupDLLocation
                    }
                }
                else {
			        Start-Job -Name $CurrentFeature -ScriptBlock {
    			        param(
        			        [parameter(Mandatory=$true)]
        			        $CurrentFeature
    			        )
    			        Add-WindowsFeature $CurrentFeature
			        } -ArgumentList $CurrentFeature | Out-Null
			        Wait-Job -Name $CurrentFeature
			        Remove-Job -Name $CurrentFeature
                }
            }
        }
        else {
            Write-OutputBox -OutputBoxMessage "Skipping role (already installed): $($CurrentFeatureDisplayName.DisplayName)"
        }
        $ProgressBar.PerformStep()
    }
	$ShellObject = New-Object -ComObject Wscript.Shell
	$PopupContinue = $ShellObject.Popup("Installation completed. Would you like to download the prerequisite files?`n(A connection to the internet connection is required)",0,"Prerequisites",1)
	if ($PopupContinue -eq 1) {
		Get-PrereqFiles
        Write-OutputBox -OutputBoxMessage "Starting verification that all features where successfully installed"
        $ErrorVerify = 0
        $ProgressBar.Value = 0
        $WinFeatures | ForEach-Object {
            $CurrentFeature = $_
            $CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
            if (Get-WindowsFeature $CurrentFeature | Where-Object { $_.Installed -eq $true}) {
                Write-OutputBox "Verified installed: $($CurrentFeatureDisplayName.DisplayName)"
                $ProgressBar.PerformStep()
            }
            else {
                $ErrorVerify++
                Write-OutputBox "Feature not installed: $($CurrentFeatureDisplayName.DisplayName)"
                $ProgressBar.PerformStep()
            }
        }
        if ($ErrorVerify -eq 0) {
    	    Write-OutputBox -OutputBoxMessage "Successfully installed all required Windows Features"
        }
        else {
            Write-OutputBox -OutputBoxMessage "One or more Windows Features was not installed"
        }
	}
	else {
		Write-OutputBox -OutputBoxMessage "Starting verification that all features where successfully installed"
        $ErrorVerify = 0
        $ProgressBar.Value = 0
        $WinFeatures | ForEach-Object {
            $CurrentFeature = $_
            $CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
            if (Get-WindowsFeature $CurrentFeature | Where-Object { $_.Installed -eq $true}) {
                Write-OutputBox "Verified installed: $($CurrentFeatureDisplayName.DisplayName)"
                $ProgressBar.PerformStep()
            }
            else {
                $ErrorVerify++
                Write-OutputBox "Feature not installed: $($CurrentFeatureDisplayName.DisplayName)"
                $ProgressBar.PerformStep()
            }
        }
        if ($ErrorVerify -eq 0) {
            Write-OutputBox -OutputBoxMessage "Successfully installed all required Windows Features"
        }
        else {
            Write-OutputBox -OutputBoxMessage "One or more Windows Features was not installed"
        }
		$ButtonBack.Enabled = $true
		$Form.Controls.Remove($ButtonInstallPrimarySite)
    	$Form.Controls.Add($ButtonFinish)
	}
	$InstallType = 0
}

function Install-Secondary {
	$OSBuild = ([System.Environment]::OSVersion.Version).Build
    if (($OSBuild -eq 7600) -or ($OSBuild -eq 7601)) {
		Write-OutputBox -OutputBoxMessage "Detected OS build version is $($OSBuild) running PowerShell version $($host.Version)"
		$WinFeatures = @("NET-Framework-Core","BITS","BITS-IIS-Ext","BITS-Compact-Server","RDC","WAS-Process-Model","WAS-Config-APIs","WAS-Net-Environment","Web-Server","Web-ISAPI-Ext","Web-Windows-Auth","Web-Basic-Auth","Web-URL-Auth","Web-IP-Security","Web-Scripting-Tools","Web-Mgmt-Service","Web-Metabase","Web-WMI")
	}
	if ($OSBuild -ge 9200) {
		Write-OutputBox -OutputBoxMessage "Detected OS build version is $($OSBuild) running PowerShell version $($host.Version)"
		$WinFeatures = @("NET-Framework-Core","BITS","BITS-IIS-Ext","BITS-Compact-Server","RDC","WAS-Process-Model","WAS-Config-APIs","WAS-Net-Environment","Web-Server","Web-ISAPI-Ext","Web-Windows-Auth","Web-Basic-Auth","Web-URL-Auth","Web-IP-Security","Web-Scripting-Tools","Web-Mgmt-Service","Web-Metabase","Web-WMI")
	}
    $ProgressBar.Maximum = ($WinFeatures | Measure-Object).Count
    $ProgressPreference = "SilentlyContinue"
	$WarningPreference = "SilentlyContinue"	
    $ButtonBack.Enabled = $false
    $ButtonInstallSecondarySite.Enabled = $false
	$WinFeatures | ForEach-Object {
        $CurrentFeature = $_
		$CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (-NOT(Get-WindowsFeature -Name $CurrentFeature | Select-Object Name,Installed | Where-Object { $_.Installed -like "true" })) {
        	Write-OutputBox -OutputBoxMessage "Installing role: $($CurrentFeatureDisplayName.DisplayName)"
			[System.Windows.Forms.Application]::DoEvents()
            if (([System.Environment]::OSVersion.Version).Build -lt 9200) {
   			    Add-WindowsFeature $CurrentFeature | Out-Null
            }
            if (([System.Environment]::OSVersion.Version).Build -ge 9200) {
                if ($CurrentFeature -eq "NET-Framework-Core") {
                    Add-WindowsFeature NET-Framework-Core -ErrorAction SilentlyContinue | Out-Null
                    if (Get-WindowsFeature -Name NET-Framework-Core | Select-Object Name,Installed | Where-Object { $_.Installed -like "false" }) {
                        Write-OutputBox -OutputBoxMessage "Failed to install $($CurrentFeatureDisplayName.DisplayName)" -Type "ERROR: "

                        do {
                            if (([System.Environment]::OSVersion.Version).Build -eq 9600) {
			                    $SetupDLLocation = Read-FolderBrowserDialog -Message "Browse the Windows Server 2012 R2 installation media for the '<drive-letter>:\sources\sxs' folder."
                            }
                            if (([System.Environment]::OSVersion.Version).Build -eq 9200) {
                                $SetupDLLocation = Read-FolderBrowserDialog -Message "Browse the Windows Server 2012 installation media for the '<drive-letter>:\sources\sxs' folder."
                            }
		                }
                        until (($SetupDLLocation.Length -gt 0) -and (Test-Path -Path "$($SetupDLLocation.SubString(0,2))\sources\sxs" -ErrorAction SilentlyContinue))
                        Write-OutputBox -OutputBoxMessage "Installing role with specified source location: $($CurrentFeatureDisplayName.DisplayName)"
                        Add-WindowsFeature NET-Framework-Core -Source $SetupDLLocation
                    }
                }
                else {
			        Start-Job -Name $CurrentFeature -ScriptBlock {
    			        param(
        			        [parameter(Mandatory=$true)]
        			        $CurrentFeature
    			        )
    			        Add-WindowsFeature $CurrentFeature
			        } -ArgumentList $CurrentFeature | Out-Null
			        Wait-Job -Name $CurrentFeature
			        Remove-Job -Name $CurrentFeature
                }
            }
        }
        else {
            Write-OutputBox -OutputBoxMessage "Skipping role (already installed): $($CurrentFeatureDisplayName.DisplayName)"
        }
        $ProgressBar.PerformStep()
    }
    Write-OutputBox -OutputBoxMessage "Starting verification that all features where successfully installed"
    $ErrorVerify = 0
    $ProgressBar.Value = 0
    $WinFeatures | ForEach-Object {
        $CurrentFeature = $_
        $CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (Get-WindowsFeature $CurrentFeature | Where-Object { $_.Installed -eq $true}) {
            Write-OutputBox "Verified installed: $($CurrentFeatureDisplayName.DisplayName)"
            $ProgressBar.PerformStep()
        }
        else {
            $ErrorVerify++
            Write-OutputBox "Feature not installed: $($CurrentFeatureDisplayName.DisplayName)"
            $ProgressBar.PerformStep()
        }
    }
    if ($ErrorVerify -eq 0) {
	    Write-OutputBox -OutputBoxMessage "Successfully installed all required Windows Features"
    }
    else {
        Write-OutputBox -OutputBoxMessage "One or more Windows Features was not installed"
    }
	$ButtonBack.Enabled = $true
	$Form.Controls.Remove($ButtonInstallSecondarySite)
    $Form.Controls.Add($ButtonFinish)
}

function Install-AppCat {
	$OSBuild = ([System.Environment]::OSVersion.Version).Build
    if (($OSBuild -eq 7600) -or ($OSBuild -eq 7601)) {
		Write-OutputBox -OutputBoxMessage "Detected OS build version is $($OSBuild) running PowerShell version $($host.Version)"
		$WinFeatures = @("NET-Framework-Core","NET-HTTP-Activation","NET-Non-HTTP-Activ","RDC","WAS","WAS-Process-Model","WAS-NET-Environment","WAS-Config-APIs","Web-Server","Web-WebServer","Web-Common-Http","Web-Static-Content","Web-Default-Doc","Web-App-Dev","Web-ASP-Net","Web-Net-Ext","Web-ISAPI-Ext","Web-ISAPI-Filter","Web-Security","Web-Windows-Auth","Web-Filtering","Web-Mgmt-Tools","Web-Mgmt-Console","Web-Scripting-Tools","Web-Mgmt-Compat","Web-Metabase","Web-Lgcy-Mgmt-Console","Web-Lgcy-Scripting","Web-WMI")
	}
	if ($OSBuild -ge 9200) {
		Write-OutputBox -OutputBoxMessage "Detected OS build version is $($OSBuild) running PowerShell version $($host.Version)"
		$WinFeatures = @("NET-Framework-Features","NET-Framework-Core","NET-HTTP-Activation","NET-Non-HTTP-Activ","NET-WCF-Services45","NET-WCF-HTTP-Activation45","RDC","WAS","WAS-Process-Model","WAS-NET-Environment","WAS-Config-APIs","Web-Server","Web-WebServer","Web-Common-Http","Web-Static-Content","Web-Default-Doc","Web-App-Dev","Web-ASP-Net","Web-ASP-Net45","Web-Net-Ext","Web-Net-Ext45","Web-ISAPI-Ext","Web-ISAPI-Filter","Web-Security","Web-Windows-Auth","Web-Filtering","Web-Mgmt-Tools","Web-Mgmt-Console","Web-Scripting-Tools","Web-Mgmt-Compat","Web-Metabase","Web-Lgcy-Mgmt-Console","Web-Lgcy-Scripting","Web-WMI")
	}
    $ProgressBar.Maximum = ($WinFeatures | Measure-Object).Count
    $ProgressPreference = "SilentlyContinue"
	$WarningPreference = "SilentlyContinue"
    $ButtonBack.Enabled = $false
    $ButtonInstallAppCat.Enabled = $false
	$WinFeatures | ForEach-Object {
        $CurrentFeature = $_
		$CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (-NOT(Get-WindowsFeature -Name $CurrentFeature | Select-Object Name,Installed | Where-Object { $_.Installed -like "true" })) {
        	Write-OutputBox -OutputBoxMessage "Installing role: $($CurrentFeatureDisplayName.DisplayName)"
			[System.Windows.Forms.Application]::DoEvents()
            if (([System.Environment]::OSVersion.Version).Build -lt 9200) {
   			    Add-WindowsFeature $CurrentFeature | Out-Null
            }
            if (([System.Environment]::OSVersion.Version).Build -ge 9200) {
                if ($CurrentFeature -eq "NET-Framework-Core") {
                    Add-WindowsFeature NET-Framework-Core -ErrorAction SilentlyContinue | Out-Null
                    if (Get-WindowsFeature -Name NET-Framework-Core | Select-Object Name,Installed | Where-Object { $_.Installed -like "false" }) {
                        Write-OutputBox -OutputBoxMessage "Failed to install $($CurrentFeatureDisplayName.DisplayName)" -Type "ERROR: "

                        do {
                            if (([System.Environment]::OSVersion.Version).Build -eq 9600) {
			                    $SetupDLLocation = Read-FolderBrowserDialog -Message "Browse the Windows Server 2012 R2 installation media for the '<drive-letter>:\sources\sxs' folder."
                            }
                            if (([System.Environment]::OSVersion.Version).Build -eq 9200) {
                                $SetupDLLocation = Read-FolderBrowserDialog -Message "Browse the Windows Server 2012 installation media for the '<drive-letter>:\sources\sxs' folder."
                            }
		                }
                        until (($SetupDLLocation.Length -gt 0) -and (Test-Path -Path "$($SetupDLLocation.SubString(0,2))\sources\sxs" -ErrorAction SilentlyContinue))
                        Write-OutputBox -OutputBoxMessage "Installing role with specified source location: $($CurrentFeatureDisplayName.DisplayName)"
                        Add-WindowsFeature NET-Framework-Core -Source $SetupDLLocation
                    }
                }
                else {
			        Start-Job -Name $CurrentFeature -ScriptBlock {
    			        param(
        			        [parameter(Mandatory=$true)]
        			        $CurrentFeature
    			        )
    			        Add-WindowsFeature $CurrentFeature
			        } -ArgumentList $CurrentFeature | Out-Null
			        Wait-Job -Name $CurrentFeature
			        Remove-Job -Name $CurrentFeature
                }
            }
        }
        else {
            Write-OutputBox -OutputBoxMessage "Skipping role (already installed): $($CurrentFeatureDisplayName.DisplayName)"
        }
        $ProgressBar.PerformStep()
    }
    Write-OutputBox -OutputBoxMessage "Starting verification that all features where successfully installed"
    $ErrorVerify = 0
    $ProgressBar.Value = 0
    $WinFeatures | ForEach-Object {
        $CurrentFeature = $_
        $CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (Get-WindowsFeature $CurrentFeature | Where-Object { $_.Installed -eq $true}) {
            Write-OutputBox "Verified installed: $($CurrentFeatureDisplayName.DisplayName)"
            $ProgressBar.PerformStep()
        }
        else {
            $ErrorVerify++
            Write-OutputBox "Feature not installed: $($CurrentFeatureDisplayName.DisplayName)"
            $ProgressBar.PerformStep()
        }
    }
    if ($ErrorVerify -eq 0) {
	    Write-OutputBox -OutputBoxMessage "Successfully installed all required Windows Features"
    }
    else {
        Write-OutputBox -OutputBoxMessage "One or more Windows Features was not installed"
    }
	$ButtonBack.Enabled = $true
	$Form.Controls.Remove($ButtonInstallAppCat)
    $Form.Controls.Add($ButtonFinish)		
}

function Install-MP {
	$OSBuild = ([System.Environment]::OSVersion.Version).Build
    if (($OSBuild -eq 7600) -or ($OSBuild -eq 7601)) {
		Write-OutputBox -OutputBoxMessage "Detected OS build version is $($OSBuild) running PowerShell version $($host.Version)"
		$WinFeatures = @("BITS","BITS-IIS-Ext","BITS-Compact-Server","RSAT-Bits-Server","Web-Server","Web-WebServer","Web-ISAPI-Ext","Web-WMI","Web-Metabase","Web-Windows-Auth","Web-ISAPI-Ext")
	}
	if ($OSBuild -ge 9200) {
		Write-OutputBox -OutputBoxMessage "Detected OS build version is $($OSBuild) running PowerShell version $($host.Version)"
		$WinFeatures = @("NET-Framework-45-Features","NET-Framework-45-Core","NET-WCF-TCP-PortSharing45","NET-WCF-Services45","BITS","BITS-IIS-Ext","BITS-Compact-Server","RSAT-Bits-Server","Web-Server","Web-WebServer","Web-ISAPI-Ext","Web-WMI","Web-Metabase","Web-Windows-Auth","Web-ISAPI-Ext")
	}
    $ProgressBar.Maximum = ($WinFeatures | Measure-Object).Count
    $ProgressPreference = "SilentlyContinue"
	$WarningPreference = "SilentlyContinue"
    $ButtonBack.Enabled = $false
    $ButtonInstallMP.Enabled = $false
	$WinFeatures | ForEach-Object {
        $CurrentFeature = $_
		$CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (-NOT(Get-WindowsFeature -Name $CurrentFeature | Select-Object Name,Installed | Where-Object { $_.Installed -like "true" })) {
        	Write-OutputBox -OutputBoxMessage "Installing role: $($CurrentFeatureDisplayName.DisplayName)"
			[System.Windows.Forms.Application]::DoEvents()
            if (([System.Environment]::OSVersion.Version).Build -lt 9200) {
   			    Add-WindowsFeature $CurrentFeature | Out-Null
            }
            if (([System.Environment]::OSVersion.Version).Build -ge 9200) {
                if ($CurrentFeature -eq "NET-Framework-Core") {
                    Add-WindowsFeature NET-Framework-Core -ErrorAction SilentlyContinue | Out-Null
                    if (Get-WindowsFeature -Name NET-Framework-Core | Select-Object Name,Installed | Where-Object { $_.Installed -like "false" }) {
                        Write-OutputBox -OutputBoxMessage "Failed to install $($CurrentFeatureDisplayName.DisplayName)" -Type "ERROR: "

                        do {
                            if (([System.Environment]::OSVersion.Version).Build -eq 9600) {
			                    $SetupDLLocation = Read-FolderBrowserDialog -Message "Browse the Windows Server 2012 R2 installation media for the '<drive-letter>:\sources\sxs' folder."
                            }
                            if (([System.Environment]::OSVersion.Version).Build -eq 9200) {
                                $SetupDLLocation = Read-FolderBrowserDialog -Message "Browse the Windows Server 2012 installation media for the '<drive-letter>:\sources\sxs' folder."
                            }
		                }
                        until (($SetupDLLocation.Length -gt 0) -and (Test-Path -Path "$($SetupDLLocation.SubString(0,2))\sources\sxs" -ErrorAction SilentlyContinue))
                        Write-OutputBox -OutputBoxMessage "Installing role with specified source location: $($CurrentFeatureDisplayName.DisplayName)"
                        Add-WindowsFeature NET-Framework-Core -Source $SetupDLLocation
                    }
                }
                else {
			        Start-Job -Name $CurrentFeature -ScriptBlock {
    			        param(
        			        [parameter(Mandatory=$true)]
        			        $CurrentFeature
    			        )
    			        Add-WindowsFeature $CurrentFeature
			        } -ArgumentList $CurrentFeature | Out-Null
			        Wait-Job -Name $CurrentFeature
			        Remove-Job -Name $CurrentFeature
                }
            }
        }
        else {
            Write-OutputBox -OutputBoxMessage "Skipping role (already installed): $($CurrentFeatureDisplayName.DisplayName)"
        }
        $ProgressBar.PerformStep()
    }
    if ((Get-WmiObject -Namespace root\cimv2 -Class Win32_OperatingSystem).BuildNumber -lt 9200) {
	    $HKLM = "HKEY_LOCAL_MACHINE"
        $RegKey = "SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"
        $GetValue = [Microsoft.Win32.Registry]::GetValue("$($HKLM)\$($RegKey)","Install",$Null)
        $dotNETInstallArgs = "/q /norestart"
        $ShellObject = New-Object -ComObject Wscript.Shell
	    if ($GetValue -ne 1) {
            $PopupContinue = $ShellObject.Popup("Would you like to download .NET Framework 4.0 Full?`nPress OK to download the setup or Cancel to `nspecify a location to the setup.",0,"Prerequisites",1)
            if (($PopupContinue -eq 1) -and ($GetValue -ne 1)) {
                $dotNETDownloadPath = "C:\Downloads"
                $dotNETFileName = "dotNetFx40_Full_x86_x64.exe"
                Write-OutputBox -OutputBoxMessage "Starting download of .NET Framework 4.0 Full to $($dotNETDownloadPath)" -Type "INFO: "
                Get-WebDownloadFile -URL "http://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe" -DownloadFolder $dotNETDownloadPath -FileName $dotNETFileName
                [System.Windows.Forms.Application]::DoEvents()
                Write-OutputBox -OutputBoxMessage "Successfully downloaded .NET Framework 4.0 Full" -Type "INFO: "
                [System.Windows.Forms.Application]::DoEvents()
                Start-Process -FilePath "$($dotNETDownloadPath)\$($dotNETFileName)" -ArgumentList $dotNETInstallArgs -Wait
                $dotNETInstallValue = [Microsoft.Win32.Registry]::GetValue("$($HKLM)\$($RegKey)","Install",$Null)
                if ($dotNETInstallValue -eq 1) {
                    Write-OutputBox -OutputBoxMessage "Successfully installed .NET Framework 4.0" -Type "INFO: "
                }
                else {
                    Write-OutputBox -OutputBoxMessage "An error occured during the installation of .NET Framework 4.0 Full, application was not detected" -Type "ERROR: "
                }

            }
            elseif (($PopupContinue -ne 1) -and ($GetValue -ne 1)) {
                do {
                    $SetupDLNetFramework = Read-FolderBrowserDialog -Message "Select the folder where dotNetFx40_Full_x86_x64.exe is located:"
                }
                until (Test-Path -Path "$($SetupDLNetFramework)\dotNetFx40_Full_x86_x64.exe")
                Write-OutputBox -OutputBoxMessage "Installing .NET Framework 4.0 Full, this will take some time" -Type "INFO: "
                [System.Windows.Forms.Application]::DoEvents()
                Start-Process -FilePath "$($SetupDLNetFramework)\dotNetFx40_Full_x86_x64.exe" -ArgumentList $dotNETInstallArgs -Wait
                $dotNETInstallValue = [Microsoft.Win32.Registry]::GetValue("$($HKLM)\$($RegKey)","Install",$Null)
                if ($dotNETInstallValue -eq 1) {
                    Write-OutputBox -OutputBoxMessage "Successfully installed .NET Framework 4.0" -Type "INFO: "
                }
                else {
                    Write-OutputBox -OutputBoxMessage "An error occured during the installation of .NET Framework 4.0 Full, application was not detected" -Type "ERROR: "
                }
            }
        }
        elseif ($GetValue -eq 1) {
            Write-OutputBox -OutputBoxMessage "Detected that .NET Framework 4.0 Full is already installed, skipping install" -Type "INFO: "
        }
    }
    Write-OutputBox -OutputBoxMessage "Starting verification that all features where successfully installed"
    $ErrorVerify = 0
    $ProgressBar.Value = 0
    $WinFeatures | ForEach-Object {
        $CurrentFeature = $_
        $CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (Get-WindowsFeature $CurrentFeature | Where-Object { $_.Installed -eq $true}) {
            Write-OutputBox "Verified installed: $($CurrentFeatureDisplayName.DisplayName)"
            $ProgressBar.PerformStep()
        }
        else {
            $ErrorVerify++
            Write-OutputBox "Feature not installed: $($CurrentFeatureDisplayName.DisplayName)"
            $ProgressBar.PerformStep()
        }
    }
    if ($ErrorVerify -eq 0) {
	    Write-OutputBox -OutputBoxMessage "Successfully installed all required Windows Features"
    }
    else {
        Write-OutputBox -OutputBoxMessage "One or more Windows Features was not installed"
    }
	$ButtonBack.Enabled = $true
	$Form.Controls.Remove($ButtonInstallMP)
    $Form.Controls.Add($ButtonFinish)		
}

function Install-DP {
	$OSBuild = ([System.Environment]::OSVersion.Version).Build
    if (($OSBuild -eq 7600) -or ($OSBuild -eq 7601)) {
		Write-OutputBox -OutputBoxMessage "Detected OS build version is $($OSBuild) running PowerShell version $($host.Version)"
		$WinFeatures = @("FS-FileServer","RDC","Web-WebServer","Web-Common-Http","Web-Default-Doc","Web-Dir-Browsing","Web-Http-Errors","Web-Static-Content","Web-Http-Redirect","Web-Health","Web-Http-Logging","Web-Performance","Web-Stat-Compression","Web-Security","Web-Filtering","Web-Windows-Auth","Web-App-Dev","Web-ISAPI-Ext","Web-Mgmt-Tools","Web-Mgmt-Console","Web-Mgmt-Compat","Web-Metabase","Web-WMI","Web-Scripting-Tools")
	}
	if ($OSBuild -ge 9200) {
		Write-OutputBox -OutputBoxMessage "Detected OS build version is $($OSBuild) running PowerShell version $($host.Version)"
		$WinFeatures = @("FS-FileServer","RDC","Web-WebServer","Web-Common-Http","Web-Default-Doc","Web-Dir-Browsing","Web-Http-Errors","Web-Static-Content","Web-Http-Redirect","Web-Health","Web-Http-Logging","Web-Performance","Web-Stat-Compression","Web-Security","Web-Filtering","Web-Windows-Auth","Web-App-Dev","Web-ISAPI-Ext","Web-Mgmt-Tools","Web-Mgmt-Console","Web-Mgmt-Compat","Web-Metabase","Web-WMI","Web-Scripting-Tools")
	}
	$ProgressBar.Maximum = ($WinFeatures | Measure-Object).Count
    $ProgressPreference = "SilentlyContinue"
	$WarningPreference = "SilentlyContinue"
    $ButtonBack.Enabled = $false
    $ButtonInstallDP.Enabled = $false
	$WinFeatures | ForEach-Object {
        $CurrentFeature = $_
		$CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (-NOT(Get-WindowsFeature -Name $CurrentFeature | Select-Object Name,Installed | Where-Object { $_.Installed -like "true" })) {
        	Write-OutputBox -OutputBoxMessage "Installing role: $($CurrentFeatureDisplayName.DisplayName)"
			[System.Windows.Forms.Application]::DoEvents()
            if (([System.Environment]::OSVersion.Version).Build -lt 9200) {
   			    Add-WindowsFeature $CurrentFeature | Out-Null
            }
            if (([System.Environment]::OSVersion.Version).Build -ge 9200) {
			    Start-Job -Name $CurrentFeature -ScriptBlock {
    			    param(
        			    [parameter(Mandatory=$true)]
        			    $CurrentFeature
    			    )
    			    Add-WindowsFeature $CurrentFeature
			    } -ArgumentList $CurrentFeature | Out-Null
			    Wait-Job -Name $CurrentFeature
			    Remove-Job -Name $CurrentFeature
            }
        }
        else {
            Write-OutputBox -OutputBoxMessage "Skipping role (already installed): $($CurrentFeatureDisplayName.DisplayName)"
        }
        $ProgressBar.PerformStep()
    }
    Write-OutputBox -OutputBoxMessage "Starting verification that all features where successfully installed"
    $ErrorVerify = 0
    $ProgressBar.Value = 0
    $WinFeatures | ForEach-Object {
        $CurrentFeature = $_
        $CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (Get-WindowsFeature $CurrentFeature | Where-Object { $_.Installed -eq $true}) {
            Write-OutputBox "Verified installed: $($CurrentFeatureDisplayName.DisplayName)"
            $ProgressBar.PerformStep()
        }
        else {
            $ErrorVerify++
            Write-OutputBox "Feature not installed: $($CurrentFeatureDisplayName.DisplayName)"
            $ProgressBar.PerformStep()
        }
    }
    if ($ErrorVerify -eq 0) {
	    Write-OutputBox -OutputBoxMessage "Successfully installed all required Windows Features"
    }
    else {
        Write-OutputBox -OutputBoxMessage "One or more Windows Features was not installed"
    }
	$ButtonBack.Enabled = $true
	$Form.Controls.Remove($ButtonInstallDP)
    $Form.Controls.Add($ButtonFinish)			
}

function Install-EP {
    $RadioButtonEP.Enabled = $false
    $RadioButtonEPP.Enabled = $false
	$OSBuild = ([System.Environment]::OSVersion.Version).Build
    if ($RadioButtonEP.Checked -eq $true) {
	    if ($OSBuild -ge 9200) {
		    Write-OutputBox -OutputBoxMessage "Detected OS build version is $($OSBuild) running PowerShell version $($host.Version)"
		    $WinFeatures = @("Web-Server","Web-WebServer","Web-Default-Doc","Web-Dir-Browsing","Web-Http-Errors","Web-Static-Content","Web-Http-Logging","Web-Stat-Compression","Web-Filtering","Web-Net-Ext","Web-Asp-Net","Web-ISAPI-Ext","Web-ISAPI-Filter","Web-Mgmt-Console","Web-Metabase","NET-Framework-Core","NET-Framework-Features","NET-HTTP-Activation","NET-Framework-45-Features","NET-Framework-45-Core","NET-Framework-45-ASPNET","NET-WCF-Services45","NET-WCF-TCP-PortSharing45")
	    }
    }
    if ($RadioButtonEPP.Checked -eq $true) {
	    if ($OSBuild -ge 9200) {
		    Write-OutputBox -OutputBoxMessage "Detected OS build version is $($OSBuild) running PowerShell version $($host.Version)"
		    $WinFeatures = @("Web-Server","Web-WebServer","Web-Default-Doc","Web-Dir-Browsing","Web-Http-Errors","Web-Static-Content","Web-Http-Logging","Web-Stat-Compression","Web-Filtering","Web-Windows-Auth","Web-Net-Ext","Web-Net-Ext45","Web-Asp-Net","Web-Asp-Net45","Web-ISAPI-Ext","Web-ISAPI-Filter","Web-Mgmt-Console","Web-Metabase","NET-Framework-Core","NET-Framework-Features","NET-Framework-45-Features","NET-Framework-45-Core","NET-Framework-45-ASPNET","NET-WCF-Services45","NET-WCF-TCP-PortSharing45")
	    }
    }
    $ProgressBar.Maximum = ($WinFeatures | Measure-Object).Count
    $ProgressPreference = "SilentlyContinue"
	$WarningPreference = "SilentlyContinue"
    $ButtonBack.Enabled = $false
    $ButtonInstallEP.Enabled = $false
	$WinFeatures | ForEach-Object {
        $CurrentFeature = $_
		$CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (-NOT(Get-WindowsFeature -Name $CurrentFeature | Select-Object Name,Installed | Where-Object { $_.Installed -like "true" })) {
        	Write-OutputBox -OutputBoxMessage "Installing role: $($CurrentFeatureDisplayName.DisplayName)"
			[System.Windows.Forms.Application]::DoEvents()
            if (([System.Environment]::OSVersion.Version).Build -lt 9200) {
   			    Add-WindowsFeature $CurrentFeature | Out-Null
            }
            if (([System.Environment]::OSVersion.Version).Build -ge 9200) {
                if ($CurrentFeature -eq "NET-Framework-Core") {
                    Add-WindowsFeature NET-Framework-Core -ErrorAction SilentlyContinue | Out-Null
                    if (Get-WindowsFeature -Name NET-Framework-Core | Select-Object Name,Installed | Where-Object { $_.Installed -like "false" }) {
                        Write-OutputBox -OutputBoxMessage "Failed to install $($CurrentFeatureDisplayName.DisplayName)" -Type "ERROR: "

                        do {
                            if (([System.Environment]::OSVersion.Version).Build -eq 9600) {
			                    $SetupDLLocation = Read-FolderBrowserDialog -Message "Browse the Windows Server 2012 R2 installation media for the '<drive-letter>:\sources\sxs' folder."
                            }
                            if (([System.Environment]::OSVersion.Version).Build -eq 9200) {
                                $SetupDLLocation = Read-FolderBrowserDialog -Message "Browse the Windows Server 2012 installation media for the '<drive-letter>:\sources\sxs' folder."
                            }
		                }
                        until (($SetupDLLocation.Length -gt 0) -and (Test-Path -Path "$($SetupDLLocation.SubString(0,2))\sources\sxs" -ErrorAction SilentlyContinue))
                        Write-OutputBox -OutputBoxMessage "Installing role with specified source location: $($CurrentFeatureDisplayName.DisplayName)"
                        Add-WindowsFeature NET-Framework-Core -Source $SetupDLLocation
                    }
                }
                else {
			        Start-Job -Name $CurrentFeature -ScriptBlock {
    			        param(
        			        [parameter(Mandatory=$true)]
        			        $CurrentFeature
    			        )
    			        Add-WindowsFeature $CurrentFeature
			        } -ArgumentList $CurrentFeature | Out-Null
			        Wait-Job -Name $CurrentFeature
			        Remove-Job -Name $CurrentFeature
                }
            }
        }
        else {
            Write-OutputBox -OutputBoxMessage "Skipping role (already installed): $($CurrentFeatureDisplayName.DisplayName)"
        }
        $ProgressBar.PerformStep()
    }
    Write-OutputBox -OutputBoxMessage "Starting verification that all features where successfully installed"
    $ErrorVerify = 0
    $ProgressBar.Value = 0
    $WinFeatures | ForEach-Object {
        $CurrentFeature = $_
        $CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (Get-WindowsFeature $CurrentFeature | Where-Object { $_.Installed -eq $true}) {
            Write-OutputBox "Verified installed: $($CurrentFeatureDisplayName.DisplayName)"
            $ProgressBar.PerformStep()
        }
        else {
            $ErrorVerify++
            Write-OutputBox "Feature not installed: $($CurrentFeatureDisplayName.DisplayName)"
            $ProgressBar.PerformStep()
        }
    }
    if ($ErrorVerify -eq 0) {
	    Write-OutputBox -OutputBoxMessage "Successfully installed all required Windows Features"
    }
    else {
        Write-OutputBox -OutputBoxMessage "One or more Windows Features was not installed"
    }
	$ButtonBack.Enabled = $true
	$Form.Controls.Remove($ButtonInstallEP)
    $Form.Controls.Add($ButtonFinish)		
}

function Extend-ActiveDirectorySchema {
	$Form.Controls.Remove($ButtonConnectDC)
	$Form.Controls.Add($ButtonExtendActiveDirectory)
	$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent() 
	$WindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($CurrentUser)
	if (($WindowsPrincipal.IsInRole("Domain Admins")) -and ($WindowsPrincipal.IsInRole("Schema Admins"))) {
    	do { 
			$SetupDLLocation = Read-FolderBrowserDialog -Message "Browse to the '<ConfigMgr source files>\SMSSETUP\BIN\X64' folder."
		}
		until (Test-Path -Path "$($SetupDLLocation)\EXTADSCH.EXE")
    	$DC = $TextBoxDC.Text
    	$GetPath = Get-ChildItem -Recurse -Filter "EXTADSCH.EXE" -Path "$($SetupDLLocation)"
    	$Path = $GetPath.DirectoryName + "\EXTADSCH.EXE"
    	$Destination = "\\" + $DC + "\C$"
		Write-OutputBox -OutputBoxMessage "Copying EXTADSCH.EXE to the specified domain controller"
    	Copy-Item $Path $Destination -Force
		Write-OutputBox -OutputBoxMessage "Starting to extend the Active Directory schema"
    	Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList "C:\EXTADSCH.EXE" -ComputerName $DC | Out-Null
		Start-Sleep -Seconds 10
    	$Content = Get-Content -Path "\\$($DC)\C$\extadsch.log"
    	if ($Content -match "Successfully extended the Active Directory schema") {
        	Write-OutputBox -OutputBoxMessage "Active Directory schema was successfully extended"
			$Form.Controls.Remove($ButtonInstallExtendAD)
			$Form.Controls.Add($ButtonFinish)
    	}
    	else {
			Write-OutputBox -OutputBoxMessage "Active Directory was not extended successfully, refer to C:\ExtADSch.log on the domain controller" -Type "ERROR: "
    	}
	}
	else {
		Write-OutputBox -OutputBoxMessage "Current logged on user is not a member of the Domain Admins group" -Type "ERROR: "

	}
}

function Install-WSUS {
    $RadioButtonWID.Enabled = $false
    $RadioButtonSQL.Enabled = $false
    $TextBoxWSUSSQLServer.Enabled = $false
    $TextBoxWSUSSQLInstance.Enabled = $false
    if ($RadioButtonWID.Checked -eq $true) {
        $WinFeatures = @("UpdateServices","UpdateServices-WidDB","UpdateServices-Services","UpdateServices-RSAT","UpdateServices-API","UpdateServices-UI")
    }
    if ($RadioButtonSQL.Checked -eq $true) {
        $WinFeatures = @("UpdateServices-Services","UpdateServices-RSAT","UpdateServices-API","UpdateServices-UI","UpdateServices-DB")    
    }
    $ProgressBar.Maximum = 10
    $ProgressPreference = "SilentlyContinue"
	$WarningPreference = "SilentlyContinue"	
    $ButtonBack.Enabled = $false
    $ButtonInstallWSUS.Enabled = $false
	$ProgressBar.PerformStep()
	$WinFeatures | ForEach-Object {
        $CurrentFeature = $_
		$CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (-NOT(Get-WindowsFeature -Name $CurrentFeature | Select-Object Name,Installed | Where-Object { $_.Installed -like "true" })) {
        	Write-OutputBox -OutputBoxMessage "Installing role: $($CurrentFeatureDisplayName.DisplayName)"
			Start-Job -Name $CurrentFeature -ScriptBlock {
    			param(
        			[parameter(Mandatory=$true)]
        			$CurrentFeature
    			)
    			Add-WindowsFeature $CurrentFeature
			} -ArgumentList $CurrentFeature | Out-Null
			Wait-Job -Name $CurrentFeature
			Remove-Job -Name $CurrentFeature
        }
        else {
            Write-OutputBox -OutputBoxMessage "Skipping role (already installed): $($CurrentFeatureDisplayName.DisplayName)"
        }
        $ProgressBar.PerformStep()
    }
	Write-OutputBox -OutputBoxMessage "Successfully installed all required Windows Features"
	$WSUSContentPath = Read-FolderBrowserDialog -Message "Choose a location where WSUS content will be stored, e.g. C:\WSUS"
	$ProgressBar.PerformStep()
    if (!(Test-Path -Path $WSUSContentPath)) {
            New-Item $WSUSContentPath -ItemType Directory | Out-Null
    }
	if (Test-Path -Path "$Env:ProgramFiles\Update Services\Tools\WsusUtil.exe") {
        $WSUSUtil = "$Env:ProgramFiles\Update Services\Tools\WsusUtil.exe"
        if ($RadioButtonWID.Checked -eq $true) {
            $WSUSUtilArgs = "POSTINSTALL CONTENT_DIR=$WSUSContentPath"
        }
        if ($RadioButtonSQL.Checked -eq $true) {
            if (($TextBoxWSUSSQLServer.Text.Length -ge 1) -and ($TextBoxWSUSSQLServer.Text -notlike $WaterMarkWSUSSQLServer) -and ($TextBoxWSUSSQLInstance.Text -like $WaterMarkWSUSSQLInstance)) {
                Write-OutputBox -OutputBoxMessage "Choosen configuration is SQL Server, default instance" -Type "INFO: "
                $WSUSUtilArgs = "POSTINSTALL SQL_INSTANCE_NAME=$($TextBoxWSUSSQLServer.Text) CONTENT_DIR=$($WSUSContentPath)"
            }
            if (($TextBoxWSUSSQLServer.Text.Length -ge 1) -and ($TextBoxWSUSSQLServer.Text -notlike $WaterMarkWSUSSQLServer) -and ($TextBoxWSUSSQLInstance.Text.Length -ge 1) -and ($TextBoxWSUSSQLInstance.Text -notlike $WaterMarkWSUSSQLInstance)) {
                Write-OutputBox -OutputBoxMessage "Choosen configuration is SQL Server, named instance" -Type "INFO: "
                $WSUSUtilArgs = "POSTINSTALL SQL_INSTANCE_NAME=$($TextBoxWSUSSQLServer.Text)\$($TextBoxWSUSSQLInstance.Text) CONTENT_DIR=$($WSUSContentPath)"
		    }
        }
    	Write-OutputBox -OutputBoxMessage "Starting WSUS post install configuration"
		$ProgressBar.PerformStep()
    	Start-Process -FilePath $WSUSUtil -ArgumentList $WSUSUtilArgs -NoNewWindow -Wait -RedirectStandardOutput "C:\temp.txt" | Out-Null
		$ProgressBar.PerformStep()
    	Write-OutputBox -OutputBoxMessage "Successfully installed and configured WSUS"
        Remove-Item "C:\temp.txt" -Force
		$ButtonBack.Enabled = $true
		$Form.Controls.Remove($ButtonInstallWSUS)
    	$Form.Controls.Add($ButtonFinish)
	}
    else {
		$ProgressBar.PerformStep()
		Write-OutputBox -OutputBoxMessage "Unable to locate $($WSUSUtil)"
		$ProgressBar.PerformStep()
		$ButtonBack.Enabled = $true
		$ButtonInstallWSUS.Enabled = $true
	}
}

function Install-ADK {
	$RadioButtonOnline.Enabled = $false
	$RadioButtonOffline.Enabled = $false
	$ButtonInstallADK.Enabled = $false
	$ButtonBack.Enabled = $false
    $ADKInstalledFeatures = @()
    $ComputerName = $env:COMPUTERNAME
    $UninstallKey = "SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
    $Registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$ComputerName)
    $RegistryKey = $Registry.OpenSubKey($UninstallKey)
    $SubKeys = $RegistryKey.GetSubKeyNames()
    ForEach ($Key in $SubKeys) {
        $CurrentKey = $UninstallKey + "\\" + $Key
        $CurrentSubKey = $Registry.OpenSubKey($CurrentKey)
        $DisplayName = $CurrentSubKey.GetValue("DisplayName")
        if ($DisplayName -like "Windows PE x86 x64") {
            $ADKInstalledFeatures += $DisplayName
        }
        elseif ($DisplayName -like "User State Migration Tool") {
            $ADKInstalledFeatures += $DisplayName
        }
        elseif ($DisplayName -like "Windows Deployment Tools") {
            $ADKInstalledFeatures += $DisplayName
        }
    }
	if (($RadioButtonOnline.Checked -eq $true) -AND ($ADKInstalledFeatures.Length -ne 3)) {
		$ADKOnlineArguments = "/norestart /q /ceip off /features OptionId.WindowsPreinstallationEnvironment OptionId.DeploymentTools OptionId.UserStateMigrationTool"
		$ADKDownloadFolder = "C:\Downloads"
		$ADKSetupFile = "adksetup.exe"
		Get-WebDownloadFile -URL "http://download.microsoft.com/download/6/A/E/6AEA92B0-A412-4622-983E-5B305D2EBE56/adk/adksetup.exe" -DownloadFolder $ADKDownloadFolder -FileName $ADKSetupFile
		Write-OutputBox -OutputBoxMessage "Download completed" -Type "INFO: "
		[System.Windows.Forms.Application]::DoEvents()
		Write-OutputBox -OutputBoxMessage "Starting Windows ADK installation" -Type "INFO: "
		[System.Windows.Forms.Application]::DoEvents()
		Write-OutputBox -OutputBoxMessage "Downloading Windows ADK components and installing, this will take some time" -Type "INFO: "
		[System.Windows.Forms.Application]::DoEvents()
		Start-Process -FilePath "$($ADKDownloadFolder)\$($ADKSetupFile)" -ArgumentList $ADKOnlineArguments
		while (Get-WmiObject -Class Win32_Process -Filter 'Name="adksetup.exe"') {
			[System.Windows.Forms.Application]::DoEvents()
			Start-Sleep -Milliseconds 500
		}
		Write-OutputBox -OutputBoxMessage "Successfully installed Windows ADK" -Type "INFO: "
	}
    elseif (($RadioButtonOffline.Checked -eq $true) -AND ($ADKInstalledFeatures.Length -ne 3)) {
        $ADKOfflineArguments = "/norestart /q /ceip off /features OptionId.WindowsPreinstallationEnvironment OptionId.DeploymentTools OptionId.UserStateMigrationTool"
		$ADKSetupFile = "adksetup.exe"
		do {
			$SetupLocation = Read-FolderBrowserDialog -Message "Select the folder where adksetup.exe is located"
			if (-not(Test-Path -Path "$($SetupLocation)\$($ADKSetupFile)")) {
				$ADKShellObject = New-Object -ComObject Wscript.Shell
				$PopupValidate = $ADKShellObject.Popup("Unable to find $($ADKSetupFile) in the selected folder",0,"Unable to locate file",0)
			}
		}
		until (Test-Path -Path "$($SetupLocation)\$($ADKSetupFile)")
        Write-OutputBox -OutputBoxMessage "Starting Windows ADK installation, this will take some time"
        Start-Process -FilePath "$($SetupLocation)\$($ADKSetupFile)" -ArgumentList $ADKOfflineArguments
		while (Get-WmiObject -Class Win32_Process -Filter 'Name="adksetup.exe"') {
			[System.Windows.Forms.Application]::DoEvents()
			Start-Sleep -Milliseconds 500
		}
		Write-OutputBox -OutputBoxMessage "Successfully installed Windows ADK"
    }    
    else {
        if ($ADKInstalledFeatures.Length -eq 3) {
            Write-OutputBox -OutputBoxMessage "All required Windows ADK features are already installed, skipping install" -Type "INFO: "
        }
    }
	$ButtonBack.Enabled = $true
	$Form.Controls.Remove($ButtonInstallADK)
	$Form.Controls.Add($ButtonFinish)
}

function Configure-SystemManagementContainerComputer {
    $OutputBox.ResetText()
    $ADDomain = New-Object System.DirectoryServices.DirectoryEntry | Select-Object -ExpandProperty distinguishedName
    try {
        $ADFilter = "(&(objectClass=container)(cn=*System Management*))"
        $ADSearch = New-Object System.DirectoryServices.DirectorySearcher($ADFilter) 
        $ADResult = $ADSearch.FindOne()
        $Container = $ADResult.GetDirectoryEntry()
    }
    catch {
        $SMCError = $_.Exception.Message
    }
    if ($CBSMCCreate.Checked -eq $true) {
        try {
            if ($Container) {
                Write-OutputBox -OutputBoxMessage "Found container $($ContainerDN)" -Type "INFO: "
                Write-OutputBox -OutputBoxMessage "System Management container found, will not create it" -Type "INFO: "
            }
            else {
                Write-OutputBox -OutputBoxMessage "System Management container not found" -Type "INFO: "
                Write-OutputBox -OutputBoxMessage "Creating the 'System Management' container" -Type "INFO: "
                $ObjectDomain = New-Object System.DirectoryServices.DirectoryEntry
                $ObjectContainer = $ObjectDomain.Create("container", "CN=System Management,CN=System")
                $ObjectContainer.SetInfo() | Out-Null
                Write-OutputBox -OutputBoxMessage "System Management container created successfully" -Type "INFO: "
            }
        }
        catch {
            Write-OutputBox -OutputBoxMessage "$($_.Exception.Message)" -Type "ERROR: "
        }
    }
    $SearchComputerAdded = {
        $ComputerFilter = "(&(ObjectClass=Computer)(samAccountName=*$($ComputerName)*))"
        $ComputerSearch = New-Object System.DirectoryServices.DirectorySearcher($ComputerFilter)
        $ComputerResult = $ComputerSearch.FindOne()
        $ComputerObjectSID = New-Object System.Security.Principal.SecurityIdentifier $ComputerResult.Properties["objectSID"][0],0
        [System.Security.Principal.SecurityIdentifier]$ComputerSID = $ComputerObjectSID.Value
        $ComputerIdentityReference = @()
        $ContainerObject = [ADSI]("LDAP://CN=System Management,CN=System,$($ADDomain)")
        $ContainerObject.ObjectSecurity.GetAccessRules($true,$true,[System.Security.Principal.SecurityIdentifier]) | ForEach-Object {
            $ComputerIdentityReference += $_.IdentityReference
        }
        if ($ComputerIdentityReference.Value -match $ComputerSID.Value) {
            return $true
        }
        else {
            return $false
        }
    }
    if (($RadioButtonSMCLocal.Checked -eq $true) -and ($Container)) {
        $ComputerName = $TextBoxSMCLocal.Text
        if ($SearchComputerAdded.Invoke()) {
            Write-OutputBox -OutputBoxMessage "Computer account is already added to the System Management container" -Type "INFO: "
            $ButtonConfigureSystemManagementContainerComputer.Enabled = $true
        }
        else {
            try {
                Write-OutputBox -OutputBoxMessage "Adding $($ComputerName) to the System Management container" -Type "INFO: "
                $ComputerFilter = "(&(ObjectClass=Computer)(samAccountName=*$($ComputerName)*))"
                $ComputerSearch = New-Object System.DirectoryServices.DirectorySearcher($ComputerFilter)
                $ComputerResult = $ComputerSearch.FindOne()
                $ComputerObjectSID = New-Object System.Security.Principal.SecurityIdentifier $ComputerResult.Properties["objectSID"][0],0
                [System.Security.Principal.SecurityIdentifier]$ComputerSID = $ComputerObjectSID.Value
                $ContainerObject = [ADSI]("LDAP://CN=System Management,CN=System,$($ADDomain)")
                $ComputerSchemaGUID = New-Object GUID 00000000-0000-0000-0000-000000000000
                $ContainerACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($ComputerSID,"GenericAll","Allow","All",$ComputerSchemaGUID)
                $ContainerObject.ObjectSecurity.AddAccessRule($ContainerACE)
                $ContainerObject.CommitChanges()
                Write-OutputBox -OutputBoxMessage "Successfully added $($ComputerName) to the System Management container" -Type "INFO: "
                $ButtonConfigureSystemManagementContainerComputer.Enabled = $false
                $RadioButtonSMCLocal.Enabled = $false
                $RadioButtonSMCRemote.Enabled = $false
                $TextBoxSMCRemote.Enabled = $false
            }
            catch {
                Write-OutputBox -OutputBoxMessage "$($_.Exception.Message)" -Type "ERROR: "
            }
        }
    }
    if (($RadioButtonSMCRemote.Checked -eq $true) -and ($Container)) {
        $ComputerName = $TextBoxSMCRemote.Text
        if ($TextBoxSMCRemote.Text.Length -gt 1) {
            if ($SearchComputerAdded.Invoke()) {
                Write-OutputBox -OutputBoxMessage "Computer account is already added to the System Management container" -Type "INFO: "
                $ButtonConfigureSystemManagementContainerComputer.Enabled = $true
            }
            else {
                try {
                    Write-OutputBox -OutputBoxMessage "Adding $($ComputerName) to the System Management container" -Type "INFO: "
                    $ComputerFilter = "(&(ObjectClass=Computer)(samAccountName=*$($ComputerName)*))"
                    $ComputerSearch = New-Object System.DirectoryServices.DirectorySearcher($ComputerFilter)
                    $ComputerResult = $ComputerSearch.FindOne()
                    $ComputerObjectSID = New-Object System.Security.Principal.SecurityIdentifier $ComputerResult.Properties["objectSID"][0],0
                    [System.Security.Principal.SecurityIdentifier]$ComputerSID = $ComputerObjectSID.Value
                    $ContainerObject = [ADSI]("LDAP://CN=System Management,CN=System,$($ADDomain)")
                    $ComputerSchemaGUID = New-Object GUID 00000000-0000-0000-0000-000000000000
                    $ContainerACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($ComputerSID,"GenericAll","Allow","All",$ComputerSchemaGUID)
                    $ContainerObject.ObjectSecurity.AddAccessRule($ContainerACE)
                    $ContainerObject.CommitChanges()
                    Write-OutputBox -OutputBoxMessage "Successfully added $($ComputerName) to the System Management container" -Type "INFO: "
                    $ButtonConfigureSystemManagementContainerComputer.Enabled = $false
                    $RadioButtonSMCLocal.Enabled = $false
                    $RadioButtonSMCRemote.Enabled = $false
                    $TextBoxSMCRemote.Enabled = $false
                }
                catch {
                    Write-OutputBox -OutputBoxMessage "$($_.Exception.Message)" -Type "ERROR: "
                }
            }
        }
        elseif ($ComputerName.Length -eq 0) {
            Write-OutputBox -OutputBoxMessage "Please enter a computer name" -Type "WARNING: "
        }
    }
}

function Configure-SystemManagementContainerGroup {
    Write-OutputBox -OutputBoxMessage "Checking if '$($ADGroupName)' is already added to the System Management container" -Type "INFO: "
    $ADDomain = New-Object System.DirectoryServices.DirectoryEntry | Select-Object -ExpandProperty distinguishedName
    $ADGroupName = $TextBoxSMCGroupResult.Text
    $ADGroupFilter = "(&(ObjectCategory=group)(samAccountName=*$($ADGroupName)*))"
    $ADGroupSearch = New-Object System.DirectoryServices.DirectorySearcher($ADGroupFilter)
    $ADGroupSearch.FindAll() | ForEach-Object {
         $Object = New-Object System.Security.Principal.SecurityIdentifier $_.Properties["objectSID"][0],0
         [System.Security.Principal.SecurityIdentifier]$ADGroupSID = $Object.Value
	}
    $IdentityReference = @()
    $ContainerObject = [ADSI]("LDAP://CN=System Management,CN=System,$($ADDomain)")
    $ContainerObject.ObjectSecurity.GetAccessRules($true,$true,[System.Security.Principal.SecurityIdentifier]) | ForEach-Object {
        $IdentityReference += $_.IdentityReference
    }
    if ($IdentityReference.Value -match $ADGroupSID.Value) {
        Write-OutputBox -OutputBoxMessage "'$($ADGroupName)' is already added to the System Management container" -Type "WARNING: "
    }
    else {
        try {
            Write-OutputBox -OutputBoxMessage "Adding '$($ADGroupName)' to the System Management container" -Type "INFO: "
            $ObjectGUID = New-Object GUID 00000000-0000-0000-0000-000000000000
            $ContainerACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule ($ADGroupSID,"GenericAll","Allow","All",$ObjectGUID)
            $ContainerObject.ObjectSecurity.AddAccessRule($ContainerACE)
            $ContainerObject.CommitChanges()
            Write-OutputBox -OutputBoxMessage "Succesfully added '$($ADGroupName)' to the System Management container" -Type "INFO: "
        }
        catch {
            Write-OutputBox -OutputBoxMessage "$($_.Exception.Message)" -Type "ERROR: "
        }
    }
}

function Validate-ADGroupSearch {
	$DGVSMCGroup.Rows.Clear()
	$DGVSMCGroup.Refresh()
}

function Search-ADGroup {
    if ($DGVSMCGroup.Rows.Count -ge 1) {
        Validate-ADGroupSearch
    }
    $ADGroupFilter = "(&(ObjectCategory=group)(samAccountName=*$($TextBoxSMCGroupSearch.Text)*))"
    $ADGroupSearch = New-Object System.DirectoryServices.DirectorySearcher($ADGroupFilter)
    $ADGroupSearch.FindAll() | ForEach-Object -Begin { Write-OutputBox -OutputBoxMessage "Showing the results" -Type "INFO: " } -Process { $DGVSMCGroup.Rows.Add(([string]$_.Properties.Item("samAccountName"))) | Out-Null }
    Write-OutputBox -OutputBoxMessage "Select a group from the results view and click 'Configure'" -Type "INFO: "
}


function Read-FolderBrowserDialog {
    param(
    [parameter(Mandatory=$true)]
    [string]$Message
    )
   	$ShellApplication = New-Object -ComObject Shell.Application
    $FolderBrowserDialog = $ShellApplication.BrowseForFolder(0,"$($Message)",0,17)
   	if ($FolderBrowserDialog) {
		return $FolderBrowserDialog.Self.Path
	} 
	else {
		return ""
	}
}

function Clear-OutputBox {
	$OutputBox.ResetText()	
}

function Get-WebDownloadFile {
	param(
	[Parameter(Mandatory=$true)]
	[String]$URL,
	[Parameter(Mandatory=$true)]
	[string]$DownloadFolder,
	[Parameter(Mandatory=$true)]
	[string]$FileName
	)
	process {
		$ProgressBar.Maximum = 100
        $ProgressBar.Value = 0
    	$WebClient = New-Object System.Net.WebClient
		if (-not(Test-Path -Path $DownloadFolder)) {
			Write-OutputBox -OutputBoxMessage "Creating download folder: $($DownloadFolder)"
			[System.Windows.Forms.Application]::DoEvents()
            New-Item $DownloadFolder -ItemType Directory | Out-Null
        }
		$Global:DownloadComplete = $False
        $EventDataComplete = Register-ObjectEvent $WebClient DownloadFileCompleted -SourceIdentifier WebClient.DownloadFileComplete -Action {$Global:DownloadComplete = $True}
        $EventDataProgress = Register-ObjectEvent $WebClient DownloadProgressChanged -SourceIdentifier WebClient.DownloadProgressChanged -Action { $Global:DPCEventArgs = $EventArgs }    
    	$WebClient.DownloadFileAsync($URL, "$($DownloadFolder)\$($FileName)")
		Write-OutputBox -OutputBoxMessage "Downloading ($($FileName) to $($DownloadFolder)"
		do {                
            $PercentComplete = $Global:DPCEventArgs.ProgressPercentage
			$DownloadedBytes = $Global:DPCEventArgs.BytesReceived
			$TotalBytes = $Global:DPCEventArgs.TotalBytesToReceive
            $ProgressBar.Value = $PercentComplete
            [System.Windows.Forms.Application]::DoEvents()
        }
		until ($Global:DownloadComplete)
    	$WebClient.Dispose()
        Unregister-Event -SourceIdentifier WebClient.DownloadProgressChanged
        Unregister-Event -SourceIdentifier WebClient.DownloadFileComplete
	}	
}

function Get-PrereqFiles {
	$DownloadDestination = "C:\ConfigMgrPrereqs"
	if (-not(Test-Path -Path $DownloadDestination)) {
		New-Item -ItemType Directory -Path $DownloadDestination	
	}
	do { 
		$SetupDLLocation = Read-FolderBrowserDialog -Message "Browse to the '<ConfigMgr source files>\SMSSETUP\BIN\X64' folder."
	}
	until (Test-Path -Path "$($SetupDLLocation)\setupdl.exe")
	Write-OutputBox -OutputBoxMessage "Downloading prerequites from Microsoft"
	do {
		Start-Process -FilePath "$($SetupDLLocation)\setupdl.exe" -ArgumentList "$($DownloadDestination)" -Wait
	}
	until ((Get-ChildItem -Path $DownloadDestination | Measure-Object).Count -ge 59)
	Write-OutputBox -OutputBoxMessage "Successfully downloaded all prerequisites"
	$ButtonBack.Enabled = $true
	if ($InstallType -eq 1) {
		$Form.Controls.Remove($ButtonInstallCAS)
	}
	if ($InstallType -eq 2) {
		$Form.Controls.Remove($ButtonInstallPrimarySite)
	}
	$Form.Controls.Add($ButtonFinish)
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
		}
		else {
			$OutputBox.AppendText("`n$($Type)$($OutputBoxMessage)")
			[System.Windows.Forms.Application]::DoEvents()
		}
	}
}

function Enter-WaterMark {
    param(
    [parameter(Mandatory=$true)]
    $InputObject,
    [parameter(Mandatory=$true)]
    $Text
    )
	if ($InputObject.Text -eq $Text) {
		$InputObject.Text = ""
		$InputObject.ForeColor = "WindowText"
	}
}

function Leave-WaterMark {
    param(
    [parameter(Mandatory=$true)]
    $InputObject,
    [parameter(Mandatory=$true)]
    $Text
    )
	if ($InputObject.Text -eq "") {
		$InputObject.Text = $Text
		$InputObject.ForeColor = "LightGray"
	}
}

function Leave-WaterMarkStart {
    param(
    [parameter(Mandatory=$true)]
    $InputObject,
    [parameter(Mandatory=$true)]
    $Text
    )
	if ($InputObject.Text.Length -gt 0) {
		$InputObject.Text = $Text
		$InputObject.ForeColor = "LightGray"
	}
}

#Assemblies
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.DirectoryServices")

#Variables
$InstallType = 0

#Form
$Form = New-Object System.Windows.Forms.Form    
$Form.Size = New-Object System.Drawing.Size(800,500)  
$Form.MinimumSize = New-Object System.Drawing.Size(800,500)
$Form.MaximumSize = New-Object System.Drawing.Size(800,500)
$Form.SizeGripStyle = "Hide"
$Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHome + "\powershell.exe")
$Form.Text = "ConfigMgr 2012 R2 Prerequisites Installation Tool - 1.2.1"

#Tabs
$TabPageSMCComputer = New-Object System.Windows.Forms.TabPage
$TabPageSMCComputer.Location = New-Object System.Drawing.Size(10,50)
$TabPageSMCComputer.Size = New-Object System.Drawing.Size(300,300)
$TabPageSMCComputer.Text = "Computer"
$TabPageSMCComputer.Name = "Computer"
$TabPageSMCComputer.Padding = "0,0,0,0"
$TabPageSMCComputer.BackColor = "Control"
$TabPageSMCGroup = New-Object System.Windows.Forms.TabPage
$TabPageSMCGroup.Location = New-Object System.Drawing.Size(0,0)
$TabPageSMCGroup.Size = New-Object System.Drawing.Size(300,300)
$TabPageSMCGroup.Text = "Group  "
$TabPageSMCGroup.Name = "Group"
$TabPageSMCGroup.Padding = "0,0,0,0"
$TabPageSMCGroup.BackColor = "Control"
$TabPageSMCGroup.Margin = New-Object System.Windows.Forms.Padding('0')
$TabControlSMC = New-Object System.Windows.Forms.TabControl
$TabControlSMC.Location = New-Object System.Drawing.Size(0,0)
$TabControlSMC.Size = New-Object System.Drawing.Size(800,500)
$TabControlSMC.Anchor = "Top, Bottom, Left, Right"
$TabControlSMC.Name = "TabControl"
$TabControlSMC.SelectedIndex = 0
$TabControlSMC.Add_Selected([System.Windows.Forms.TabControlEventHandler]{
    if ($TabControlSMC.SelectedTab.Name -like "Group") {
        if ($OutputBox.Location.Y -eq 10) {
            $OutputBox.Location = New-Object System.Drawing.Size(380,65)
            $OutputBox.Size = New-Object System.Drawing.Size(393,296)
        }
        $TabPageSMCGroup.Controls.Add($OutputBox)
    }
})
$TabControlSMC.Add_Selected([System.Windows.Forms.TabControlEventHandler]{
    if ($TabControlSMC.SelectedTab.Name -like "Computer") {
        if ($OutputBox.ControlAdded) {
            $TabPageSMCGroup.Controls.Remove($OutputBox)
        }
        $OutputBox.Location = New-Object System.Drawing.Size(10,10)
        $OutputBox.Size = New-Object System.Drawing.Size(763,350)
        $TabPageSMCComputer.Controls.Add($OutputBox)
    }
})

#ProgressBar
$ProgressBar = New-Object System.Windows.Forms.ProgressBar
$ProgressBar.Location = New-Object System.Drawing.Size(10,375)
$ProgressBar.Size = New-Object System.Drawing.Size(763,30)
$ProgressBar.Step = 1
$ProgressBar.Value = 0

#OutputBox
$OutputBox = New-Object System.Windows.Forms.RichTextBox 
$OutputBox.Location = New-Object System.Drawing.Size(10,10) 
$OutputBox.Size = New-Object System.Drawing.Size(763,350)
$OutputBox.Font = "Courier New"
$OutputBox.BackColor = "white"
$OutputBox.ReadOnly = $true
$OutputBox.MultiLine = $True

#DataGriView
$DGVSMCGroup = New-Object System.Windows.Forms.DataGridView
$DGVSMCGroup.Location = New-Object System.Drawing.Size(10,65)
$DGVSMCGroup.Size = New-Object System.Drawing.Size(360,295)
$DGVSMCGroup.ColumnCount = 1
$DGVSMCGroup.ColumnHeadersVisible = $true
$DGVSMCGroup.Columns[0].Name = "Active Directory group"
$DGVSMCGroup.AllowUserToAddRows = $false
$DGVSMCGroup.AllowUserToDeleteRows = $false
$DGVSMCGroup.ReadOnly = $True
$DGVSMCGroup.ColumnHeadersHeightSizeMode = "DisableResizing"
$DGVSMCGroup.AutoSizeColumnsMode = "Fill"
$DGVSMCGroup.RowHeadersWidthSizeMode = "DisableResizing"
$DGVSMCGroup.Add_Click({
    $DGVSMCResult = $DGVSMCGroup.CurrentCell.Value
    $TextBoxSMCGroupResult.Text = $DGVSMCResult
    Write-OutputBox -OutputBoxMessage "Selected the '$($DGVSMCResult)' group" -Type "INFO: "
    $ButtonConfigureSystemManagementContainerGroup.Enabled = $true
})

#Textboxes
$TextBoxDC = New-Object System.Windows.Forms.TextBox
$TextBoxDC.Location = New-Object System.Drawing.Size(20,428) 
$TextBoxDC.Size = New-Object System.Drawing.Size(170,20)
$TextBoxDC.TabIndex = "0"
$TextBoxSMCLocal = New-Object System.Windows.Forms.TextBox
$TextBoxSMCLocal.Location = New-Object System.Drawing.Size(38,393) 
$TextBoxSMCLocal.Size = New-Object System.Drawing.Size(140,20)
$TextBoxSMCLocal.TabIndex = "0"
$TextBoxSMCLocal.Text = $env:COMPUTERNAME
$TextBoxSMCLocal.Enabled = $false
$TextBoxSMCRemote = New-Object System.Windows.Forms.TextBox
$TextBoxSMCRemote.Location = New-Object System.Drawing.Size(218,393) 
$TextBoxSMCRemote.Size = New-Object System.Drawing.Size(140,20)
$TextBoxSMCRemote.TabIndex = "0"
$TextBoxSMCRemote.Enabled = $false
$TextBoxSMCGroupSearch = New-Object System.Windows.Forms.TextBox
$TextBoxSMCGroupSearch.Location = New-Object System.Drawing.Size(20,27) 
$TextBoxSMCGroupSearch.Size = New-Object System.Drawing.Size(340,20)
$TextBoxSMCGroupSearch.TabIndex = "0"
$TextBoxSMCGroupSearch.Add_KeyPress([System.Windows.Forms.KeyPressEventHandler]{ 
    if ($_.KeyChar -eq 13) {
        $OutputBox.ResetText()
        Write-OutputBox -OutputBoxMessage "Searching Active Directory for '$($TextBoxSMCGroupSearch.Text)'" -Type "INFO: "    
        Search-ADGroup
    } 
})
$TextBoxSMCGroupResult = New-Object System.Windows.Forms.TextBox
$TextBoxSMCGroupResult.Location = New-Object System.Drawing.Size(20,392) 
$TextBoxSMCGroupResult.Size = New-Object System.Drawing.Size(340,20)
$TextBoxSMCGroupResult.Enabled = $false
$TextBoxWSUSSQLServer = New-Object System.Windows.Forms.TextBox
$TextBoxWSUSSQLServer.Location = New-Object System.Drawing.Size(160,428) 
$TextBoxWSUSSQLServer.Size = New-Object System.Drawing.Size(140,20)
$TextBoxWSUSSQLServer.TabIndex = "0"
$TextBoxWSUSSQLServer.Enabled = $false
$TextBoxWSUSSQLInstance = New-Object System.Windows.Forms.TextBox
$TextBoxWSUSSQLInstance.Location = New-Object System.Drawing.Size(310,428)
$TextBoxWSUSSQLInstance.Size = New-Object System.Drawing.Size(140,20)
$TextBoxWSUSSQLInstance.TabIndex = "0"
$TextBoxWSUSSQLInstance.Text = $env:COMPUTERNAME
$TextBoxWSUSSQLInstance.Enabled = $false

#Buttons
$ButtonCAS = New-Object System.Windows.Forms.Button 
$ButtonCAS.Location = New-Object System.Drawing.Size(60,130) 
$ButtonCAS.Size = New-Object System.Drawing.Size(200,80) 
$ButtonCAS.Text = "Central Administration Site"
$ButtonCAS.TabIndex = "1"
$ButtonCAS.Add_Click({Load-CAS})
$ButtonPrimarySite = New-Object System.Windows.Forms.Button 
$ButtonPrimarySite.Location = New-Object System.Drawing.Size(60,230) 
$ButtonPrimarySite.Size = New-Object System.Drawing.Size(200,80) 
$ButtonPrimarySite.Text = "Primary Site"
$ButtonPrimarySite.TabIndex = "2"
$ButtonPrimarySite.Add_Click({Load-Primary})
$ButtonSecondarySite = New-Object System.Windows.Forms.Button 
$ButtonSecondarySite.Location = New-Object System.Drawing.Size(60,330) 
$ButtonSecondarySite.Size = New-Object System.Drawing.Size(200,80) 
$ButtonSecondarySite.Text = "Secondary Site"
$ButtonSecondarySite.TabIndex = "3"
$ButtonSecondarySite.Add_Click({Load-Secondary})
$ButtonMP = New-Object System.Windows.Forms.Button 
$ButtonMP.Location = New-Object System.Drawing.Size(290,130) 
$ButtonMP.Size = New-Object System.Drawing.Size(200,50) 
$ButtonMP.Text = "Management Point"
$ButtonMP.TabIndex = "4"
$ButtonMP.Add_Click({Load-MP})
$ButtonAppCat = New-Object System.Windows.Forms.Button 
$ButtonAppCat.Location = New-Object System.Drawing.Size(290,200) 
$ButtonAppCat.Size = New-Object System.Drawing.Size(200,50) 
$ButtonAppCat.Text = "Application Catalog"
$ButtonAppCat.TabIndex = "5"
$ButtonAppCat.Add_Click({Load-AppCat})
$ButtonDP = New-Object System.Windows.Forms.Button 
$ButtonDP.Location = New-Object System.Drawing.Size(290,270) 
$ButtonDP.Size = New-Object System.Drawing.Size(200,50) 
$ButtonDP.Text = "Distribution Point"
$ButtonDP.TabIndex = "6"
$ButtonDP.Add_Click({Load-DP})
$ButtonEP = New-Object System.Windows.Forms.Button 
$ButtonEP.Location = New-Object System.Drawing.Size(290,340) 
$ButtonEP.Size = New-Object System.Drawing.Size(200,50) 
$ButtonEP.Text = "Enrollment Point"
$ButtonEP.TabIndex = "7"
$ButtonEP.Add_Click({Load-EP})
$ButtonExtendActiveDirectory = New-Object System.Windows.Forms.Button 
$ButtonExtendActiveDirectory.Location = New-Object System.Drawing.Size(520,130) 
$ButtonExtendActiveDirectory.Size = New-Object System.Drawing.Size(200,50) 
$ButtonExtendActiveDirectory.Text = "Extend Active Directory"
$ButtonExtendActiveDirectory.TabIndex = "8"
$ButtonExtendActiveDirectory.Add_Click({Load-ExtendActiveDirectory})
$ButtonWSUS = New-Object System.Windows.Forms.Button 
$ButtonWSUS.Location = New-Object System.Drawing.Size(520,200) 
$ButtonWSUS.Size = New-Object System.Drawing.Size(200,50) 
$ButtonWSUS.Text = "Install WSUS"
$ButtonWSUS.TabIndex = "9"
$ButtonWSUS.Add_Click({Load-WSUS})
$ButtonADK = New-Object System.Windows.Forms.Button 
$ButtonADK.Location = New-Object System.Drawing.Size(520,270) 
$ButtonADK.Size = New-Object System.Drawing.Size(200,50) 
$ButtonADK.Text = "Install ADK"
$ButtonADK.TabIndex = "10"
$ButtonADK.Add_Click({Load-ADK})
$ButtonSystemManagementContainer = New-Object System.Windows.Forms.Button 
$ButtonSystemManagementContainer.Location = New-Object System.Drawing.Size(520,340) 
$ButtonSystemManagementContainer.Size = New-Object System.Drawing.Size(200,50) 
$ButtonSystemManagementContainer.Text = "System Management Container"
$ButtonSystemManagementContainer.TabIndex = "11"
$ButtonSystemManagementContainer.Add_Click({Load-SystemManagementContainer})
$ButtonInstallCAS = New-Object System.Windows.Forms.Button 
$ButtonInstallCAS.Location = New-Object System.Drawing.Size(673,420) 
$ButtonInstallCAS.Size = New-Object System.Drawing.Size(100,30) 
$ButtonInstallCAS.Text = "Install"
$ButtonInstallCAS.TabIndex = "1"
$ButtonInstallCAS.Add_Click({Validate-CASInstall})
$ButtonInstallPrimarySite = New-Object System.Windows.Forms.Button 
$ButtonInstallPrimarySite.Location = New-Object System.Drawing.Size(673,420)
$ButtonInstallPrimarySite.Size = New-Object System.Drawing.Size(100,30) 
$ButtonInstallPrimarySite.Text = "Install"
$ButtonInstallPrimarySite.TabIndex = "1"
$ButtonInstallPrimarySite.Add_Click({Validate-PrimaryInstall})
$ButtonInstallSecondarySite = New-Object System.Windows.Forms.Button 
$ButtonInstallSecondarySite.Location = New-Object System.Drawing.Size(673,420)
$ButtonInstallSecondarySite.Size = New-Object System.Drawing.Size(100,30) 
$ButtonInstallSecondarySite.Text = "Install"
$ButtonInstallSecondarySite.TabIndex = "1"
$ButtonInstallSecondarySite.Add_Click({Validate-SecondaryInstall})
$ButtonInstallMP = New-Object System.Windows.Forms.Button 
$ButtonInstallMP.Location = New-Object System.Drawing.Size(673,420) 
$ButtonInstallMP.Size = New-Object System.Drawing.Size(100,30) 
$ButtonInstallMP.Text = "Install"
$ButtonInstallMP.TabIndex = "1"
$ButtonInstallMP.Add_Click({Validate-MPInstall})
$ButtonInstallAppCat = New-Object System.Windows.Forms.Button 
$ButtonInstallAppCat.Location = New-Object System.Drawing.Size(673,420) 
$ButtonInstallAppCat.Size = New-Object System.Drawing.Size(100,30) 
$ButtonInstallAppCat.Text = "Install"
$ButtonInstallAppCat.TabIndex = "1"
$ButtonInstallAppCat.Add_Click({Validate-AppCatInstall})
$ButtonInstallDP = New-Object System.Windows.Forms.Button 
$ButtonInstallDP.Location = New-Object System.Drawing.Size(673,420) 
$ButtonInstallDP.Size = New-Object System.Drawing.Size(100,30) 
$ButtonInstallDP.Text = "Install"
$ButtonInstallDP.TabIndex = "1"
$ButtonInstallDP.Add_Click({Validate-DPInstall})
$ButtonInstallEP = New-Object System.Windows.Forms.Button 
$ButtonInstallEP.Location = New-Object System.Drawing.Size(673,420) 
$ButtonInstallEP.Size = New-Object System.Drawing.Size(100,30) 
$ButtonInstallEP.Text = "Install"
$ButtonInstallEP.TabIndex = "1"
$ButtonInstallEP.Add_Click({Validate-EPInstall})
$ButtonInstallExtendAD = New-Object System.Windows.Forms.Button 
$ButtonInstallExtendAD.Location = New-Object System.Drawing.Size(673,420) 
$ButtonInstallExtendAD.Size = New-Object System.Drawing.Size(100,30) 
$ButtonInstallExtendAD.Text = "Extend"
$ButtonInstallExtendAD.TabIndex = "1"
$ButtonInstallExtendAD.Add_Click({Extend-ActiveDirectorySchema})
$ButtonConnectDC = New-Object System.Windows.Forms.Button 
$ButtonConnectDC.Location = New-Object System.Drawing.Size(673,420) 
$ButtonConnectDC.Size = New-Object System.Drawing.Size(100,30) 
$ButtonConnectDC.Text = "Connect"
$ButtonConnectDC.TabIndex = "1"
$ButtonConnectDC.Add_Click({Validate-ExtendActiveDirectory})
$ButtonInstallWSUS = New-Object System.Windows.Forms.Button 
$ButtonInstallWSUS.Location = New-Object System.Drawing.Size(673,420) 
$ButtonInstallWSUS.Size = New-Object System.Drawing.Size(100,30) 
$ButtonInstallWSUS.Text = "Install"
$ButtonInstallWSUS.TabIndex = "1"
$ButtonInstallWSUS.Add_Click({Validate-WSUS})
$ButtonInstallADK= New-Object System.Windows.Forms.Button 
$ButtonInstallADK.Location = New-Object System.Drawing.Size(673,420) 
$ButtonInstallADK.Size = New-Object System.Drawing.Size(100,30) 
$ButtonInstallADK.Text = "Install"
$ButtonInstallADK.TabIndex = "1"
$ButtonInstallADK.Add_Click({Validate-ADK})
$ButtonConfigureSystemManagementContainerComputer = New-Object System.Windows.Forms.Button 
$ButtonConfigureSystemManagementContainerComputer.Location = New-Object System.Drawing.Size(673,385) 
$ButtonConfigureSystemManagementContainerComputer.Size = New-Object System.Drawing.Size(100,30) 
$ButtonConfigureSystemManagementContainerComputer.Text = "Configure"
$ButtonConfigureSystemManagementContainerComputer.TabIndex = "1"
$ButtonConfigureSystemManagementContainerComputer.Add_Click({Validate-SystemManagementContainerComputer})
$ButtonConfigureSystemManagementContainerGroup = New-Object System.Windows.Forms.Button 
$ButtonConfigureSystemManagementContainerGroup.Location = New-Object System.Drawing.Size(673,385) 
$ButtonConfigureSystemManagementContainerGroup.Size = New-Object System.Drawing.Size(100,30) 
$ButtonConfigureSystemManagementContainerGroup.Text = "Configure"
$ButtonConfigureSystemManagementContainerGroup.TabIndex = "1"
$ButtonConfigureSystemManagementContainerGroup.Add_Click({Validate-SystemManagementContainerGroup})
$ButtonSystemManagementContainerGroupSearch = New-Object System.Windows.Forms.Button 
$ButtonSystemManagementContainerGroupSearch.Location = New-Object System.Drawing.Size(380,20) 
$ButtonSystemManagementContainerGroupSearch.Size = New-Object System.Drawing.Size(100,30) 
$ButtonSystemManagementContainerGroupSearch.Text = "Search"
$ButtonSystemManagementContainerGroupSearch.TabIndex = "1"
$ButtonSystemManagementContainerGroupSearch.Add_Click({
    $OutputBox.ResetText()
    Write-OutputBox -OutputBoxMessage "Searching Active Directory for '$($TextBoxSMCGroupSearch.Text)'" -Type "INFO: "
    Search-ADGroup
})
$ButtonContinue = New-Object System.Windows.Forms.Button 
$ButtonContinue.Location = New-Object System.Drawing.Size(673,420) 
$ButtonContinue.Size = New-Object System.Drawing.Size(100,30) 
$ButtonContinue.Text = "Continue"
$ButtonContinue.TabIndex = "1"
$ButtonContinue.Add_Click({Get-PrereqFiles})
$ButtonBack = New-Object System.Windows.Forms.Button 
$ButtonBack.Location = New-Object System.Drawing.Size(563,420) 
$ButtonBack.Size = New-Object System.Drawing.Size(100,30) 
$ButtonBack.Text = "Back"
$ButtonBack.TabIndex = "2"
$ButtonBack.Add_Click({Load-Start})
$ButtonBackGroup = New-Object System.Windows.Forms.Button 
$ButtonBackGroup.Location = New-Object System.Drawing.Size(563,385)
$ButtonBackGroup.Size = New-Object System.Drawing.Size(100,30) 
$ButtonBackGroup.Text = "Back"
$ButtonBackGroup.TabIndex = "2"
$ButtonBackGroup.Add_Click({Load-Start})
$ButtonFinish = New-Object System.Windows.Forms.Button 
$ButtonFinish.Location = New-Object System.Drawing.Size(673,420) 
$ButtonFinish.Size = New-Object System.Drawing.Size(100,30) 
$ButtonFinish.Text = "Finish"
$ButtonFinish.TabIndex = "1"
$ButtonFinish.Add_Click({$Form.Close()})

#WaterMarks
$WaterMarkDC = "Enter Schema Master server name"
$TextBoxDC.ForeColor = "LightGray"
$TextBoxDC.Text = $WaterMarkDC
$TextBoxDC.add_Enter({Enter-WaterMark -InputObject $TextBoxDC -Text $WaterMarkDC})
$TextBoxDC.add_Leave({Leave-WaterMark -InputObject $TextBoxDC -Text $WaterMarkDC})
$WaterMarkWSUSSQLServer = "Enter SQL Server name"
$TextBoxWSUSSQLServer.ForeColor = "LightGray"
$TextBoxWSUSSQLServer.Text = $WaterMarkWSUSSQLServer
$TextBoxWSUSSQLServer.add_Enter({Enter-WaterMark -InputObject $TextBoxWSUSSQLServer -Text $WaterMarkWSUSSQLServer})
$TextBoxWSUSSQLServer.add_Leave({Leave-WaterMark -InputObject $TextBoxWSUSSQLServer -Text $WaterMarkWSUSSQLServer})
$WaterMarkWSUSSQLInstance = "Enter SQL Server instance"
$TextBoxWSUSSQLInstance.ForeColor = "LightGray"
$TextBoxWSUSSQLInstance.Text = $WaterMarkWSUSSQLInstance
$TextBoxWSUSSQLInstance.add_Enter({Enter-WaterMark -InputObject $TextBoxWSUSSQLInstance -Text $WaterMarkWSUSSQLInstance})
$TextBoxWSUSSQLInstance.add_Leave({Leave-WaterMark -InputObject $TextBoxWSUSSQLInstance -Text $WaterMarkWSUSSQLInstance})

#Text
$LabelHeader = New-Object System.Windows.Forms.Label
$LabelHeader.Location = New-Object System.Drawing.Size(180,20)
$LabelHeader.Size = New-Object System.Drawing.Size(600,30)
$LabelHeader.Text = "Install ConfigMgr 2012 R2 Prerequisites"
$LabelHeader.Font = New-Object System.Drawing.Font("Verdana",14,[System.Drawing.FontStyle]::Bold)
$LabelSMCCreate = New-Object System.Windows.Forms.Label
$LabelSMCCreate.Location = New-Object System.Drawing.Size(418,395)
$LabelSMCCreate.Size = New-Object System.Drawing.Size(150,20)
$LabelSMCCreate.Text = "Create the container"

#Links
$OpenLink = {[System.Diagnostics.Process]::Start("http://www.scconfigmgr.com")}
$BlogLink = New-Object System.Windows.Forms.LinkLabel
$BlogLink.Location = New-Object System.Drawing.Size(330,50) 
$BlogLink.Size = New-Object System.Drawing.Size(150,25)
$BlogLink.Text = "www.scconfigmgr.com"
$BlogLink.Add_Click($OpenLink)

#RadioButtons
$RadioButtonOnline = New-Object System.Windows.Forms.RadioButton
$RadioButtonOnline.Location = New-Object System.Drawing.Size(20,427)
$RadioButtonOnline.Size = New-Object System.Drawing.Size(60,24)
$RadioButtonOnline.Text = "Online"
$RadioButtonOffline = New-Object System.Windows.Forms.RadioButton
$RadioButtonOffline.Location = New-Object System.Drawing.Size(90,427)
$RadioButtonOffline.Size = New-Object System.Drawing.Size(60,24)
$RadioButtonOffline.Text = "Offline"
$RadioButtonSMCLocal = New-Object System.Windows.Forms.RadioButton
$RadioButtonSMCLocal.Location = New-Object System.Drawing.Size(20,392)
$RadioButtonSMCLocal.Size = New-Object System.Drawing.Size(15,24)
$RadioButtonSMCLocal.Add_Click({$TextBoxSMCRemote.Enabled = $false})
$RadioButtonSMCRemote = New-Object System.Windows.Forms.RadioButton
$RadioButtonSMCRemote.Location = New-Object System.Drawing.Size(200,392)
$RadioButtonSMCRemote.Size = New-Object System.Drawing.Size(15,24)
$RadioButtonSMCRemote.Add_Click({$TextBoxSMCRemote.Enabled = $true})
$RadioButtonEP = New-Object System.Windows.Forms.RadioButton
$RadioButtonEP.Location = New-Object System.Drawing.Size(20,427)
$RadioButtonEP.Size = New-Object System.Drawing.Size(110,20)
$RadioButtonEP.Text = "Enrollment Point"
$RadioButtonEPP = New-Object System.Windows.Forms.RadioButton
$RadioButtonEPP.Location = New-Object System.Drawing.Size(160,427)
$RadioButtonEPP.Size = New-Object System.Drawing.Size(137,20)
$RadioButtonEPP.Text = "Enrollment Proxy Point"
$RadioButtonWID = New-Object System.Windows.Forms.RadioButton
$RadioButtonWID.Location = New-Object System.Drawing.Size(20,427)
$RadioButtonWID.Size = New-Object System.Drawing.Size(60,24)
$RadioButtonWID.Text = "WID"
$RadioButtonWID.Checked = $true
$RadioButtonWID.Add_Click({
    $TextBoxWSUSSQLServer.Enabled = $false
    $TextBoxWSUSSQLInstance.Enabled = $false
    $OutputBox.Clear()
})
$RadioButtonSQL = New-Object System.Windows.Forms.RadioButton
$RadioButtonSQL.Location = New-Object System.Drawing.Size(90,427)
$RadioButtonSQL.Size = New-Object System.Drawing.Size(45,24)
$RadioButtonSQL.Text = "SQL"
$RadioButtonSQL.Add_Click({
    $TextBoxWSUSSQLServer.Enabled = $true
    $TextBoxWSUSSQLInstance.Enabled = $true
    Write-OutputBox -OutputBoxMessage "Specify the SQL Server computer name and instance name in the fields below" -Type "INFO: "
    Write-OutputBox -OutputBoxMessage "Leave the instance field empty if you're using the default instance on the SQL Server" -Type "INFO: "
})

#Check boxes
$CBSMCCreate = New-Object System.Windows.Forms.CheckBox
$CBSMCCreate.Location = New-Object System.Drawing.Size(400,392)
$CBSMCCreate.Size = New-Object System.Drawing.Size(20,20)

#Group boxes
$GBSites = New-Object System.Windows.Forms.GroupBox
$GBSites.Location = New-Object System.Drawing.Size(50,100) 
$GBSites.Size = New-Object System.Drawing.Size(220,340) 
$GBSites.Text = "Sites" 
$GBSiteSystemRoles = New-Object System.Windows.Forms.GroupBox
$GBSiteSystemRoles.Location = New-Object System.Drawing.Size(280,100) 
$GBSiteSystemRoles.Size = New-Object System.Drawing.Size(220,340) 
$GBSiteSystemRoles.Text = "Site System Roles" 
$GBOther = New-Object System.Windows.Forms.GroupBox
$GBOther.Location = New-Object System.Drawing.Size(510,100) 
$GBOther.Size = New-Object System.Drawing.Size(220,340) 
$GBOther.Text = "Other" 
$GBADK = New-Object System.Windows.Forms.GroupBox
$GBADK.Location = New-Object System.Drawing.Size(10,410) 
$GBADK.Size = New-Object System.Drawing.Size(190,45) 
$GBADK.Text = "Installation methods"
$GBWSUS = New-Object System.Windows.Forms.GroupBox
$GBWSUS.Location = New-Object System.Drawing.Size(10,410) 
$GBWSUS.Size = New-Object System.Drawing.Size(130,45) 
$GBWSUS.Text = "Database options"
$GBWSUSSQL = New-Object System.Windows.Forms.GroupBox
$GBWSUSSQL.Location = New-Object System.Drawing.Size(150,410) 
$GBWSUSSQL.Size = New-Object System.Drawing.Size(310,45) 
$GBWSUSSQL.Text = "SQL Server details"
$GBExtendAD = New-Object System.Windows.Forms.GroupBox
$GBExtendAD.Location = New-Object System.Drawing.Size(10,410) 
$GBExtendAD.Size = New-Object System.Drawing.Size(190,45) 
$GBExtendAD.Text = "Schema Master server name"
$GBSystemManagementContainer = New-Object System.Windows.Forms.GroupBox
$GBSystemManagementContainer.Location = New-Object System.Drawing.Size(10,375) 
$GBSystemManagementContainer.Size = New-Object System.Drawing.Size(360,45) 
$GBSystemManagementContainer.Text = "Add computer account to the System Management container"
$GBSystemManagementContainerGroup = New-Object System.Windows.Forms.GroupBox
$GBSystemManagementContainerGroup.Location = New-Object System.Drawing.Size(10,375) 
$GBSystemManagementContainerGroup.Size = New-Object System.Drawing.Size(360,45) 
$GBSystemManagementContainerGroup.Text = "AD group that will be added to the System Management container"
$GBSystemManagementContainerGroupSearch = New-Object System.Windows.Forms.GroupBox
$GBSystemManagementContainerGroupSearch.Location = New-Object System.Drawing.Size(10,10) 
$GBSystemManagementContainerGroupSearch.Size = New-Object System.Drawing.Size(360,45) 
$GBSystemManagementContainerGroupSearch.Text = "Search for an AD group to add to the System Management Container"
$GBEP = New-Object System.Windows.Forms.GroupBox
$GBEP.Location = New-Object System.Drawing.Size(10,410) 
$GBEP.Size = New-Object System.Drawing.Size(290,45) 
$GBEP.Text = "Select a site system role"

#Create the form
Validate-OS