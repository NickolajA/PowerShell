#========================================================================
#
#    Created:   2015-06-15
#     Author:   Nickolaj Andersen
#    Version:	1.4.0
#    Twitter:	@NickolajA
#       Blog:	www.scconfigmgr.com
#
#========================================================================

#Functions
function Load-Form {
    $Form.Controls.Add($TabControl)
    $TabControl.Controls.AddRange(@(
        $TabPageGeneral,
        $TabPageCAS, 
        $TabPagePrimary, 
        $TabPageSecondary, 
        $TabPageSiteRoles, 
        $TabPageOther
    ))
    $TabPageGeneral.Controls.AddRange(@(
        $OutputBoxGeneral, 
        $BlogLink, 
        $LBVersions,
        $CBValidationOverride,
        $LabelHeader, 
        $LabelGeneralRestart, 
        $LabelGeneralOS, 
        $LabelGeneralPS, 
        $LabelGeneralElevated,
        $PBReboot,
        $PBOS,
        $PBPS,
        $PBElevated,
        $GBGeneralReboot, 
        $GBGeneralOS, 
        $GBGeneralPS, 
        $GBGeneralElevated, 
        $GBGeneralValidation,
        $GBGeneralVersion
    ))
    $Form.Add_Shown({Validate-RunChecks})
	$Form.Add_Shown({$Form.Activate()})
	[void]$Form.ShowDialog()	
}

function Load-CAS {
    if (-not(($TabPageCAS.Controls | Measure-Object).Count -ge 1)) {
        $TabPageCAS.Controls.Clear()
	    $TabPageCAS.Controls.AddRange(@(
            $ProgressBarCAS, 
            $OutputBoxCAS, 
            $CBCASDownloadPrereqs, 
            $ButtonInstallCAS
        ))
    }
	if ($ButtonInstallCAS.Enabled -eq $false) {
		$ButtonInstallCAS.Enabled = $true
	}	
}

function Load-Primary {
    if (-not(($TabPagePrimary.Controls | Measure-Object).Count -ge 1)) {
	    $TabPagePrimary.Controls.Clear()
	    $TabPagePrimary.Controls.AddRange(@(
            $ProgressBarPrimary, 
            $OutputBoxPrimary, 
            $CBPrimaryDownloadPrereqs, 
            $ButtonInstallPrimarySite
        ))
    }
	if ($ButtonInstallPrimarySite.Enabled -eq $false) {
		$ButtonInstallPrimarySite.Enabled = $true
	}
}

function Load-Secondary {
    if (-not(($TabPageSecondary.Controls | Measure-Object).Count -ge 1)) {
	    $TabPageSecondary.Controls.Clear()
        $TabPageSecondary.Controls.AddRange(@(
            $ProgressBarSecondary, 
            $OutputBoxSecondary, 
            $ButtonInstallSecondarySite
        ))
    }
	if ($ButtonInstallSecondarySite.Enabled -eq $false) {
		$ButtonInstallSecondarySite.Enabled = $true
	}
}

function Load-SiteSystemRoles {
    if (-not(($TabPageSiteRoles.Controls | Measure-Object).Count -ge 1)) {
        $TabPageSiteRoles.Controls.Clear()
        $TabPageSiteRoles.Controls.AddRange(@(
            $ProgressBarSiteRoles, 
            $OutputBoxSiteRoles, 
            $RadioButtonSiteRoleMP, 
            $RadioButtonSiteRoleDP, 
            $RadioButtonSiteRoleAppCat, 
            $RadioButtonSiteRoleEP, 
            $RadioButtonSiteRoleSMP,
            $ButtonInstallSiteRoles, 
            $GBSiteSystemRoles
        ))
    }
}

function Load-Other {
    if (-not(($TabPageOther.Controls | Measure-Object).Count -ge 1)) {
        $TabPageOther.Controls.Clear()
        $TabPageOther.Controls.AddRange(@(
            $ProgressBarOther, 
            $OutputBoxOther, 
            $ButtonInstallOther, 
            $RadioButtonOtherEAD, 
            $RadioButtonOtherWSUS, 
            $RadioButtonOtherADK, 
            $RadioButtonOtherSMC, 
            $RadioButtonOtherNoSMS, 
            $GBOther
        ))
    }
}

function Load-SystemManagementContainer {
    Validate-ADGroupSearch
}

function Interactive-TabPages {
    param(
    [parameter(Mandatory=$true)]
    [ValidateSet("Enable","Disable")]
    $Mode
    )
    Begin {
        $CurrentTabPage = $TabControl.SelectedTab.Name
        switch ($Mode) {
            "Enable" { $TabPageMode = $true }
            "Disable" { $TabPageMode = $false }
        }
        $TabNameArrayList = New-Object -TypeName System.Collections.ArrayList
        foreach ($TabNameArrayListObject in (($TabControl.TabPages.Name))) {
            $TabNameArrayList.Add($TabNameArrayListObject)
        }
    }
    Process {
        foreach ($TabPageObject in $TabNameArrayList) {
            if ($Mode -like "Disable") {
                if ($CurrentTabPage -like "General") {
                    $TabPageCAS.Enabled = $TabPageMode
                    $TabPagePrimary.Enabled = $TabPageMode
                    $TabPageSecondary.Enabled = $TabPageMode
                    $TabPageSiteRoles.Enabled = $TabPageMode
                    $TabPageOther.Enabled = $TabPageMode
                }
                if ($CurrentTabPage -like "Central Administration Site") {
                    $TabPageGeneral.Enabled = $TabPageMode
                    $TabPagePrimary.Enabled = $TabPageMode
                    $TabPageSecondary.Enabled = $TabPageMode
                    $TabPageSiteRoles.Enabled = $TabPageMode
                    $TabPageOther.Enabled = $TabPageMode
                }
                if ($CurrentTabPage -like "Primary Site") {
                    $TabPageGeneral.Enabled = $TabPageMode
                    $TabPageCAS.Enabled = $TabPageMode
                    $TabPageSecondary.Enabled = $TabPageMode
                    $TabPageSiteRoles.Enabled = $TabPageMode
                    $TabPageOther.Enabled = $TabPageMode
                }
                if ($CurrentTabPage -like "Secondary Site") {
                    $TabPageGeneral.Enabled = $TabPageMode
                    $TabPageCAS.Enabled = $TabPageMode
                    $TabPagePrimary.Enabled = $TabPageMode
                    $TabPageSiteRoles.Enabled = $TabPageMode
                    $TabPageOther.Enabled = $TabPageMode
                }
                if ($CurrentTabPage -like "Site System Roles") {
                    $TabPageGeneral.Enabled = $TabPageMode
                    $TabPageCAS.Enabled = $TabPageMode
                    $TabPagePrimary.Enabled = $TabPageMode
                    $TabPageSecondary.Enabled = $TabPageMode
                    $TabPageOther.Enabled = $TabPageMode
                }
                if ($CurrentTabPage -like "Other") {
                    $TabPageGeneral.Enabled = $TabPageMode
                    $TabPageCAS.Enabled = $TabPageMode
                    $TabPagePrimary.Enabled = $TabPageMode
                    $TabPageSecondary.Enabled = $TabPageMode
                    $TabPageSiteRoles.Enabled = $TabPageMode
                }
            }
            else {
                $TabPageGeneral.Enabled = $TabPageMode
                $TabPageCAS.Enabled = $TabPageMode
                $TabPagePrimary.Enabled = $TabPageMode
                $TabPageSecondary.Enabled = $TabPageMode
                $TabPageSiteRoles.Enabled = $TabPageMode
                $TabPageOther.Enabled = $TabPageMode
            }
        }
    }
}

function Interactive-RadioButtons {
    param(
    [parameter(Mandatory=$true)]
    [ValidateSet("Enable","Disable")]
    $Mode,
    [parameter(Mandatory=$true)]
    [ValidateSet("Other","SiteRoles")]
    $Module
    )
    Begin {
        switch ($Mode) {
            "Enable" { $TabPageRadioButtonMode = $true }
            "Disable" { $TabPageRadioButtonMode = $false }
        }
    }
    Process {
        if ($Module -eq "SiteRoles") {
            foreach ($Control in $TabPageSiteRoles.Controls) {
                if ($Control.GetType().ToString() -eq "System.Windows.Forms.RadioButton") {
                    $Control.Enabled = $TabPageRadioButtonMode
                }
                if ($Control.GetType().ToString() -eq "System.Windows.Forms.ComboBox") {
                    $Control.Enabled = $TabPageRadioButtonMode
                }
            }
        }
        if ($Module -eq "Other") {
            foreach ($Control in $TabPageOther.Controls) {
                if ($Control.GetType().ToString() -eq "System.Windows.Forms.RadioButton") {
                    $Control.Enabled = $TabPageRadioButtonMode
                }
                if ($Control.GetType().ToString() -eq "System.Windows.Forms.ComboBox") {
                    $Control.Enabled = $TabPageRadioButtonMode
                }
                if ($Control.GetType().ToString() -eq "System.Windows.Forms.CheckBox") {
                    $Control.Enabled = $TabPageRadioButtonMode
                }
                if ($Control.GetType().ToString() -eq "System.Windows.Forms.TextBox") {
                    $Control.Enabled = $TabPageRadioButtonMode
                }
            }
        }
    }
}

function Interactive-SiteRolesControlVisibility {
    param(
    [parameter(Mandatory=$true)]
    [ValidateSet("Enable","Disable")]
    $Mode,
    [parameter(Mandatory=$true)]
    [ValidateSet("MP","DP","AppCat","EP","SMP")]
    $Module
    )
    Begin {
        $ControlsArrayList = New-Object System.Collections.ArrayList
        $ControlsArrayList.AddRange(@("Option Enrollment Point","Option Management Point","Option Distribution Point","Option Application Catalog","Option Site System Roles","Option State Migration Point"))
        switch ($Mode) {
            "Enable" { $TabPageSiteRolesVisibilityMode = $true }
            "Disable" { $TabPageSiteRolesVisibilityMode = $false }
        }
    }
    Process {
        $SiteRolesControls = $TabPageSiteRoles.Controls
        $SiteRolesControls | ForEach-Object {
            $CurrentControl = $_
            if ($CurrentControl.GetType().ToString() -eq "System.Windows.Forms.RadioButton") {
                if (-not($ControlsArrayList -contains $CurrentControl.Name)) {
                    if (($CurrentControl.Name -eq $Module)) {
                        $CurrentControl.Visible = $TabPageSiteRolesVisibilityMode
                    }
                }
            }
            if ($CurrentControl.GetType().ToString() -eq "System.Windows.Forms.GroupBox") {
                if (-not($ControlsArrayList -contains $CurrentControl.Name)) {
                    if (($CurrentControl.Name -eq $Module)) {
                        $CurrentControl.Visible = $TabPageSiteRolesVisibilityMode
                    }
                }
            }
            if ($CurrentControl.GetType().ToString() -eq "System.Windows.Forms.CheckBox") {
                if (-not($ControlsArrayList -contains $CurrentControl.Name)) {
                    if (($CurrentControl.Name -eq $Module)) {
                        $CurrentControl.Visible = $TabPageSiteRolesVisibilityMode
                    }
                }
            }
            if ($CurrentControl.GetType().ToString() -eq "System.Windows.Forms.ComboBox") {
                if (-not($ControlsArrayList -contains $CurrentControl.Name)) {
                    if (($CurrentControl.Name -eq $Module)) {
                        $CurrentControl.Visible = $TabPageSiteRolesVisibilityMode
                    }
                }
            }
            if ($CurrentControl.GetType().ToString() -eq "System.Windows.Forms.TextBox") {
                if (-not($ControlsArrayList -contains $CurrentControl.Name)) {
                    if (($CurrentControl.Name -eq $Module)) {
                        $CurrentControl.Visible = $TabPageSiteRolesVisibilityMode
                    }
                }
            }
        }
    }
}

function Interactive-OtherControlVisibility {
    param(
    [parameter(Mandatory=$true)]
    [ValidateSet("Enable","Disable")]
    $Mode,
    [parameter(Mandatory=$true)]
    [ValidateSet("EAD","WSUS","ADK","SMC","NoSMS")]
    $Module
    )
    Begin {
        $OtherControlsArrayList = New-Object System.Collections.ArrayList
        $OtherControlsArrayList.AddRange(@("Option Extend Active Directory","Option Install WSUS","Option Install Windows ADK","Option System Management Container","Option Make a selection","Option No SMS on drive"))
        switch ($Mode) {
            "Enable" { $TabPageOtherVisibilityMode = $true }
            "Disable" { $TabPageOtherVisibilityMode = $false }
        }
    }
    Process {
        $OtherControls = $TabPageOther.Controls
        $OtherControls | ForEach-Object {
            $OtherCurrentControl = $_
            if ($OtherCurrentControl.GetType().ToString() -eq "System.Windows.Forms.RadioButton") {
                if (-not($OtherControlsArrayList -contains $OtherCurrentControl.Name)) {
                    if (($OtherCurrentControl.Name -eq $Module)) {
                        $CurrentControl.Visible = $TabPageOtherVisibilityMode
                    }
                }
            }
            if ($OtherCurrentControl.GetType().ToString() -eq "System.Windows.Forms.GroupBox") {
                if (-not($OtherControlsArrayList -contains $OtherCurrentControl.Name)) {
                    if (($OtherCurrentControl.Name -eq $Module)) {
                        $OtherCurrentControl.Visible = $TabPageOtherVisibilityMode
                    }
                }
            }
            if ($OtherCurrentControl.GetType().ToString() -eq "System.Windows.Forms.ComboBox") {
                if (-not($OtherControlsArrayList -contains $OtherCurrentControl.Name)) {
                    if (($OtherCurrentControl.Name -eq $Module)) {
                        $OtherCurrentControl.Visible = $TabPageOtherVisibilityMode
                    }
                }
            }
            if ($OtherCurrentControl.GetType().ToString() -eq "System.Windows.Forms.TextBox") {
                if (-not($OtherControlsArrayList -contains $OtherCurrentControl.Name)) {
                    if (($OtherCurrentControl.Name -eq $Module)) {
                        $OtherCurrentControl.Visible = $TabPageOtherVisibilityMode
                    }
                }
            }
            if ($OtherCurrentControl.GetType().ToString() -eq "System.Windows.Forms.CheckBox") {
                if (-not($OtherControlsArrayList -contains $OtherCurrentControl.Name)) {
                    if (($OtherCurrentControl.Name -eq $Module)) {
                        $OtherCurrentControl.Visible = $TabPageOtherVisibilityMode
                    }
                }
            }
        }
    }
}

function Validate-RunChecks {
    $ValidateCounter = 0
    if (Validate-RebootPendingCheck) {
        $ValidateCounter++
    }
    if (Validate-OSCheck) {
        $ValidateCounter++
    }
    if (Validate-PSCheck) {
        $ValidateCounter++
    }
    if (Validate-Elevated) {
        $ValidateCounter++
    }
    if ($ValidateCounter -ge 4) {
        Interactive-TabPages -Mode Enable
        Write-OutputBox -OutputBoxMessage "All validation checks passed successfully" -Type "INFO: " -Object General
        $CBValidationOverride.Enabled = $false
    }
    else {
        Interactive-TabPages -Mode Disable
        Write-OutputBox -OutputBoxMessage "All validation checks did not pass successfully, remediate the errors and re-launch the tool or check the override checkbox to use the tool anyway" -Type "ERROR: " -Object General
    }
}

function Validate-Elevated {
    $UserIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $UserWP = New-Object Security.Principal.WindowsPrincipal($UserIdentity)
    $ErrorActionPreference = "Stop"
    try {
        if ($UserWP.IsInRole("S-1-5-32-544")) {
            $PBElevated.Image = $ValidatedImage
		    $LabelGeneralElevated.Visible = $true
            Write-OutputBox -OutputBoxMessage "User has local administrative rights, and the tool was launched elevated" -Type "INFO: " -Object General
            return $true
        }
        else {
            $PBElevated.Image = $NonValidatedImage
		    $LabelGeneralElevated.Visible = $true
            Write-OutputBox -OutputBoxMessage "The tool requires local administrative rights and was not launched elevated" -Type "ERROR: " -Object General
            return $false
        }
    }
    catch [System.Exception] {
        Write-OutputBox -OutputBoxMessage "An error occured when attempting to query for elevation, possible due to issues contacting the domain or the tool is launched in a sub-domain. If used in a sub-domain, check the override checkbox to enable this tool" -Type "WARNING: " -Object General
        $PBElevated.Image = $NonValidatedImage
		$LabelGeneralElevated.Visible = $true
        $ErrorActionPreference = "Continue"
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

function Validate-RebootPendingCheck {
	$GetComputerName = $env:COMPUTERNAME
	$ValidateRebootPending = Validate-RebootPending -ComputerName $GetComputerName
	if ($ValidateRebootPending) {
        $PBReboot.Image = $NonValidatedImage
		$LabelGeneralRestart.Visible = $true
        Write-OutputBox -OutputBoxMessage "A reboot is pending, please restart the system" -Type "ERROR: " -Object General
        return $false
	}
	else {
        $PBReboot.Image = $ValidatedImage
		$LabelGeneralRestart.Visible = $true
        Write-OutputBox -OutputBoxMessage "Pending reboot checks validated successfully" -Type "INFO: " -Object General
        return $true
	}
}

function Validate-OSCheck {
    $OSProductType = Get-WmiObject -Namespace "root\cimv2" -Class Win32_OperatingSystem | Select-Object -ExpandProperty ProductType
    $OSBuildNumber = Get-WmiObject -Namespace "root\cimv2" -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber
	if (($OSProductType -eq 3) -and ($OSBuildNumber -ge 9200)) {
        Write-OutputBox -OutputBoxMessage "Supported operating system found" -Type "INFO: " -Object General
        $PBOS.Image = $ValidatedImage
        $LabelGeneralOS.Visible = $true
        return $true
	}
	else {
        if ($OSBuildNumber -lt 9200) {
		    Write-OutputBox -OutputBoxMessage "The detected operating system is not supported. This tool is supported on Windows Server 2012 and above" -Type "ERROR: " -Object General
            $PBOS.Image = $NonValidatedImage
            $LabelGeneralOS.Visible = $true
            return $false
        }
        if ($OSProductType -eq 2) {
		    Write-OutputBox -OutputBoxMessage "The detected system is a Domain Controller. This tool is not supported on this platform" -Type "ERROR: " -Object General
            $PBOS.Image = $NonValidatedImage
            $LabelGeneralOS.Visible = $true
            return $false
        }
        if ($OSProductType -eq 1) {
		    Write-OutputBox -OutputBoxMessage "The detected operating system is a Workstation OS. This tool is not supported on this platform" -Type "ERROR: " -Object General
            $PBOS.Image = $NonValidatedImage
            $LabelGeneralOS.Visible = $true
            return $false
        }
	}
}

function Validate-PSCheck {
    if ($host.Version -ge "3.0") {
        Write-OutputBox -OutputBoxMessage "Supported version of PowerShell was detected" -Type "INFO: " -Object General
        $PBPS.Image = $ValidatedImage
        $LabelGeneralPS.Visible = $true
        return $true
    }
    else {
        Write-OutputBox -OutputBoxMessage "Unsupported version of PowerShell detected. This tool requires PowerShell 3.0 and above" -Type "ERROR: " -Object General
        $PBPS.Image = $NonValidatedImage
        $LabelGeneralPS.Visible = $true
        return $false
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
            Write-OutputBox -OutputBoxMessage "Specified server name is the Schema Master role owner" -Type "INFO: " -Object Other
            return $true
        }
        elseif (($DCName -ne $SchemaMaster) -or ($DCName -ne $SchemaMaster.Split(".")[0])) {
           	Write-OutputBox -OutputBoxMessage "The specified server name is not the Schema Master role owner in the forest" -Type "ERROR: " -Object Other
            return $false
       	}
       	else {
           	return $false
       	}
   	}
}

function Validate-WSUS {
	$WSUSErrorHandler = 0
	if ((([System.Environment]::OSVersion.Version).Build -lt 9200) -or ([System.Environment]::Is64BitOperatingSystem -eq $false)) {
		$WSUSErrorHandler++
	}
	if ($WSUSErrorHandler -gt 0) {
		Write-OutputBox -OutputBoxMessage "Unsupported Operating System detected. Windows Server 2012 64-bit and later is supported" -Type "ERROR: " -Object Other
		$ButtonInstallWSUS.Enabled = $false
	}
	else {
		$GetComputerName = $env:COMPUTERNAME
		$ValidateWSUSRebootPending = Validate-RebootPending -ComputerName $GetComputerName
		if ($ValidateWSUSRebootPending) {
			$ButtonInstallWSUS.Enabled = $false
			Write-OutputBox -OutputBoxMessage "A reboot is pending, please restart the system." -Type "WARNING: " -Object Other
		}
		else {
            if (($TextBoxWSUSSQLServer.Text.Length -eq 0) -and ($RadioButtonSQL.Checked -eq $true)) {
                Write-OutputBox -OutputBoxMessage "Please enter a SQL Server computer name" -Type "ERROR: " -Object Other
            }
            else {
                Install-WSUS
            }
		}
	}	
}

function Install-CAS {
    Interactive-TabPages -Mode Disable
	$ProgressBarCAS.Value = 0
    $OutputBoxCAS.ResetText()
	$OSBuild = ([System.Environment]::OSVersion.Version).Build
	if ($OSBuild -ge 9200) {
		Write-OutputBox -OutputBoxMessage "Detected OS build version is $($OSBuild) running PowerShell version $($Host.Version)" -Type "INFO: " -Object CAS
		$WinFeatures = @("NET-Framework-Core","BITS","BITS-IIS-Ext","BITS-Compact-Server","RDC","WAS-Process-Model","WAS-Config-APIs","WAS-Net-Environment","Web-Server","Web-ISAPI-Ext","Web-ISAPI-Filter","Web-Net-Ext","Web-Net-Ext45","Web-ASP-Net","Web-ASP-Net45","Web-ASP","Web-Windows-Auth","Web-Basic-Auth","Web-URL-Auth","Web-IP-Security","Web-Scripting-Tools","Web-Mgmt-Service","Web-Stat-Compression","Web-Dyn-Compression","Web-Metabase","Web-WMI","Web-HTTP-Redirect","Web-Log-Libraries","Web-HTTP-Tracing","UpdateServices-RSAT","UpdateServices-API","UpdateServices-UI")
	}
    $ProgressBarCAS.Maximum = ($WinFeatures | Measure-Object).Count
    $ProgressPreference = "SilentlyContinue"
	$WarningPreference = "SilentlyContinue"	
    $ButtonInstallCAS.Enabled = $false
    $CBCASDownloadPrereqs.Enabled = $false
	$WinFeatures | ForEach-Object {
        $CurrentFeature = $_
		$CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (-not(Get-WindowsFeature -Name $CurrentFeature | Select-Object Name,Installed | Where-Object { $_.Installed -like "true" })) {
        	Write-OutputBox -OutputBoxMessage "Installing role: $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object CAS
			[System.Windows.Forms.Application]::DoEvents()
            if (([System.Environment]::OSVersion.Version).Build -ge 9200) {
                if ($CurrentFeature -eq "NET-Framework-Core") {
                    Add-WindowsFeature NET-Framework-Core -ErrorAction SilentlyContinue | Out-Null
                    if (Get-WindowsFeature -Name NET-Framework-Core | Select-Object Name,Installed | Where-Object { $_.Installed -like "false" }) {
                        Write-OutputBox -OutputBoxMessage "Failed to install $($CurrentFeatureDisplayName.DisplayName)" -Type "ERROR: " -Object CAS
                        do {
                            if (([System.Environment]::OSVersion.Version).Build -eq 9600) {
			                    $SetupDLLocation = Read-FolderBrowserDialog -Message "Browse the Windows Server 2012 R2 installation media for the '<drive-letter>:\sources\sxs' folder."
                            }
                            if (([System.Environment]::OSVersion.Version).Build -eq 9200) {
                                $SetupDLLocation = Read-FolderBrowserDialog -Message "Browse the Windows Server 2012 installation media for the '<drive-letter>:\sources\sxs' folder."
                            }
		                }
                        until (($SetupDLLocation.Length -gt 0) -and (Test-Path -Path "$($SetupDLLocation.SubString(0,2))\sources\sxs" -ErrorAction SilentlyContinue))
                        Write-OutputBox -OutputBoxMessage "Installing role with specified source location: $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object CAS
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
            Write-OutputBox -OutputBoxMessage "Skipping role (already installed): $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object CAS
        }
        $ProgressBarCAS.PerformStep()
    }
	Write-OutputBox -OutputBoxMessage "Installation completed" -Type "INFO: " -Object CAS
    if ($CBCASDownloadPrereqs.Checked -eq $true) {
		Get-PrereqFiles -Module CAS
        Write-OutputBox -OutputBoxMessage "Starting to verify that all features were successfully installed" -Type "INFO: " -Object CAS
        $ErrorVerify = 0
        $ProgressBarCAS.Value = 0
        $WinFeatures | ForEach-Object {
            $CurrentFeature = $_
            $CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
            if (Get-WindowsFeature $CurrentFeature | Where-Object { $_.Installed -eq $true}) {
                Write-OutputBox -OutputBoxMessage "Verified installed: $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object CAS
                $ProgressBarCAS.PerformStep()
            }
            else {
                $ErrorVerify++
                Write-OutputBox -OutputBoxMessage "Feature not installed: $($CurrentFeatureDisplayName.DisplayName)" -Type "ERROR: " -Object CAS
                $ProgressBarCAS.PerformStep()
            }
        }
        if ($ErrorVerify -eq 0) {
    	    Write-OutputBox -OutputBoxMessage "Successfully installed all required Windows Features" -Type "INFO: " -Object CAS
        }
        else {
            Write-OutputBox -OutputBoxMessage "One or more Windows Features was not installed" -Type "ERROR: " -Object CAS
        }
	}
	else {
		Write-OutputBox -OutputBoxMessage "Starting to verify that all features were successfully installed" -Type "INFO: " -Object CAS
        $ErrorVerify = 0
        $ProgressBarCAS.Value = 0
        $WinFeatures | ForEach-Object {
            $CurrentFeature = $_
            $CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
            if (Get-WindowsFeature $CurrentFeature | Where-Object { $_.Installed -eq $true}) {
                Write-OutputBox -OutputBoxMessage "Verified installed: $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object CAS
                $ProgressBarCAS.PerformStep()
            }
            else {
                $ErrorVerify++
                Write-OutputBox -OutputBoxMessage "Feature not installed: $($CurrentFeatureDisplayName.DisplayName)" -Type "ERROR: " -Object CAS
                $ProgressBarCAS.PerformStep()
            }
        }
        if ($ErrorVerify -eq 0) {
            Write-OutputBox -OutputBoxMessage "Successfully installed all required Windows Features" -Type "INFO: " -Object CAS
        }
        else {
            Write-OutputBox -OutputBoxMessage "One or more Windows Features was not installed" -Type "ERROR: " -Object CAS
        }
	}
    $ButtonInstallCAS.Enabled = $true
    $CBCASDownloadPrereqs.Enabled = $true
    Interactive-TabPages -Mode Enable
}

function Install-Primary {
    Interactive-TabPages -Mode Disable
	$ProgressBarPrimary.Value = 0
    $OutputBoxPrimary.ResetText()
	$OSBuild = ([System.Environment]::OSVersion.Version).Build
    if ($OSBuild -ge 9200) {
		Write-OutputBox -OutputBoxMessage "Detected OS build version is $($OSBuild) running PowerShell version $($host.Version)" -Type "INFO: " -Object Primary
		$WinFeatures = @("NET-Framework-Core","BITS","BITS-IIS-Ext","BITS-Compact-Server","RDC","WAS-Process-Model","WAS-Config-APIs","WAS-Net-Environment","Web-Server","Web-ISAPI-Ext","Web-ISAPI-Filter","Web-Net-Ext","Web-Net-Ext45","Web-ASP-Net","Web-ASP-Net45","Web-ASP","Web-Windows-Auth","Web-Basic-Auth","Web-URL-Auth","Web-IP-Security","Web-Scripting-Tools","Web-Mgmt-Service","Web-Stat-Compression","Web-Dyn-Compression","Web-Metabase","Web-WMI","Web-HTTP-Redirect","Web-Log-Libraries","Web-HTTP-Tracing","UpdateServices-RSAT","UpdateServices-API","UpdateServices-UI")
	}
    $ProgressBarPrimary.Maximum = ($WinFeatures | Measure-Object).Count
    $ProgressPreference = "SilentlyContinue"
	$WarningPreference = "SilentlyContinue"	
    $ButtonInstallPrimarySite.Enabled = $false
    $CBPrimaryDownloadPrereqs.Enabled = $false
	$WinFeatures | ForEach-Object {
        $CurrentFeature = $_
		$CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (-not(Get-WindowsFeature -Name $CurrentFeature | Select-Object Name,Installed | Where-Object { $_.Installed -like "true" })) {
        	Write-OutputBox -OutputBoxMessage "Installing role: $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object Primary
			[System.Windows.Forms.Application]::DoEvents()
            if (([System.Environment]::OSVersion.Version).Build -ge 9200) {
                if ($CurrentFeature -eq "NET-Framework-Core") {
                    Add-WindowsFeature NET-Framework-Core -ErrorAction SilentlyContinue | Out-Null
                    if (Get-WindowsFeature -Name NET-Framework-Core | Select-Object Name,Installed | Where-Object { $_.Installed -like "false" }) {
                        Write-OutputBox -OutputBoxMessage "Failed to install $($CurrentFeatureDisplayName.DisplayName)" -Type "ERROR: " -Object Primary
                        do {
                            if (([System.Environment]::OSVersion.Version).Build -eq 9600) {
			                    $SetupDLLocation = Read-FolderBrowserDialog -Message "Browse the Windows Server 2012 R2 installation media for the '<drive-letter>:\sources\sxs' folder."
                            }
                            if (([System.Environment]::OSVersion.Version).Build -eq 9200) {
                                $SetupDLLocation = Read-FolderBrowserDialog -Message "Browse the Windows Server 2012 installation media for the '<drive-letter>:\sources\sxs' folder."
                            }
		                }
                        until (($SetupDLLocation.Length -gt 0) -and (Test-Path -Path "$($SetupDLLocation.SubString(0,2))\sources\sxs" -ErrorAction SilentlyContinue))
                        Write-OutputBox -OutputBoxMessage "Installing role with specified source location: $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object Primary
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
            Write-OutputBox -OutputBoxMessage "Skipping role (already installed): $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object Primary
        }
        $ProgressBarPrimary.PerformStep()
    }
	Write-OutputBox -OutputBoxMessage "Installation completed" -Type "INFO: " -Object Primary
    if ($CBPrimaryDownloadPrereqs.Checked -eq $true) {
		Get-PrereqFiles -Module Primary
        Write-OutputBox -OutputBoxMessage "Starting to verify that all features were successfully installed" -Type "INFO: " -Object Primary
        $ErrorVerify = 0
        $ProgressBarPrimary.Value = 0
        $WinFeatures | ForEach-Object {
            $CurrentFeature = $_
            $CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
            if (Get-WindowsFeature $CurrentFeature | Where-Object { $_.Installed -eq $true}) {
                Write-OutputBox -OutputBoxMessage "Verified installed: $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object Primary
                $ProgressBarPrimary.PerformStep()
            }
            else {
                $ErrorVerify++
                Write-OutputBox -OutputBoxMessage "Feature not installed: $($CurrentFeatureDisplayName.DisplayName)" -Type "ERROR: " -Object Primary
                $ProgressBarPrimary.PerformStep()
            }
        }
        if ($ErrorVerify -eq 0) {
    	    Write-OutputBox -OutputBoxMessage "Successfully installed all required Windows Features" -Type "INFO: " -Object Primary
        }
        else {
            Write-OutputBox -OutputBoxMessage "One or more Windows Features was not installed" -Type "ERROR: " -Object Primary
        }
	}
	else {
		Write-OutputBox -OutputBoxMessage "Starting to verify that all features were successfully installed" -Type "INFO: " -Object Primary
        $ErrorVerify = 0
        $ProgressBarPrimary.Value = 0
        $WinFeatures | ForEach-Object {
            $CurrentFeature = $_
            $CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
            if (Get-WindowsFeature $CurrentFeature | Where-Object { $_.Installed -eq $true}) {
                Write-OutputBox -OutputBoxMessage "Verified installed: $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object Primary
                $ProgressBarPrimary.PerformStep()
            }
            else {
                $ErrorVerify++
                Write-OutputBox -OutputBoxMessage "Feature not installed: $($CurrentFeatureDisplayName.DisplayName)" -Type "ERROR: " -Object Primary
                $ProgressBarPrimary.PerformStep()
            }
        }
        if ($ErrorVerify -eq 0) {
            Write-OutputBox -OutputBoxMessage "Successfully installed all required Windows Features" -Type "INFO: " -Object Primary
        }
        else {
            Write-OutputBox -OutputBoxMessage "One or more Windows Features was not installed" -Type "ERROR: " -Object Primary
        }
	}
    $ButtonInstallPrimarySite.Enabled = $true
    $CBPrimaryDownloadPrereqs.Enabled = $true
    Interactive-TabPages -Mode Enable
}

function Install-Secondary {
    Interactive-TabPages -Mode Disable
    $ProgressBarSecondary.Value = 0
    $OutputBoxSecondary.ResetText()
	$OSBuild = ([System.Environment]::OSVersion.Version).Build
	if ($OSBuild -ge 9200) {
		Write-OutputBox -OutputBoxMessage "Detected OS build version is $($OSBuild) running PowerShell version $($host.Version)" -Type "INFO: " -Object Secondary
		$WinFeatures = @("NET-Framework-Core","BITS","BITS-IIS-Ext","BITS-Compact-Server","RDC","WAS-Process-Model","WAS-Config-APIs","WAS-Net-Environment","Web-Server","Web-ISAPI-Ext","Web-Windows-Auth","Web-Basic-Auth","Web-URL-Auth","Web-IP-Security","Web-Scripting-Tools","Web-Mgmt-Service","Web-Metabase","Web-WMI")
	}
    $ProgressBarSecondary.Maximum = ($WinFeatures | Measure-Object).Count
    $ProgressPreference = "SilentlyContinue"
	$WarningPreference = "SilentlyContinue"	
    $ButtonInstallSecondarySite.Enabled = $false
	$WinFeatures | ForEach-Object {
        $CurrentFeature = $_
		$CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (-not(Get-WindowsFeature -Name $CurrentFeature | Select-Object Name,Installed | Where-Object { $_.Installed -like "true" })) {
        	Write-OutputBox -OutputBoxMessage "Installing role: $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object Secondary
			[System.Windows.Forms.Application]::DoEvents()
            if (([System.Environment]::OSVersion.Version).Build -ge 9200) {
                if ($CurrentFeature -eq "NET-Framework-Core") {
                    Add-WindowsFeature NET-Framework-Core -ErrorAction SilentlyContinue | Out-Null
                    if (Get-WindowsFeature -Name NET-Framework-Core | Select-Object Name,Installed | Where-Object { $_.Installed -like "false" }) {
                        Write-OutputBox -OutputBoxMessage "Failed to install $($CurrentFeatureDisplayName.DisplayName)" -Type "ERROR: " -Object Secondary

                        do {
                            if (([System.Environment]::OSVersion.Version).Build -eq 9600) {
			                    $SetupDLLocation = Read-FolderBrowserDialog -Message "Browse the Windows Server 2012 R2 installation media for the '<drive-letter>:\sources\sxs' folder."
                            }
                            if (([System.Environment]::OSVersion.Version).Build -eq 9200) {
                                $SetupDLLocation = Read-FolderBrowserDialog -Message "Browse the Windows Server 2012 installation media for the '<drive-letter>:\sources\sxs' folder."
                            }
		                }
                        until (($SetupDLLocation.Length -gt 0) -and (Test-Path -Path "$($SetupDLLocation.SubString(0,2))\sources\sxs" -ErrorAction SilentlyContinue))
                        Write-OutputBox -OutputBoxMessage "Installing role with specified source location: $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object Secondary
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
            Write-OutputBox -OutputBoxMessage "Skipping role (already installed): $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object Secondary
        }
        $ProgressBarSecondary.PerformStep()
    }
    Write-OutputBox -OutputBoxMessage "Starting to verify that all features were successfully installed"  -Type "INFO: " -Object Secondary
    $ErrorVerify = 0
    $ProgressBarSecondary.Value = 0
    $WinFeatures | ForEach-Object {
        $CurrentFeature = $_
        $CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (Get-WindowsFeature $CurrentFeature | Where-Object { $_.Installed -eq $true}) {
            Write-OutputBox "Verified installed: $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object Secondary
            $ProgressBarSecondary.PerformStep()
        }
        else {
            $ErrorVerify++
            Write-OutputBox "Feature not installed: $($CurrentFeatureDisplayName.DisplayName)" -Type "ERROR: " -Object Secondary
            $ProgressBarSecondary.PerformStep()
        }
    }
    if ($ErrorVerify -eq 0) {
	    Write-OutputBox -OutputBoxMessage "Successfully installed all required Windows Features" -Type "INFO: " -Object Secondary
    }
    else {
        Write-OutputBox -OutputBoxMessage "One or more Windows Features was not installed" -Type "ERROR: " -Object Secondary
    }
    $ButtonInstallSecondarySite.Enabled = $true
    Interactive-TabPages -Mode Enable
}

function Install-AppCat {
    Interactive-TabPages -Mode Disable
    Interactive-RadioButtons -Mode Disable -Module SiteRoles
    $ProgressBarSiteRoles.Value = 0
	$OSBuild = ([System.Environment]::OSVersion.Version).Build
	if ($OSBuild -ge 9200) {
		Write-OutputBox -OutputBoxMessage "Detected OS build version is $($OSBuild) running PowerShell version $($host.Version)" -Type "INFO: " -Object SiteRoles
		$WinFeatures = @("NET-Framework-Features","NET-Framework-Core","NET-HTTP-Activation","NET-Non-HTTP-Activ","NET-WCF-Services45","NET-WCF-HTTP-Activation45","RDC","WAS","WAS-Process-Model","WAS-NET-Environment","WAS-Config-APIs","Web-Server","Web-WebServer","Web-Common-Http","Web-Static-Content","Web-Default-Doc","Web-App-Dev","Web-ASP-Net","Web-ASP-Net45","Web-Net-Ext","Web-Net-Ext45","Web-ISAPI-Ext","Web-ISAPI-Filter","Web-Security","Web-Windows-Auth","Web-Filtering","Web-Mgmt-Tools","Web-Mgmt-Console","Web-Scripting-Tools","Web-Mgmt-Compat","Web-Metabase","Web-Lgcy-Mgmt-Console","Web-Lgcy-Scripting","Web-WMI")
	}
    $ProgressBarSiteRoles.Maximum = ($WinFeatures | Measure-Object).Count
    $ProgressPreference = "SilentlyContinue"
	$WarningPreference = "SilentlyContinue"
    $ButtonInstallSiteRoles.Enabled = $false
	$WinFeatures | ForEach-Object {
        $CurrentFeature = $_
		$CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (-not(Get-WindowsFeature -Name $CurrentFeature | Select-Object Name,Installed | Where-Object { $_.Installed -like "true" })) {
        	Write-OutputBox -OutputBoxMessage "Installing role: $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object SiteRoles
			[System.Windows.Forms.Application]::DoEvents()
            if (([System.Environment]::OSVersion.Version).Build -ge 9200) {
                if ($CurrentFeature -eq "NET-Framework-Core") {
                    Add-WindowsFeature NET-Framework-Core -ErrorAction SilentlyContinue | Out-Null
                    if (Get-WindowsFeature -Name NET-Framework-Core | Select-Object Name,Installed | Where-Object { $_.Installed -like "false" }) {
                        Write-OutputBox -OutputBoxMessage "Failed to install $($CurrentFeatureDisplayName.DisplayName)" -Type "ERROR: " -Object SiteRoles
                        do {
                            if (([System.Environment]::OSVersion.Version).Build -eq 9600) {
			                    $SetupDLLocation = Read-FolderBrowserDialog -Message "Browse the Windows Server 2012 R2 installation media for the '<drive-letter>:\sources\sxs' folder."
                            }
                            if (([System.Environment]::OSVersion.Version).Build -eq 9200) {
                                $SetupDLLocation = Read-FolderBrowserDialog -Message "Browse the Windows Server 2012 installation media for the '<drive-letter>:\sources\sxs' folder."
                            }
		                }
                        until (($SetupDLLocation.Length -gt 0) -and (Test-Path -Path "$($SetupDLLocation.SubString(0,2))\sources\sxs" -ErrorAction SilentlyContinue))
                        Write-OutputBox -OutputBoxMessage "Installing role with specified source location: $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object SiteRoles
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
            Write-OutputBox -OutputBoxMessage "Skipping role (already installed): $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object SiteRoles
        }
        $ProgressBarSiteRoles.PerformStep()
    }
    Write-OutputBox -OutputBoxMessage "Starting to verify that all features were successfully installed" -Type "INFO: " -Object SiteRoles
    $ErrorVerify = 0
    $ProgressBarSiteRoles.Value = 0
    $WinFeatures | ForEach-Object {
        $CurrentFeature = $_
        $CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (Get-WindowsFeature $CurrentFeature | Where-Object { $_.Installed -eq $true}) {
            Write-OutputBox "Verified installed: $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object SiteRoles
            $ProgressBarSiteRoles.PerformStep()
        }
        else {
            $ErrorVerify++
            Write-OutputBox "Feature not installed: $($CurrentFeatureDisplayName.DisplayName)" -Type "ERROR: " -Object SiteRoles
            $ProgressBarSiteRoles.PerformStep()
        }
    }
    if ($ErrorVerify -eq 0) {
	    Write-OutputBox -OutputBoxMessage "Successfully installed all required Windows Features" -Type "INFO: " -Object SiteRoles
    }
    else {
        Write-OutputBox -OutputBoxMessage "One or more Windows Features was not installed" -Type "ERROR: " -Object SiteRoles
    }
    Interactive-RadioButtons -Mode Enable -Module SiteRoles
    Interactive-TabPages -Mode Enable
    $ButtonInstallSiteRoles.Enabled = $true
}

function Install-MP {
    Interactive-TabPages -Mode Disable
    Interactive-RadioButtons -Mode Disable -Module SiteRoles
    $ProgressBarSiteRoles.Value = 0
	$OSBuild = ([System.Environment]::OSVersion.Version).Build
	if ($OSBuild -ge 9200) {
		Write-OutputBox -OutputBoxMessage "Detected OS build version is $($OSBuild) running PowerShell version $($host.Version)" -Type "INFO: " -Object SiteRoles
		$WinFeatures = @("NET-Framework-Core","NET-Framework-45-Features","NET-Framework-45-Core","NET-WCF-TCP-PortSharing45","NET-WCF-Services45","BITS","BITS-IIS-Ext","BITS-Compact-Server","RSAT-Bits-Server","Web-Server","Web-WebServer","Web-ISAPI-Ext","Web-WMI","Web-Metabase","Web-Windows-Auth","Web-ISAPI-Ext","Web-ASP","Web-Asp-Net","Web-Asp-Net45")
	}
    $ProgressBarSiteRoles.Maximum = ($WinFeatures | Measure-Object).Count
    $ProgressPreference = "SilentlyContinue"
	$WarningPreference = "SilentlyContinue"
    $ButtonInstallSiteRoles.Enabled = $false
	$WinFeatures | ForEach-Object {
        $CurrentFeature = $_
		$CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (-not(Get-WindowsFeature -Name $CurrentFeature | Select-Object Name,Installed | Where-Object { $_.Installed -like "true" })) {
        	Write-OutputBox -OutputBoxMessage "Installing role: $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object SiteRoles
			[System.Windows.Forms.Application]::DoEvents()
            if (([System.Environment]::OSVersion.Version).Build -ge 9200) {
                if ($CurrentFeature -eq "NET-Framework-Core") {
                    Add-WindowsFeature NET-Framework-Core -ErrorAction SilentlyContinue | Out-Null
                    if (Get-WindowsFeature -Name NET-Framework-Core | Select-Object Name,Installed | Where-Object { $_.Installed -like "false" }) {
                        Write-OutputBox -OutputBoxMessage "Failed to install $($CurrentFeatureDisplayName.DisplayName)" -Type "ERROR: " -Object SiteRoles
                        do {
                            if (([System.Environment]::OSVersion.Version).Build -eq 9600) {
			                    $SetupDLLocation = Read-FolderBrowserDialog -Message "Browse the Windows Server 2012 R2 installation media for the '<drive-letter>:\sources\sxs' folder."
                            }
                            if (([System.Environment]::OSVersion.Version).Build -eq 9200) {
                                $SetupDLLocation = Read-FolderBrowserDialog -Message "Browse the Windows Server 2012 installation media for the '<drive-letter>:\sources\sxs' folder."
                            }
		                }
                        until (($SetupDLLocation.Length -gt 0) -and (Test-Path -Path "$($SetupDLLocation.SubString(0,2))\sources\sxs" -ErrorAction SilentlyContinue))
                        Write-OutputBox -OutputBoxMessage "Installing role with specified source location: $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object SiteRoles
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
            Write-OutputBox -OutputBoxMessage "Skipping role (already installed): $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object SiteRoles
        }
        $ProgressBarSiteRoles.PerformStep()
    }
    Write-OutputBox -OutputBoxMessage "Starting to verify that all features were successfully installed" -Type "INFO: " -Object SiteRoles
    $ErrorVerify = 0
    $ProgressBarSiteRoles.Value = 0
    $WinFeatures | ForEach-Object {
        $CurrentFeature = $_
        $CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (Get-WindowsFeature $CurrentFeature | Where-Object { $_.Installed -eq $true}) {
            Write-OutputBox "Verified installed: $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object SiteRoles
            $ProgressBarSiteRoles.PerformStep()
        }
        else {
            $ErrorVerify++
            Write-OutputBox "Feature not installed: $($CurrentFeatureDisplayName.DisplayName)" -Type "ERROR: " -Object SiteRoles
            $ProgressBarSiteRoles.PerformStep()
        }
    }
    if ($ErrorVerify -eq 0) {
	    Write-OutputBox -OutputBoxMessage "Successfully installed all required Windows Features" -Type "INFO: " -Object SiteRoles
    }
    else {
        Write-OutputBox -OutputBoxMessage "One or more Windows Features was not installed" -Type "ERROR: " -Object SiteRoles
    }
    Interactive-RadioButtons -Mode Enable -Module SiteRoles
    Interactive-TabPages -Mode Enable
    $ButtonInstallSiteRoles.Enabled = $true
}

function Install-DP {
    Interactive-TabPages -Mode Disable
    Interactive-RadioButtons -Mode Disable -Module SiteRoles
    $ProgressBarSiteRoles.Value = 0
	$OSBuild = ([System.Environment]::OSVersion.Version).Build
	if ($OSBuild -ge 9200) {
		Write-OutputBox -OutputBoxMessage "Detected OS build version is $($OSBuild) running PowerShell version $($host.Version)" -Type "INFO: " -Object SiteRoles
		$WinFeatures = @("FS-FileServer","RDC","Web-WebServer","Web-Common-Http","Web-Default-Doc","Web-Dir-Browsing","Web-Http-Errors","Web-Static-Content","Web-Http-Redirect","Web-Health","Web-Http-Logging","Web-Performance","Web-Stat-Compression","Web-Security","Web-Filtering","Web-Windows-Auth","Web-App-Dev","Web-ISAPI-Ext","Web-Mgmt-Tools","Web-Mgmt-Console","Web-Mgmt-Compat","Web-Metabase","Web-WMI","Web-Scripting-Tools")
	}
	$ProgressBarSiteRoles.Maximum = ($WinFeatures | Measure-Object).Count
    $ProgressPreference = "SilentlyContinue"
	$WarningPreference = "SilentlyContinue"
    $ButtonInstallSiteRoles.Enabled = $false
	$WinFeatures | ForEach-Object {
        $CurrentFeature = $_
		$CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (-not(Get-WindowsFeature -Name $CurrentFeature | Select-Object Name,Installed | Where-Object { $_.Installed -like "true" })) {
        	Write-OutputBox -OutputBoxMessage "Installing role: $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object SiteRoles
			[System.Windows.Forms.Application]::DoEvents()
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
            Write-OutputBox -OutputBoxMessage "Skipping role (already installed): $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object SiteRoles
        }
        $ProgressBarSiteRoles.PerformStep()
    }
    Write-OutputBox -OutputBoxMessage "Starting to verify that all features were successfully installed" -Type "INFO: " -Object SiteRoles
    $ErrorVerify = 0
    $ProgressBarSiteRoles.Value = 0
    $WinFeatures | ForEach-Object {
        $CurrentFeature = $_
        $CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (Get-WindowsFeature $CurrentFeature | Where-Object { $_.Installed -eq $true}) {
            Write-OutputBox "Verified installed: $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object SiteRoles
            $ProgressBarSiteRoles.PerformStep()
        }
        else {
            $ErrorVerify++
            Write-OutputBox "Feature not installed: $($CurrentFeatureDisplayName.DisplayName)" -Type "ERROR: " -Object SiteRoles
            $ProgressBarSiteRoles.PerformStep()
        }
    }
    if ($ErrorVerify -eq 0) {
	    Write-OutputBox -OutputBoxMessage "Successfully installed all required Windows Features" -Type "INFO: " -Object SiteRoles
    }
    else {
        Write-OutputBox -OutputBoxMessage "One or more Windows Features was not installed" -Type "ERROR: " -Object SiteRoles
    }
    Interactive-RadioButtons -Mode Enable -Module SiteRoles
    Interactive-TabPages -Mode Enable
    $ButtonInstallSiteRoles.Enabled = $true	
}

function Install-EP {
    Interactive-TabPages -Mode Disable
    Interactive-RadioButtons -Mode Disable -Module SiteRoles
    $ProgressBarSiteRoles.Value = 0
	$OSBuild = ([System.Environment]::OSVersion.Version).Build
    if ($ComboBoxSiteRolesEP.Text -eq "Enrollment Point") {
	    if ($OSBuild -ge 9200) {
		    Write-OutputBox -OutputBoxMessage "Detected OS build version is $($OSBuild) running PowerShell version $($host.Version)" -Type "INFO: " -Object SiteRoles
		    $WinFeatures = @("Web-Server","Web-WebServer","Web-Default-Doc","Web-Dir-Browsing","Web-Http-Errors","Web-Static-Content","Web-Http-Logging","Web-Stat-Compression","Web-Filtering","Web-Net-Ext","Web-Asp-Net","Web-ISAPI-Ext","Web-ISAPI-Filter","Web-Mgmt-Console","Web-Metabase","NET-Framework-Core","NET-Framework-Features","NET-HTTP-Activation","NET-Framework-45-Features","NET-Framework-45-Core","NET-Framework-45-ASPNET","NET-WCF-Services45","NET-WCF-TCP-PortSharing45")
	    }
    }
    if ($ComboBoxSiteRolesEP.Text -eq "Enrollment Proxy Point") {
	    if ($OSBuild -ge 9200) {
		    Write-OutputBox -OutputBoxMessage "Detected OS build version is $($OSBuild) running PowerShell version $($host.Version)" -Type "INFO: " -Object SiteRoles
		    $WinFeatures = @("Web-Server","Web-WebServer","Web-Default-Doc","Web-Dir-Browsing","Web-Http-Errors","Web-Static-Content","Web-Http-Logging","Web-Stat-Compression","Web-Filtering","Web-Windows-Auth","Web-Net-Ext","Web-Net-Ext45","Web-Asp-Net","Web-Asp-Net45","Web-ISAPI-Ext","Web-ISAPI-Filter","Web-Mgmt-Console","Web-Metabase","NET-Framework-Core","NET-Framework-Features","NET-Framework-45-Features","NET-Framework-45-Core","NET-Framework-45-ASPNET","NET-WCF-Services45","NET-WCF-TCP-PortSharing45")
	    }
    }
    $ProgressBarSiteRoles.Maximum = ($WinFeatures | Measure-Object).Count
    $ProgressPreference = "SilentlyContinue"
	$WarningPreference = "SilentlyContinue"
    $ButtonInstallSiteRoles.Enabled = $false
	$WinFeatures | ForEach-Object {
        $CurrentFeature = $_
		$CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (-not(Get-WindowsFeature -Name $CurrentFeature | Select-Object Name,Installed | Where-Object { $_.Installed -like "true" })) {
        	Write-OutputBox -OutputBoxMessage "Installing role: $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object SiteRoles
			[System.Windows.Forms.Application]::DoEvents()
            if (([System.Environment]::OSVersion.Version).Build -ge 9200) {
                if ($CurrentFeature -eq "NET-Framework-Core") {
                    Add-WindowsFeature NET-Framework-Core -ErrorAction SilentlyContinue | Out-Null
                    if (Get-WindowsFeature -Name NET-Framework-Core | Select-Object Name,Installed | Where-Object { $_.Installed -like "false" }) {
                        Write-OutputBox -OutputBoxMessage "Failed to install $($CurrentFeatureDisplayName.DisplayName)" -Type "ERROR: " -Object SiteRoles
                        do {
                            if (([System.Environment]::OSVersion.Version).Build -eq 9600) {
			                    $SetupDLLocation = Read-FolderBrowserDialog -Message "Browse the Windows Server 2012 R2 installation media for the '<drive-letter>:\sources\sxs' folder."
                            }
                            if (([System.Environment]::OSVersion.Version).Build -eq 9200) {
                                $SetupDLLocation = Read-FolderBrowserDialog -Message "Browse the Windows Server 2012 installation media for the '<drive-letter>:\sources\sxs' folder."
                            }
		                }
                        until (($SetupDLLocation.Length -gt 0) -and (Test-Path -Path "$($SetupDLLocation.SubString(0,2))\sources\sxs" -ErrorAction SilentlyContinue))
                        Write-OutputBox -OutputBoxMessage "Installing role with specified source location: $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object SiteRoles
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
			        Wait-Job -Name $CurrentFeature -Force
			        Remove-Job -Name $CurrentFeature
                }
            }
        }
        else {
            Write-OutputBox -OutputBoxMessage "Skipping role (already installed): $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object SiteRoles
        }
        $ProgressBarSiteRoles.PerformStep()
    }
    Write-OutputBox -OutputBoxMessage "Starting to verify that all features were successfully installed" -Type "INFO: " -Object SiteRoles
    $ErrorVerify = 0
    $ProgressBarSiteRoles.Value = 0
    $WinFeatures | ForEach-Object {
        $CurrentFeature = $_
        $CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (Get-WindowsFeature $CurrentFeature | Where-Object { $_.Installed -eq $true}) {
            Write-OutputBox "Verified installed: $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object SiteRoles
            $ProgressBarSiteRoles.PerformStep()
        }
        else {
            $ErrorVerify++
            Write-OutputBox "Feature not installed: $($CurrentFeatureDisplayName.DisplayName)" -Type "ERROR: " -Object SiteRoles
            $ProgressBarSiteRoles.PerformStep()
        }
    }
    if ($ErrorVerify -eq 0) {
	    Write-OutputBox -OutputBoxMessage "Successfully installed all required Windows Features" -Type "INFO: " -Object SiteRoles
    }
    else {
        Write-OutputBox -OutputBoxMessage "One or more Windows Features was not installed" -Type "ERROR: " -Object SiteRoles
    }
    Interactive-RadioButtons -Mode Enable -Module SiteRoles
    Interactive-TabPages -Mode Enable
    $ButtonInstallSiteRoles.Enabled = $true
}

function Install-SMP {
    Interactive-TabPages -Mode Disable
    Interactive-RadioButtons -Mode Disable -Module SiteRoles
    $ProgressBarSiteRoles.Value = 0
	$OSBuild = ([System.Environment]::OSVersion.Version).Build
	if ($OSBuild -ge 9200) {
		Write-OutputBox -OutputBoxMessage "Detected OS build version is $($OSBuild) running PowerShell version $($host.Version)" -Type "INFO: " -Object SiteRoles
		$WinFeatures = @("Web-Server","Web-Common-Http","Web-Default-Doc","Web-Dir-Browsing","Web-Http-Errors","Web-Static-Content","Web-Http-Logging","Web-Dyn-Compression","Web-Filtering","Web-Windows-Auth","Web-Mgmt-Tools","Web-Mgmt-Console")
	}
	$ProgressBarSiteRoles.Maximum = ($WinFeatures | Measure-Object).Count
    $ProgressPreference = "SilentlyContinue"
	$WarningPreference = "SilentlyContinue"
    $ButtonInstallSiteRoles.Enabled = $false
	$WinFeatures | ForEach-Object {
        $CurrentFeature = $_
		$CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (-not(Get-WindowsFeature -Name $CurrentFeature | Select-Object Name,Installed | Where-Object { $_.Installed -like "true" })) {
        	Write-OutputBox -OutputBoxMessage "Installing role: $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object SiteRoles
			[System.Windows.Forms.Application]::DoEvents()
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
            Write-OutputBox -OutputBoxMessage "Skipping role (already installed): $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object SiteRoles
        }
        $ProgressBarSiteRoles.PerformStep()
    }
    Write-OutputBox -OutputBoxMessage "Starting to verify that all features were successfully installed" -Type "INFO: " -Object SiteRoles
    $ErrorVerify = 0
    $ProgressBarSiteRoles.Value = 0
    $WinFeatures | ForEach-Object {
        $CurrentFeature = $_
        $CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (Get-WindowsFeature $CurrentFeature | Where-Object { $_.Installed -eq $true}) {
            Write-OutputBox "Verified installed: $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object SiteRoles
            $ProgressBarSiteRoles.PerformStep()
        }
        else {
            $ErrorVerify++
            Write-OutputBox "Feature not installed: $($CurrentFeatureDisplayName.DisplayName)" -Type "ERROR: " -Object SiteRoles
            $ProgressBarSiteRoles.PerformStep()
        }
    }
    if ($ErrorVerify -eq 0) {
	    Write-OutputBox -OutputBoxMessage "Successfully installed all required Windows Features" -Type "INFO: " -Object SiteRoles
    }
    else {
        Write-OutputBox -OutputBoxMessage "One or more Windows Features was not installed" -Type "ERROR: " -Object SiteRoles
    }
    Interactive-RadioButtons -Mode Enable -Module SiteRoles
    Interactive-TabPages -Mode Enable
    $ButtonInstallSiteRoles.Enabled = $true	
}

function Extend-ActiveDirectorySchema {
    $ButtonInstallOther.Enabled = $false
    Interactive-RadioButtons -Mode Disable -Module Other
	$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent() 
	$WindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($CurrentUser)
    if (-not($TextBoxDC.Text -eq $WaterMarkDC)) {
        if (Test-Connection -ComputerName $TextBoxDC.Text -Count 1 -ErrorAction SilentlyContinue) {
	        if (($WindowsPrincipal.IsInRole("Domain Admins")) -and ($WindowsPrincipal.IsInRole("Schema Admins"))) {
    	        $TextBoxDC.Enabled = $false
                do { 
			        $SetupDLLocation = Read-FolderBrowserDialog -Message "Browse to the '<ConfigMgr source files>\SMSSETUP\BIN\X64' folder."
		        }
		        until (Test-Path -Path "$($SetupDLLocation)\EXTADSCH.EXE")
    	        $DC = $TextBoxDC.Text
    	        $GetPath = Get-ChildItem -Recurse -Filter "EXTADSCH.EXE" -Path "$($SetupDLLocation)"
    	        $Path = $GetPath.DirectoryName + "\EXTADSCH.EXE"
    	        $Destination = "\\" + $DC + "\C$"
		        Write-OutputBox -OutputBoxMessage "Copying EXTADSCH.EXE to the specified domain controller" -Type "INFO: " -Object Other
    	        Copy-Item $Path $Destination -Force
		        Write-OutputBox -OutputBoxMessage "Starting to extend the Active Directory schema" -Type "INFO: " -Object Other
    	        Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList "C:\EXTADSCH.EXE" -ComputerName $DC | Out-Null
		        Start-Sleep -Seconds 10
    	        $Content = Get-Content -Path "\\$($DC)\C$\extadsch.log"
    	        if ($Content -match "Successfully extended the Active Directory schema") {
        	        Write-OutputBox -OutputBoxMessage "Active Directory schema was successfully extended" -Type "INFO: " -Object Other
    	        }
    	        else {
			        Write-OutputBox -OutputBoxMessage "Active Directory was not extended successfully, refer to C:\ExtADSch.log on the domain controller" -Type "ERROR: " -Object Other
    	        }
	        }
	        else {
		        Write-OutputBox -OutputBoxMessage "Current logged on user is not a member of the Domain Admins or Schema Admins group" -Type "ERROR: " -Object Other
	        }
        }
        else {
            Write-OutputBox -OutputBoxMessage "Unable to establish a connection to the specified domain controller" -Type "ERROR: " -Object Other
        }
    }
    else {
        Write-OutputBox -OutputBoxMessage "Please enter a hostname of a domain controller" -Type "ERROR: " -Object Other
    }
    Interactive-RadioButtons -Mode Enable -Module Other
    $ButtonInstallOther.Enabled = $true
    $TextBoxDC.Enabled = $true
}

function Install-WSUS {
    Interactive-RadioButtons -Mode Disable -Module Other
    Interactive-TabPages -Mode Disable
    $ButtonInstallOther.Enabled = $false
    if ($ComboBoxOtherWSUS.Text -eq "WID") {
        $WinFeatures = @("UpdateServices","UpdateServices-WidDB","UpdateServices-Services","UpdateServices-RSAT","UpdateServices-API","UpdateServices-UI")
    }
    if ($ComboBoxOtherWSUS.Text -eq "SQL") {
        $WinFeatures = @("UpdateServices-Services","UpdateServices-RSAT","UpdateServices-API","UpdateServices-UI","UpdateServices-DB")    
    }
    $ProgressBarOther.Maximum = 10
    $ProgressPreference = "SilentlyContinue"
	$WarningPreference = "SilentlyContinue"	
	$ProgressBarOther.PerformStep()
	$WinFeatures | ForEach-Object {
        $CurrentFeature = $_
		$CurrentFeatureDisplayName = Get-WindowsFeature | Select-Object Name,DisplayName | Where-Object { $_.Name -like "$($CurrentFeature)"}
        if (-not(Get-WindowsFeature -Name $CurrentFeature | Select-Object Name,Installed | Where-Object { $_.Installed -like "true" })) {
        	Write-OutputBox -OutputBoxMessage "Installing role: $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object Other
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
            Write-OutputBox -OutputBoxMessage "Skipping role (already installed): $($CurrentFeatureDisplayName.DisplayName)" -Type "INFO: " -Object Other
        }
        $ProgressBarOther.PerformStep()
    }
	Write-OutputBox -OutputBoxMessage "Successfully installed all required Windows Features" -Type "INFO: " -Object Other
	$WSUSContentPath = Read-FolderBrowserDialog -Message "Choose a location where WSUS content will be stored, e.g. C:\WSUS"
	$ProgressBarOther.PerformStep()
    if (-not(Test-Path -Path $WSUSContentPath)) {
            New-Item $WSUSContentPath -ItemType Directory | Out-Null
    }
	if (Test-Path -Path "$($Env:ProgramFiles)\Update Services\Tools\WsusUtil.exe") {
        $WSUSUtil = "$($Env:ProgramFiles)\Update Services\Tools\WsusUtil.exe"
        if ($ComboBoxOtherWSUS.SelectedItem -eq "WID") {
            $WSUSUtilArgs = "POSTINSTALL CONTENT_DIR=$($WSUSContentPath)"
        }
        if ($ComboBoxOtherWSUS.Text -eq "SQL") {
            if (($TextBoxWSUSSQLServer.Text.Length -ge 1) -and ($TextBoxWSUSSQLServer.Text -notlike $WaterMarkWSUSSQLServer) -and ($TextBoxWSUSSQLInstance.Text -like $WaterMarkWSUSSQLInstance)) {
                Write-OutputBox -OutputBoxMessage "Choosen configuration is SQL Server, default instance" -Type "INFO: " -Object Other
                $WSUSUtilArgs = "POSTINSTALL SQL_INSTANCE_NAME=$($TextBoxWSUSSQLServer.Text) CONTENT_DIR=$($WSUSContentPath)"
            }
            if (($TextBoxWSUSSQLServer.Text.Length -ge 1) -and ($TextBoxWSUSSQLServer.Text -notlike $WaterMarkWSUSSQLServer) -and ($TextBoxWSUSSQLInstance.Text.Length -ge 1) -and ($TextBoxWSUSSQLInstance.Text -notlike $WaterMarkWSUSSQLInstance)) {
                Write-OutputBox -OutputBoxMessage "Choosen configuration is SQL Server, named instance" -Type "INFO: " -Object Other
                $WSUSUtilArgs = "POSTINSTALL SQL_INSTANCE_NAME=$($TextBoxWSUSSQLServer.Text)\$($TextBoxWSUSSQLInstance.Text) CONTENT_DIR=$($WSUSContentPath)"
		    }
        }
    	Write-OutputBox -OutputBoxMessage "Starting WSUS post install configuration, this will take some time" -Type "INFO: " -Object Other
		$ProgressBarOther.PerformStep()
    	Start-Process -FilePath $WSUSUtil -ArgumentList $WSUSUtilArgs -NoNewWindow -Wait -RedirectStandardOutput "C:\temp.txt" | Out-Null
		$ProgressBarOther.PerformStep()
    	Write-OutputBox -OutputBoxMessage "Successfully installed and configured WSUS" -Type "INFO: " -Object Other
        Remove-Item "C:\temp.txt" -Force
        $ProgressBarOther.PerformStep()
	}
    else {
		$ProgressBarOther.Value = 10
		Write-OutputBox -OutputBoxMessage "Unable to locate $($WSUSUtil)" -Type "INFO: " -Object Other
	}
    Interactive-RadioButtons -Mode Enable -Module Other
    Interactive-TabPages -Mode Enable
    $ButtonInstallOther.Enabled = $true
}

function Install-ADK {
    Interactive-RadioButtons -Mode Disable -Module Other
    Interactive-TabPages -Mode Disable
    $ButtonInstallOther.Enabled = $false
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
	if (($ComboBoxOtherADK.Text -eq "Online") -and ($ADKInstalledFeatures.Length -ne 3)) {
		$ADKOnlineArguments = "/norestart /q /ceip off /features OptionId.WindowsPreinstallationEnvironment OptionId.DeploymentTools OptionId.UserStateMigrationTool"
		$ADKDownloadFolder = "C:\Downloads"
		$ADKSetupFile = "adksetup.exe"
		Get-WebDownloadFile -URL "http://download.microsoft.com/download/6/A/E/6AEA92B0-A412-4622-983E-5B305D2EBE56/adk/adksetup.exe" -DownloadFolder $ADKDownloadFolder -FileName $ADKSetupFile -Module Other
		Write-OutputBox -OutputBoxMessage "Download completed" -Type "INFO: " -Object Other
		[System.Windows.Forms.Application]::DoEvents()
		Write-OutputBox -OutputBoxMessage "Starting Windows ADK installation" -Type "INFO: " -Object Other
		[System.Windows.Forms.Application]::DoEvents()
		Write-OutputBox -OutputBoxMessage "Downloading Windows ADK components and installing, this will take some time depending on your internet connection" -Type "INFO: " -Object Other
		[System.Windows.Forms.Application]::DoEvents()
		Start-Process -FilePath "$($ADKDownloadFolder)\$($ADKSetupFile)" -ArgumentList $ADKOnlineArguments
		while (Get-WmiObject -Class Win32_Process -Filter 'Name="adksetup.exe"') {
			[System.Windows.Forms.Application]::DoEvents()
			Start-Sleep -Milliseconds 500
		}
		Write-OutputBox -OutputBoxMessage "Successfully installed Windows ADK" -Type "INFO: " -Object Other
	}
    if (($ComboBoxOtherADK.Text -eq "Offline") -and ($ADKInstalledFeatures.Length -ne 3)) {
        $ADKOfflineArguments = "/norestart /q /ceip off /features OptionId.WindowsPreinstallationEnvironment OptionId.DeploymentTools OptionId.UserStateMigrationTool"
		$ADKSetupFile = "adksetup.exe"
		do {
			$SetupLocation = Read-FolderBrowserDialog -Message "Select the folder where adksetup.exe is located"
			if (-not(Test-Path -Path "$($SetupLocation)\$($ADKSetupFile)")) {
				$ADKShellObject = New-Object -ComObject WScript.Shell
				$PopupValidate = $ADKShellObject.Popup("Unable to find $($ADKSetupFile) in the selected folder",0,"Unable to locate file",0)
			}
		}
		until (Test-Path -Path "$($SetupLocation)\$($ADKSetupFile)")
        Write-OutputBox -OutputBoxMessage "Starting Windows ADK installation, this will take some time" -Type "INFO: " -Object Other
        Start-Process -FilePath "$($SetupLocation)\$($ADKSetupFile)" -ArgumentList $ADKOfflineArguments
		while (Get-WmiObject -Class Win32_Process -Filter 'Name="adksetup.exe"') {
			[System.Windows.Forms.Application]::DoEvents()
			Start-Sleep -Milliseconds 500
		}
		Write-OutputBox -OutputBoxMessage "Successfully installed Windows ADK" -Type "INFO: " -Object Other
    }    
    if ($ADKInstalledFeatures.Length -eq 3) {
            Write-OutputBox -OutputBoxMessage "All required Windows ADK features are already installed, skipping install" -Type "INFO: " -Object Other
    }
    Interactive-RadioButtons -Mode Enable -Module Other
    Interactive-TabPages -Mode Enable
    $ButtonInstallOther.Enabled = $true
}

function Create-SMCContainer {
    $ObjectDomain = New-Object System.DirectoryServices.DirectoryEntry
    $ObjectContainer = $ObjectDomain.Create("container", "CN=System Management,CN=System")
    $ObjectContainer.SetInfo() | Out-Null
    $SuccssContainerCreate = Get-SMCContainer
    if ($SuccssContainerCreate -eq $true) {
        return $true
    }
    else {
        return $false
    }
}

function Get-SMCContainer {
    $ADFilter = "(&(objectClass=container)(cn=*System Management*))"
    $ADSearch = New-Object System.DirectoryServices.DirectorySearcher($ADFilter) 
    $ADResult = $ADSearch.FindOne()
    $SuccessContainer = $ADResult.GetDirectoryEntry()
    if ($SuccessContainer) {
        return $true
    }
    else {
        return $false
    }
}

function Configure-SystemManagementContainer {
    Interactive-RadioButtons -Mode Disable -Module Other
    Interactive-TabPages -Mode Disable
    $ButtonInstallOther.Enabled = $false
    $ADGroupName = $Global:SMCSharedData
    $ShellObject = New-Object -ComObject Wscript.Shell
    $CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $WindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($CurrentUser)
    if ($WindowsPrincipal.IsInRole("Domain Admins")) {
        if ($CBSMCCreate.Checked -eq $true) {
            if (Get-SMCContainer -eq $true) {
                Write-OutputBox -OutputBoxMessage "Found the System Management container, will not create it" -Type "INFO: " -Object Other
            }
            else {
                Write-OutputBox -OutputBoxMessage "System Management container not found, creating it" -Type "INFO: " -Object Other
                Create-SMCContainer
                if (Get-SMCContainer -eq $true) {
                    Write-OutputBox -OutputBoxMessage "System Management container created successfully" -Type "INFO: " -Object Other
                }
            }
        }
        if (Get-SMCContainer -eq $true) {
            Write-OutputBox -OutputBoxMessage "Found the System Management container" -Type "INFO: " -Object Other
            Write-OutputBox -OutputBoxMessage "Checking if '$($ADGroupName)' is already added to the System Management container" -Type "INFO: " -Object Other
            $ADDomain = New-Object System.DirectoryServices.DirectoryEntry | Select-Object -ExpandProperty distinguishedName
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
                Write-OutputBox -OutputBoxMessage "'$($ADGroupName)' is already added to the System Management container" -Type "ERROR: " -Object Other
            }
            else {
                try {
                    Write-OutputBox -OutputBoxMessage "Adding '$($ADGroupName)' to the System Management container" -Type "INFO: " -Object Other
                    $ObjectGUID = New-Object GUID 00000000-0000-0000-0000-000000000000
                    $ContainerACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule ($ADGroupSID,"GenericAll","Allow","All",$ObjectGUID)
                    $ContainerObject.ObjectSecurity.AddAccessRule($ContainerACE)
                    $ContainerObject.CommitChanges()
                    Write-OutputBox -OutputBoxMessage "Succesfully added '$($ADGroupName)' to the System Management container" -Type "INFO: " -Object Other
                }
                catch {
                    Write-OutputBox -OutputBoxMessage "$($_.Exception.Message)" -Type "ERROR: " -Object Other
                }
            }
        }
        else {
            Write-OutputBox -OutputBoxMessage "Unable to find the System Management container, will not continue" -Type "ERROR: " -Object Other
        }
    }
    else {
        Write-OutputBox -OutputBoxMessage "The current user is not a member of the Domain Admins group, please run this script as a member of the Domain Admin group" -Type "ERROR: " -Object Other
    }
    Interactive-RadioButtons -Mode Enable -Module Other
    Interactive-TabPages -Mode Enable
    $ButtonInstallOther.Enabled = $true
}

function Search-SMC {
    $FormSMCSearch.Controls.AddRange(@($ButtonSystemManagementContainerGroupSearch, $ButtonSMCOK, $TextBoxSMCGroupSearch, $TextBoxSMCGroupResult, $DGVSMCGroup, $GBSystemManagementContainerGroup, $GBSystemManagementContainerGroupSearch))
    $FormSMCSearch.Add_Shown({$FormSMCSearch.Activate()})
    [void]$FormSMCSearch.ShowDialog()
    $ButtonSMCOK.Enabled = $false
    if (($DGVSMCGroup.Rows | Measure-Object).Count -ge 1) {
        $TextBoxSMCGroupSearch.ResetText()
        $TextBoxSMCGroupResult.ResetText()
        $DGVSMCGroup.Rows.Clear()
        $DGVSMCGroup.Refresh()
    }
}

function Create-NoSMSOnDrive {
    $FilePathNoSMS = (Join-Path -Path $ComboBoxOtherNoSMS.SelectedItem -ChildPath "NO_SMS_ON_DRIVE.SMS")
    if (-not(Test-Path -Path $FilePathNoSMS -ErrorAction SilentlyContinue)) {
        try {
            New-Item -Path $FilePathNoSMS -ItemType File -ErrorAction Stop -Force
            Write-OutputBox -OutputBoxMessage "Successfully created a NO_SMS_ON_DRIVE.SMS file on target drive" -Type "INFO: " -Object Other
        }
        catch [System.Exception] {
            Write-OutputBox -OutputBoxMessage "Unable to create NO_SMS_ON_DRIVE.SMS file on target drive, this operatin requires elevation" -Type "WARNING: " -Object Other
        }
    }
    else {
        Write-OutputBox -OutputBoxMessage "A NO_SMS_ON_DRIVE.SMS file already exists on target drive" -Type "INFO: " -Object Other
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
    if ($TextBoxSMCGroupSearch.Text.Length -ge 1) {
        $ADGroupFilter = "(&(ObjectCategory=group)(samAccountName=*$($TextBoxSMCGroupSearch.Text)*))"
        $ADGroupSearch = New-Object System.DirectoryServices.DirectorySearcher($ADGroupFilter)
        $ADGroupSearch.FindAll() | ForEach-Object { $DGVSMCGroup.Rows.Add(([string]$_.Properties.Item("samAccountName"))) | Out-Null }
    }
    else {
        Write-OutputBox -OutputBoxMessage "Please enter an Active Directory group to search for in the text box" -Type "ERROR: " -Object Other
    }
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
	[string]$FileName,
    [Parameter(Mandatory=$true)]
    [ValidateSet("SiteRoles","Other")]
    [string]$Module
	)
	process {
        if ($Module -eq "SiteRoles") {
		    $ProgressBarSiteRoles.Maximum = 100
            $ProgressBarSiteRoles.Value = 0
        }
        if ($Module -eq "Other") {
		    $ProgressBarOther.Maximum = 100
            $ProgressBarOther.Value = 0
        }
    	$WebClient = New-Object System.Net.WebClient
		if (-not(Test-Path -Path $DownloadFolder)) {
			Write-OutputBox -OutputBoxMessage "Creating download folder: $($DownloadFolder)" -Type "INFO: " -Object $Module
			[System.Windows.Forms.Application]::DoEvents()
            New-Item $DownloadFolder -ItemType Directory | Out-Null
        }
		$Global:DownloadComplete = $False
        $EventDataComplete = Register-ObjectEvent $WebClient DownloadFileCompleted -SourceIdentifier WebClient.DownloadFileComplete -Action {$Global:DownloadComplete = $True}
        $EventDataProgress = Register-ObjectEvent $WebClient DownloadProgressChanged -SourceIdentifier WebClient.DownloadProgressChanged -Action { $Global:DPCEventArgs = $EventArgs }    
    	$WebClient.DownloadFileAsync($URL, "$($DownloadFolder)\$($FileName)")
		Write-OutputBox -OutputBoxMessage "Downloading ($($FileName) to $($DownloadFolder)" -Type "INFO: " -Object $Module
		do {                
            $PercentComplete = $Global:DPCEventArgs.ProgressPercentage
			$DownloadedBytes = $Global:DPCEventArgs.BytesReceived
			$TotalBytes = $Global:DPCEventArgs.TotalBytesToReceive
            if ($Module -eq "SiteRoles") {
                $ProgressBarSiteRoles.Value = $PercentComplete
            }
            if ($Module -eq "Other") {
                $ProgressBarOther.Value = $PercentComplete
            }            
            [System.Windows.Forms.Application]::DoEvents()
        }
		until ($Global:DownloadComplete)
    	$WebClient.Dispose()
        Unregister-Event -SourceIdentifier WebClient.DownloadProgressChanged
        Unregister-Event -SourceIdentifier WebClient.DownloadFileComplete
	}	
}

function Get-PrereqFiles {
    param(
    [parameter(Mandatory=$true)]
    [ValidateSet("CAS","Primary")]
    [string]$Module
	)
    do {
	    $GetDownloadDestination = Read-FolderBrowserDialog -Message "Browse for a folder where the prerequisite files will be downloaded to."
        $DownloadDestination = '"' + $GetDownloadDestination + '"'
    }
    until (Test-Path -Path $GetDownloadDestination)
	Write-OutputBox -OutputBoxMessage "Prerequisite files will be downloaded to: $($GetDownloadDestination)" -Type "INFO: " -Object $Module
	do { 
		$SetupDLLocation = Read-FolderBrowserDialog -Message "Browse to the '<ConfigMgr source files>\SMSSETUP\BIN\X64' folder."
	}
	until (Test-Path -Path "$($SetupDLLocation)\setupdl.exe")
	Write-OutputBox -OutputBoxMessage "Downloading prerequisite files from Microsoft" -Type "INFO: " -Object $Module
	do {
		Start-Process -FilePath "$($SetupDLLocation)\setupdl.exe" -ArgumentList $DownloadDestination -Wait
	}
	until ((Get-ChildItem -Path $GetDownloadDestination | Measure-Object).Count -ge 59)
	Write-OutputBox -OutputBoxMessage "Successfully downloaded all prerequisite files" -Type "INFO: " -Object $Module
}

function Add-SiteServerLocalAdministrators {
    param(
        [parameter(Mandatory=$true)]
        [string]$ComputerName
    )
    $ErrorActionPreference = "Stop"
    try {
        $AdministratorsGroup = [ADSI](”WinNT://$($env:COMPUTERNAME)/Administrators”)
        $AdministratorsGroupMembers = $AdministratorsGroup.PSBase.Invoke(“Members”)
        foreach ($Member in $AdministratorsGroupMembers) {
            [array]$AdministratorsGroupMemberList += $Member.GetType().InvokeMember(“Name”, ‘GetProperty’, $null, $Member, $null) 
        }
        if (($ComputerName + "`$") -in $AdministratorsGroupMemberList) {
            Write-OutputBox -OutputBoxMessage "Site Server '$($ComputerName)' is already a member of the local Administrators group" -Type "INFO: " -Object SiteRoles
        }
        else {
            $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain() | Select-Object -ExpandProperty Name
            $Group = [ADSI]("WinNT://$($env:COMPUTERNAME)/Administrators")
            $Computer = [ADSI]("WinNT://$($Domain)/$($ComputerName)$")
            $Group.PSBase.Invoke("Add", $Computer.PSBase.Path)
            Write-OutputBox -OutputBoxMessage "Added Site Server '$($ComputerName)' to the local Administrators group" -Type "INFO: " -Object SiteRoles
        }
    }
    catch [System.Exception] {
        Write-OutputBox -OutputBoxMessage "An error occured when attempting to add '$($ComputerName)' to the local Administrators group" -Type "ERROR: " -Object SiteRoles
    }
}

function Write-OutputBox {
	param(
	[parameter(Mandatory=$true)]
	[string]$OutputBoxMessage,
	[ValidateSet("WARNING: ","ERROR: ","INFO: ")]
	[string]$Type,
    [parameter(Mandatory=$true)]
    [ValidateSet("General","CAS","Primary","Secondary","SiteRoles","Other")]
    [string]$Object
	)
	Process {
        if ($Object -like "General") {
		    if ($OutputBoxGeneral.Text.Length -eq 0) {
			    $OutputBoxGeneral.Text = "$($Type)$($OutputBoxMessage)"
			    [System.Windows.Forms.Application]::DoEvents()
                $OutputBoxGeneral.ScrollToCaret()
		    }
		    else {
			    $OutputBoxGeneral.AppendText("`n$($Type)$($OutputBoxMessage)")
			    [System.Windows.Forms.Application]::DoEvents()
                $OutputBoxGeneral.ScrollToCaret()
		    }
        }
        if ($Object -like "CAS") {
		    if ($OutputBoxCAS.Text.Length -eq 0) {
			    $OutputBoxCAS.Text = "$($Type)$($OutputBoxMessage)"
			    [System.Windows.Forms.Application]::DoEvents()
                $OutputBoxCAS.ScrollToCaret()
		    }
		    else {
			    $OutputBoxCAS.AppendText("`n$($Type)$($OutputBoxMessage)")
			    [System.Windows.Forms.Application]::DoEvents()
                $OutputBoxCAS.ScrollToCaret()
		    }
        }
        if ($Object -like "Primary") {
		    if ($OutputBoxPrimary.Text.Length -eq 0) {
			    $OutputBoxPrimary.Text = "$($Type)$($OutputBoxMessage)"
			    [System.Windows.Forms.Application]::DoEvents()
                $OutputBoxPrimary.ScrollToCaret()
		    }
		    else {
			    $OutputBoxPrimary.AppendText("`n$($Type)$($OutputBoxMessage)")
			    [System.Windows.Forms.Application]::DoEvents()
                $OutputBoxPrimary.ScrollToCaret()
		    }
        }
        if ($Object -like "Secondary") {
		    if ($OutputBoxSecondary.Text.Length -eq 0) {
			    $OutputBoxSecondary.Text = "$($Type)$($OutputBoxMessage)"
			    [System.Windows.Forms.Application]::DoEvents()
                $OutputBoxSecondary.ScrollToCaret()
		    }
		    else {
			    $OutputBoxSecondary.AppendText("`n$($Type)$($OutputBoxMessage)")
			    [System.Windows.Forms.Application]::DoEvents()
                $OutputBoxSecondary.ScrollToCaret()
		    }
        }
        if ($Object -like "SiteRoles") {
		    if ($OutputBoxSiteRoles.Text.Length -eq 0) {
			    $OutputBoxSiteRoles.Text = "$($Type)$($OutputBoxMessage)"
			    [System.Windows.Forms.Application]::DoEvents()
                $OutputBoxSiteRoles.ScrollToCaret()
		    }
		    else {
			    $OutputBoxSiteRoles.AppendText("`n$($Type)$($OutputBoxMessage)")
			    [System.Windows.Forms.Application]::DoEvents()
                $OutputBoxSiteRoles.ScrollToCaret()
		    }
        }
        if ($Object -like "Other") {
		    if ($OutputBoxOther.Text.Length -eq 0) {
			    $OutputBoxOther.Text = "$($Type)$($OutputBoxMessage)"
			    [System.Windows.Forms.Application]::DoEvents()
                $OutputBoxOther.ScrollToCaret()
		    }
		    else {
			    $OutputBoxOther.AppendText("`n$($Type)$($OutputBoxMessage)")
			    [System.Windows.Forms.Application]::DoEvents()
                $OutputBoxOther.ScrollToCaret()
		    }
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

# Assemblies
Add-Type -AssemblyName "System.Drawing"
Add-Type -AssemblyName "System.Windows.Forms"
Add-Type -AssemblyName "System.DirectoryServices"

# Variables
$Global:SMCSharedData = 0

# Form
$Form = New-Object System.Windows.Forms.Form    
$Form.Size = New-Object System.Drawing.Size(805,530)  
$Form.MinimumSize = New-Object System.Drawing.Size(805,530)
$Form.MaximumSize = New-Object System.Drawing.Size(805,530)
$Form.SizeGripStyle = "Hide"
$Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHome + "\powershell.exe")
$Form.Text = "ConfigMgr Prerequisites Tool 1.4.0"
$FormSMCSearch = New-Object System.Windows.Forms.Form    
$FormSMCSearch.Size = New-Object System.Drawing.Size(505,480)  
$FormSMCSearch.MinimumSize = New-Object System.Drawing.Size(505,480)
$FormSMCSearch.MaximumSize = New-Object System.Drawing.Size(505,480)
$FormSMCSearch.SizeGripStyle = "Hide"
$FormSMCSearch.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHome + "\powershell.exe")
$FormSMCSearch.Text = "Search for an Active Directory group"

# Base64
$ValidatedBase64String = "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAACcUlEQVQ4jZVR30tTcRw99/u9P5x36s1fA5d1lZWYpTdfCtRtiQmbmflWgTF78qnsL7D9BfPFBymSwEgjKE3QCKYPRmWml0TIDF1mc0NzVzc3NnW3hzBERul5/HDO+ZzP+TA4CrohE4Z08JSXBcr7eMrdY48glghDRq/JTtksFmB5y4+Pa1MyOayeMrT9krlGtpmrYUwzwH68Bpl8uv1QCbgHrCJyYodTrsf32AIAQGeSAAgOlYAlrOdW6XXwHIuoHkFZdjk+rargCNf5X4P0RwZXaXaJvdKk4GdiCeXZlQhEg5j5NeujhLr/nNAFBQQKGKhog7onzugxSoQhHlfZTYSTGnINeRA5I57NvQBL2NbJJlUj6ILHIhVNO07W9eSkHZtGNzz7ivM0WZxSrpiDLYRRnHEK71cmEN2Jdk42qWMAwIJB++2yFhg4AZflWvTO9bfPPvwiiZzhcX56nuuqpQGBnWVYMkrgj6xgKqj6KEPde0sIGMDIi1hLrGJzN4Q759tgL6xyUUJHW8+1YIckIPIiOMJj6NswKKHN7xontb8p0QgplNAu2s1WxPUY4noMtkIbiiUZFaaz2MA6ThiK4PWNYUHzud9emejbXzLFEF77awPy5vamYjNbEUcca7tBVORUIIwN5KeZ4A8HMPR1WB1v+HDj4JcoAOiv9IFQvSZHtiNKdUEVCGWwmgwik8+CgYjo/fwU28mEw/fkRyClAQDEXyYGYo6YPB+aV6zmGmQJmcgTTPAujmFBW3R7HeN9B8Upceb56R7nmzp9cL1f717q1OtGrNP/4jOphhcGK+8LVLgrUF6jhDaP1HvVVDwA+A0rr9F+/wY4EQAAAABJRU5ErkJggg=="
$ValidatedImageBytes = [Convert]::FromBase64String($ValidatedBase64String)
$ValidatedMemoryStream = New-Object -TypeName IO.MemoryStream($ValidatedImageBytes, 0, $ValidatedImageBytes.Length)
$ValidatedMemoryStream.Write($ValidatedImageBytes, 0, $ValidatedImageBytes.Length)
$ValidatedImage = [System.Drawing.Image]::FromStream($ValidatedMemoryStream, $true)
$NonValidatedBase64String = "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAACpElEQVR4nHWTTU8TQRzGn5n/rNtXuxVoWbSmJcYXwGQuFBNP+w0w8AEkPXHDT4LfoF7lAL6QXiDZIF4IlyXeCVEogqFu6Yvbmtnx4LIRo//jJL/fMzPPDEM0Xq22OvT9cvPjx6X5szMf/5gN27bsubm6Gg6PnjYaLwCAA8Cn5eV6YXZ2hTM2nxoddd+Mj1v/gV3r3r153WqtbD16VAcA5tVqq4XZ2ZXm1haGrRa0Uuien3v9dtt5dnrqA8D6xIRlV6tufnJSXuzuQisFAOj3ei/F0PfLze3tGIZSSOfzEmHorgMOGINdrbr5SkVe7OwASoFFuwqVKrO3xaKVHB110yMjEkpBhyGgFBCG6LbbXm5qCrcqFXnx4cPvda3BAFz2+16333cYALwZH7eSluWm83l5BbMwBMIQt548gb+3FyczreH3+143CJyFkxOf/XlJqWzWTd+8Ka9gpjX0YAAdBGBRclcI7zIInMWTEx9AfBwAwLptW6lMxs0kk1J9/w7VboMD4JyDiNAxDK8rhLN4fBzXLK51xRiylQpSponW4SEoAokIxDk4EfRf9fI/0wszM27asuTFzk6cSkQQRBBCoEgkRzh310ol65pgI4IzuZz81miAhyE4Y7FECAHDMGAIgdumKYuGEUvYhm1bY1HyeaMBrnWc2DNNj4hQIJJXAkMIEBE+B4F3HASOGJuerqdyOfl1cxNcazAiMMbQNQyvJ4SjARBj7p1IciMSPUgkJO906uJnp3N0urt7De6ZpvfDMOLbXiuVHKGUO0kkb0QSzjmSQXDEAOBdNls3BoPnRIRhOu0NTNNZiHq+mrVSybqTSrkP83mZTCTwpdd7dX9/fyl+B+9zuVUQlYeJxNJCs/nP7/z67l2rnMnUU4Zx9Pjg4AUA/ALA8B6CbeY2WQAAAABJRU5ErkJggg=="
$NonValidatedImageBytes = [Convert]::FromBase64String($NonValidatedBase64String)
$NonValidatedMemoryStream = New-Object -TypeName IO.MemoryStream($NonValidatedImageBytes, 0, $NonValidatedImageBytes.Length)
$NonValidatedMemoryStream.Write($NonValidatedImageBytes, 0, $NonValidatedImageBytes.Length)
$NonValidatedImage = [System.Drawing.Image]::FromStream($NonValidatedMemoryStream, $true)

# PictureBoxes
$PBReboot = New-Object -TypeName System.Windows.Forms.PictureBox
$PBReboot.Location = New-Object -TypeName System.Drawing.Size(203,50)
$PBReboot.Size = New-Object -TypeName System.Drawing.Size(16,16)
$PBOS = New-Object -TypeName System.Windows.Forms.PictureBox
$PBOS.Location = New-Object -TypeName System.Drawing.Size(203,90)
$PBOS.Size = New-Object -TypeName System.Drawing.Size(16,16)
$PBPS = New-Object -TypeName System.Windows.Forms.PictureBox
$PBPS.Location = New-Object -TypeName System.Drawing.Size(203,130)
$PBPS.Size = New-Object -TypeName System.Drawing.Size(16,16)
$PBElevated = New-Object -TypeName System.Windows.Forms.PictureBox
$PBElevated.Location = New-Object -TypeName System.Drawing.Size(203,170)
$PBElevated.Size = New-Object -TypeName System.Drawing.Size(16,16)

# ListBoxes
$LBVersions = New-Object -TypeName System.Windows.Forms.ListBox
$LBVersions.Location = New-Object -TypeName System.Drawing.Size(30,275)
$LBVersions.Size = New-Object -TypeName System.Drawing.Size(200,80)
$LBVersions.SelectionMode = "None"
$LBVersions.Items.AddRange(@("ConfigMgr 2012","ConfigMgr 2012 R2","ConfigMgr vNext"))

# TabPages
$TabPageGeneral = New-Object System.Windows.Forms.TabPage
$TabPageGeneral.Location = New-Object System.Drawing.Size(10,50)
$TabPageGeneral.Size = New-Object System.Drawing.Size(300,300)
$TabPageGeneral.Text = "General"
$TabPageGeneral.Name = "General"
$TabPageGeneral.Padding = "0,0,0,0"
$TabPageGeneral.BackColor = "Control"
$TabPageCAS = New-Object System.Windows.Forms.TabPage
$TabPageCAS.Location = New-Object System.Drawing.Size(10,50)
$TabPageCAS.Size = New-Object System.Drawing.Size(300,300)
$TabPageCAS.Text = "Central Administration Site"
$TabPageCAS.Name = "Central Administration Site"
$TabPageCAS.Padding = "0,0,0,0"
$TabPageCAS.BackColor = "Control"
$TabPagePrimary = New-Object System.Windows.Forms.TabPage
$TabPagePrimary.Location = New-Object System.Drawing.Size(10,50)
$TabPagePrimary.Size = New-Object System.Drawing.Size(300,300)
$TabPagePrimary.Text = "Primary Site"
$TabPagePrimary.Name = "Primary Site"
$TabPagePrimary.Padding = "0,0,0,0"
$TabPagePrimary.BackColor = "Control"
$TabPageSecondary = New-Object System.Windows.Forms.TabPage
$TabPageSecondary.Location = New-Object System.Drawing.Size(10,50)
$TabPageSecondary.Size = New-Object System.Drawing.Size(300,300)
$TabPageSecondary.Text = "Secondary Site"
$TabPageSecondary.Name = "Secondary Site"
$TabPageSecondary.Padding = "0,0,0,0"
$TabPageSecondary.BackColor = "Control"
$TabPageSiteRoles = New-Object System.Windows.Forms.TabPage
$TabPageSiteRoles.Location = New-Object System.Drawing.Size(10,50)
$TabPageSiteRoles.Size = New-Object System.Drawing.Size(300,300)
$TabPageSiteRoles.Text = "Site System Roles"
$TabPageSiteRoles.Name = "Site System Roles"
$TabPageSiteRoles.Padding = "0,0,0,0"
$TabPageSiteRoles.BackColor = "Control"
$TabPageOther = New-Object System.Windows.Forms.TabPage
$TabPageOther.Location = New-Object System.Drawing.Size(10,50)
$TabPageOther.Size = New-Object System.Drawing.Size(300,300)
$TabPageOther.Text = "Other"
$TabPageOther.Name = "Other"
$TabPageOther.Padding = "0,0,0,0"
$TabPageOther.BackColor = "Control"
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
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = New-Object System.Drawing.Size(0,0)
$TabControl.Size = New-Object System.Drawing.Size(805,530)
$TabControl.Anchor = "Top, Bottom, Left, Right"
$TabControl.Name = "Global"
$TabControl.SelectedIndex = 0
$TabControl.Add_Selected([System.Windows.Forms.TabControlEventHandler]{
    if ($TabControl.SelectedTab.Name -like "Central Administration Site") {
        Load-CAS
        if ($TabControl.SelectedTab.Enabled -eq $true) {
            if (-not($OutputBoxCAS.Text.Length -ge 1)) {
                $OutputBoxCAS.ResetText()
                Write-OutputBox -OutputBoxMessage "Click on the Install button to install the required Windows Features for a Central Administration Site. Additionally you can choose to also download the prerequisite files" -Type "INFO: " -Object CAS
            }
        }
    }
    if ($TabControl.SelectedTab.Name -like "Primary Site") {
        Load-Primary
        if ($TabControl.SelectedTab.Enabled -eq $true) {
            if (-not($OutputBoxPrimary.Text.Length -ge 1)) {
                $OutputBoxPrimary.ResetText()
                Write-OutputBox -OutputBoxMessage "Click on the Install button to install the required Windows Features for a Primary Site. Additionally you can choose to also download the prerequisite files" -Type "INFO: " -Object Primary
            }
        }
    }
    if ($TabControl.SelectedTab.Name -like "Secondary Site") {
        Load-Secondary
        if ($TabControl.SelectedTab.Enabled -eq $true) {
            if (-not($OutputBoxSecondary.Text.Length -ge 1)) {
                $OutputBoxSecondary.ResetText()
                Write-OutputBox -OutputBoxMessage "Click on the Install button to install the required Windows Features for a Secondary Site" -Type "INFO: " -Object Secondary
            }
        }
    }
    if ($TabControl.SelectedTab.Name -like "Site System Roles") {
        Load-SiteSystemRoles
        if ($TabControl.SelectedTab.Enabled -eq $true) {
            if (-not($OutputBoxSiteRoles.Text.Length -ge 1)) {
                $OutputBoxSiteRoles.ResetText()
                Write-OutputBox -OutputBoxMessage "Make a selection from the options on the left to begin" -Type "INFO: " -Object SiteRoles
            }
        }
    }
    if ($TabControl.SelectedTab.Name -like "Other") {
        Load-Other
        if ($TabControl.SelectedTab.Enabled -eq $true) {
            if (-not($OutputBoxOther.Text.Length -ge 1)) {
                $OutputBoxOther.ResetText()
                Write-OutputBox -OutputBoxMessage "Make a selection from the options on the left to begin" -Type "INFO: " -Object Other
            }
        }
    }
})
$TabControlSMC = New-Object System.Windows.Forms.TabControl
$TabControlSMC.Location = New-Object System.Drawing.Size(0,0)
$TabControlSMC.Size = New-Object System.Drawing.Size(800,500)
$TabControlSMC.Anchor = "Top, Bottom, Left, Right"
$TabControlSMC.Name = "TabControl"
$TabControlSMC.SelectedIndex = 0
$TabControlSMC.Add_Selected([System.Windows.Forms.TabControlEventHandler]{
    if ($TabControlSMC.SelectedTab.Name -like "Group") {
        $OutputBox.ResetText()
        if ($OutputBox.Location.Y -eq 10) {
            $OutputBox.Location = New-Object System.Drawing.Size(380,65)
            $OutputBox.Size = New-Object System.Drawing.Size(393,296)
        }
        $TabPageSMCGroup.Controls.Add($OutputBox)
    }
})
$TabControlSMC.Add_Selected([System.Windows.Forms.TabControlEventHandler]{
    if ($TabControlSMC.SelectedTab.Name -like "Computer") {
        $OutputBox.ResetText()
        if ($OutputBox.ControlAdded) {
            $TabPageSMCGroup.Controls.Remove($OutputBox)
        }
        $OutputBox.Location = New-Object System.Drawing.Size(10,10)
        $OutputBox.Size = New-Object System.Drawing.Size(763,350)
        $TabPageSMCComputer.Controls.Add($OutputBox)
    }
})

# ProgressBars
$ProgressBarCAS = New-Object System.Windows.Forms.ProgressBar
$ProgressBarCAS.Location = New-Object System.Drawing.Size(10,375)
$ProgressBarCAS.Size = New-Object System.Drawing.Size(763,30)
$ProgressBarCAS.Step = 1
$ProgressBarCAS.Value = 0
$ProgressBarPrimary = New-Object System.Windows.Forms.ProgressBar
$ProgressBarPrimary.Location = New-Object System.Drawing.Size(10,375)
$ProgressBarPrimary.Size = New-Object System.Drawing.Size(763,30)
$ProgressBarPrimary.Step = 1
$ProgressBarPrimary.Value = 0
$ProgressBarSecondary = New-Object System.Windows.Forms.ProgressBar
$ProgressBarSecondary.Location = New-Object System.Drawing.Size(10,375)
$ProgressBarSecondary.Size = New-Object System.Drawing.Size(763,30)
$ProgressBarSecondary.Step = 1
$ProgressBarSecondary.Value = 0
$ProgressBarSiteRoles = New-Object System.Windows.Forms.ProgressBar
$ProgressBarSiteRoles.Location = New-Object System.Drawing.Size(10,375)
$ProgressBarSiteRoles.Size = New-Object System.Drawing.Size(763,30)
$ProgressBarSiteRoles.Step = 1
$ProgressBarSiteRoles.Value = 0
$ProgressBarOther = New-Object System.Windows.Forms.ProgressBar
$ProgressBarOther.Location = New-Object System.Drawing.Size(10,375)
$ProgressBarOther.Size = New-Object System.Drawing.Size(763,30)
$ProgressBarOther.Step = 1
$ProgressBarOther.Value = 0

# OutputBoxes
$OutputBoxGeneral = New-Object System.Windows.Forms.RichTextBox 
$OutputBoxGeneral.Location = New-Object System.Drawing.Size(260,60) 
$OutputBoxGeneral.Size = New-Object System.Drawing.Size(500,365)
$OutputBoxGeneral.Font = "Courier New"
$OutputBoxGeneral.BackColor = "white"
$OutputBoxGeneral.ReadOnly = $true
$OutputBoxGeneral.MultiLine = $True
$OutputBoxCAS = New-Object System.Windows.Forms.RichTextBox 
$OutputBoxCAS.Location = New-Object System.Drawing.Size(10,10) 
$OutputBoxCAS.Size = New-Object System.Drawing.Size(763,350)
$OutputBoxCAS.Font = "Courier New"
$OutputBoxCAS.BackColor = "white"
$OutputBoxCAS.ReadOnly = $true
$OutputBoxCAS.MultiLine = $True
$OutputBoxPrimary = New-Object System.Windows.Forms.RichTextBox 
$OutputBoxPrimary.Location = New-Object System.Drawing.Size(10,10) 
$OutputBoxPrimary.Size = New-Object System.Drawing.Size(763,350)
$OutputBoxPrimary.Font = "Courier New"
$OutputBoxPrimary.BackColor = "white"
$OutputBoxPrimary.ReadOnly = $true
$OutputBoxPrimary.MultiLine = $True
$OutputBoxSecondary = New-Object System.Windows.Forms.RichTextBox 
$OutputBoxSecondary.Location = New-Object System.Drawing.Size(10,10) 
$OutputBoxSecondary.Size = New-Object System.Drawing.Size(763,350)
$OutputBoxSecondary.Font = "Courier New"
$OutputBoxSecondary.BackColor = "white"
$OutputBoxSecondary.ReadOnly = $true
$OutputBoxSecondary.MultiLine = $True
$OutputBoxSiteRoles = New-Object System.Windows.Forms.RichTextBox 
$OutputBoxSiteRoles.Location = New-Object System.Drawing.Size(210,10) 
$OutputBoxSiteRoles.Size = New-Object System.Drawing.Size(563,350)
$OutputBoxSiteRoles.Font = "Courier New"
$OutputBoxSiteRoles.BackColor = "white"
$OutputBoxSiteRoles.ReadOnly = $true
$OutputBoxSiteRoles.MultiLine = $True
$OutputBoxOther = New-Object System.Windows.Forms.RichTextBox 
$OutputBoxOther.Location = New-Object System.Drawing.Size(220,10) 
$OutputBoxOther.Size = New-Object System.Drawing.Size(553,350)
$OutputBoxOther.Font = "Courier New"
$OutputBoxOther.BackColor = "white"
$OutputBoxOther.ReadOnly = $true
$OutputBoxOther.MultiLine = $True

# DataGriViews
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
$DGVSMCGroup.RowHeadersVisible = $false
$DGVSMCGroup.Add_CellContentClick({
    $DGVSMCResult = $DGVSMCGroup.CurrentCell.Value
    $TextBoxSMCGroupResult.Text = $DGVSMCResult
    $ButtonSMCOK.Enabled = $true
})

# Textboxes
$TextBoxDC = New-Object System.Windows.Forms.TextBox
$TextBoxDC.Location = New-Object System.Drawing.Size(20,428) 
$TextBoxDC.Size = New-Object System.Drawing.Size(170,20)
$TextBoxDC.TabIndex = "0"
$TextBoxDC.Name = "EAD"
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
        Write-OutputBox -OutputBoxMessage "Searching Active Directory for '$($TextBoxSMCGroupSearch.Text)'" -Type "INFO: " -Object Other
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
$TextBoxWSUSSQLServer.Name = "WSUS"
$TextBoxWSUSSQLInstance = New-Object System.Windows.Forms.TextBox
$TextBoxWSUSSQLInstance.Location = New-Object System.Drawing.Size(310,428)
$TextBoxWSUSSQLInstance.Size = New-Object System.Drawing.Size(140,20)
$TextBoxWSUSSQLInstance.TabIndex = "0"
$TextBoxWSUSSQLInstance.Text = $env:COMPUTERNAME
$TextBoxWSUSSQLInstance.Enabled = $false
$TextBoxWSUSSQLInstance.Name = "WSUS"
$TextBoxSiteSystemRolesMP = New-Object System.Windows.Forms.TextBox
$TextBoxSiteSystemRolesMP.Location = New-Object System.Drawing.Size(17,428) 
$TextBoxSiteSystemRolesMP.Size = New-Object System.Drawing.Size(195,20)
$TextBoxSiteSystemRolesMP.TabIndex = "0"
$TextBoxSiteSystemRolesMP.Name = "MP"
$TextBoxSiteSystemRolesDP = New-Object System.Windows.Forms.TextBox
$TextBoxSiteSystemRolesDP.Location = New-Object System.Drawing.Size(17,428) 
$TextBoxSiteSystemRolesDP.Size = New-Object System.Drawing.Size(195,20)
$TextBoxSiteSystemRolesDP.TabIndex = "0"
$TextBoxSiteSystemRolesDP.Name = "DP"
$TextBoxSiteSystemRolesAppCat = New-Object System.Windows.Forms.TextBox
$TextBoxSiteSystemRolesAppCat.Location = New-Object System.Drawing.Size(17,428) 
$TextBoxSiteSystemRolesAppCat.Size = New-Object System.Drawing.Size(195,20)
$TextBoxSiteSystemRolesAppCat.TabIndex = "0"
$TextBoxSiteSystemRolesAppCat.Name = "AppCat"
$TextBoxSiteSystemRolesEP = New-Object System.Windows.Forms.TextBox
$TextBoxSiteSystemRolesEP.Location = New-Object System.Drawing.Size(197,428) 
$TextBoxSiteSystemRolesEP.Size = New-Object System.Drawing.Size(195,20)
$TextBoxSiteSystemRolesEP.TabIndex = "0"
$TextBoxSiteSystemRolesEP.Name = "EP"
$TextBoxSiteSystemRolesSMP = New-Object System.Windows.Forms.TextBox
$TextBoxSiteSystemRolesSMP.Location = New-Object System.Drawing.Size(17,428) 
$TextBoxSiteSystemRolesSMP.Size = New-Object System.Drawing.Size(195,20)
$TextBoxSiteSystemRolesSMP.TabIndex = "0"
$TextBoxSiteSystemRolesSMP.Name = "SMP"

# Buttons
$ButtonInstallCAS = New-Object System.Windows.Forms.Button 
$ButtonInstallCAS.Location = New-Object System.Drawing.Size(673,420) 
$ButtonInstallCAS.Size = New-Object System.Drawing.Size(100,30) 
$ButtonInstallCAS.Text = "Install"
$ButtonInstallCAS.TabIndex = "1"
$ButtonInstallCAS.Add_Click({Install-CAS})
$ButtonInstallPrimarySite = New-Object System.Windows.Forms.Button 
$ButtonInstallPrimarySite.Location = New-Object System.Drawing.Size(673,420)
$ButtonInstallPrimarySite.Size = New-Object System.Drawing.Size(100,30) 
$ButtonInstallPrimarySite.Text = "Install"
$ButtonInstallPrimarySite.TabIndex = "1"
$ButtonInstallPrimarySite.Add_Click({Install-Primary})
$ButtonInstallSecondarySite = New-Object System.Windows.Forms.Button 
$ButtonInstallSecondarySite.Location = New-Object System.Drawing.Size(673,420)
$ButtonInstallSecondarySite.Size = New-Object System.Drawing.Size(100,30) 
$ButtonInstallSecondarySite.Text = "Install"
$ButtonInstallSecondarySite.TabIndex = "1"
$ButtonInstallSecondarySite.Add_Click({Install-Secondary})
$ButtonInstallSiteRoles = New-Object System.Windows.Forms.Button 
$ButtonInstallSiteRoles.Location = New-Object System.Drawing.Size(673,420) 
$ButtonInstallSiteRoles.Size = New-Object System.Drawing.Size(100,30) 
$ButtonInstallSiteRoles.Text = "Install"
$ButtonInstallSiteRoles.TabIndex = "1"
$ButtonInstallSiteRoles.Add_Click({
    if ($RadioButtonSiteRoleMP.Checked -eq $true) {
        if ($TextBoxSiteSystemRolesMP.Text.Length -ge 1) {
            if ($TextBoxSiteSystemRolesMP.Text.Length -gt 2) {
                Write-OutputBox -OutputBoxMessage "Site Server '$($TextBoxSiteSystemRolesMP.Text)' was specified to be added to local Administrators group" -Type "INFO: " -Object SiteRoles
                Add-SiteServerLocalAdministrators -ComputerName $TextBoxSiteSystemRolesMP.Text
                Write-OutputBox -OutputBoxMessage "Begin installing prerequisites for a Management Point role" -Type "INFO: " -Object SiteRoles
                Install-MP
            }
            else {
                Write-OutputBox -OutputBoxMessage "Specified Site Server name '$($TextBoxSiteSystemRolesMP.Text)' does not meet the minimum requirements of 3 valid characters" -Type "WARNING: " -Object SiteRoles
            }
        }
        else {
            Write-OutputBox -OutputBoxMessage "Begin installing prerequisites for a Management Point role" -Type "INFO: " -Object SiteRoles
            Install-MP
        }
    }
    elseif ($RadioButtonSiteRoleDP.Checked -eq $true) {
        if ($TextBoxSiteSystemRolesDP.Text.Length -ge 1) {
            if ($TextBoxSiteSystemRolesDP.Text.Length -gt 2) {
                Write-OutputBox -OutputBoxMessage "Site Server '$($TextBoxSiteSystemRolesDP.Text)' was specified to be added to local Administrators group" -Type "INFO: " -Object SiteRoles
                Add-SiteServerLocalAdministrators -ComputerName $TextBoxSiteSystemRolesDP.Text
                Write-OutputBox -OutputBoxMessage "Begin installing prerequisites for a Distribution Point role" -Type "INFO: " -Object SiteRoles
                Install-DP
            }
            else {
                Write-OutputBox -OutputBoxMessage "Specified Site Server name '$($TextBoxSiteSystemRolesDP.Text)' does not meet the minimum requirements of 3 valid characters" -Type "WARNING: " -Object SiteRoles
            }
        }
        else {
            Write-OutputBox -OutputBoxMessage "Begin installing prerequisites for a Distribution Point role" -Type "INFO: " -Object SiteRoles
            Install-DP
        }
    }
    elseif ($RadioButtonSiteRoleAppCat.Checked -eq $true) {
        if ($TextBoxSiteSystemRolesAppCat.Text.Length -ge 1) {
            if ($TextBoxSiteSystemRolesAppCat.Text.Length -gt 2) {
                Write-OutputBox -OutputBoxMessage "Site Server '$($TextBoxSiteSystemRolesAppCat.Text)' was specified to be added to local Administrators group" -Type "INFO: " -Object SiteRoles
                Add-SiteServerLocalAdministrators -ComputerName $TextBoxSiteSystemRolesAppCat.Text
                Write-OutputBox -OutputBoxMessage "Begin installing prerequisites for a Application Catalog role" -Type "INFO: " -Object SiteRoles
                Install-AppCat
            }
            else {
                Write-OutputBox -OutputBoxMessage "Specified Site Server name '$($TextBoxSiteSystemRolesAppCat.Text)' does not meet the minimum requirements of 3 valid characters" -Type "WARNING: " -Object SiteRoles
            }
        }
        else {
            Write-OutputBox -OutputBoxMessage "Begin installing prerequisites for a Application Catalog role" -Type "INFO: " -Object SiteRoles
            Install-AppCat
        }
    }
    elseif ($RadioButtonSiteRoleEP.Checked -eq $true) {
        if ($TextBoxSiteSystemRolesEP.Text.Length -ge 1) {
            if ($TextBoxSiteSystemRolesEP.Text.Length -gt 2) {
                Write-OutputBox -OutputBoxMessage "Site Server '$($TextBoxSiteSystemRolesEP.Text)' was specified to be added to local Administrators group" -Type "INFO: " -Object SiteRoles
                Add-SiteServerLocalAdministrators -ComputerName $TextBoxSiteSystemRolesEP.Text
                if (($ComboBoxSiteRolesEP.Text -eq "Enrollment Point") -or ($ComboBoxSiteRolesEP.Text -eq "Enrollment Proxy Point")) {
                    Write-OutputBox -OutputBoxMessage "Begin installing prerequisites for a $($ComboBoxSiteRolesEP.Text) role" -Type "INFO: " -Object SiteRoles
                    Install-EP
                }
                else {
                    Write-OutputBox -OutputBoxMessage "Please select an Enrollment Point role" -Type "INFO: " -Object SiteRoles
                }
            }
            else {
                Write-OutputBox -OutputBoxMessage "Specified Site Server name '$($TextBoxSiteSystemRolesEP.Text)' does not meet the minimum requirements of 3 valid characters" -Type "WARNING: " -Object SiteRoles
            }
        }
        else {
            if (($ComboBoxSiteRolesEP.Text -eq "Enrollment Point") -or ($ComboBoxSiteRolesEP.Text -eq "Enrollment Proxy Point")) {
                Write-OutputBox -OutputBoxMessage "Begin installing prerequisites for a $($ComboBoxSiteRolesEP.Text) role" -Type "INFO: " -Object SiteRoles
                Install-EP
            }
            else {
                Write-OutputBox -OutputBoxMessage "Please select an Enrollment Point role" -Type "INFO: " -Object SiteRoles
            }
        }
    }
    elseif ($RadioButtonSiteRoleSMP.Checked -eq $true) {
        if ($TextBoxSiteSystemRolesSMP.Text.Length -ge 1) {
            if ($TextBoxSiteSystemRolesSMP.Text.Length -gt 2) {
                Write-OutputBox -OutputBoxMessage "Site Server '$($TextBoxSiteSystemRolesSMP.Text)' was specified to be added to local Administrators group" -Type "INFO: " -Object SiteRoles
                Add-SiteServerLocalAdministrators -ComputerName $TextBoxSiteSystemRolesSMP.Text
                Write-OutputBox -OutputBoxMessage "Begin installing prerequisites for a State Migration Point role" -Type "INFO: " -Object SiteRoles
                Install-SMP
            }
            else {
                Write-OutputBox -OutputBoxMessage "Specified Site Server name '$($TextBoxSiteSystemRolesDP.Text)' does not meet the minimum requirements of 3 valid characters" -Type "WARNING: " -Object SiteRoles
            }
        }
        else {
            Write-OutputBox -OutputBoxMessage "Begin installing prerequisites for a State Migration Point role" -Type "INFO: " -Object SiteRoles
            Install-SMP
        }
    }
    else {
        Write-OutputBox -OutputBoxMessage "Please select a Site System role to install" -Type "INFO: " -Object SiteRoles
    }
})
$ButtonInstallOther = New-Object System.Windows.Forms.Button 
$ButtonInstallOther.Location = New-Object System.Drawing.Size(673,420) 
$ButtonInstallOther.Size = New-Object System.Drawing.Size(100,30) 
$ButtonInstallOther.Text = "Install"
$ButtonInstallOther.TabIndex = "1"
$ButtonInstallOther.Add_Click({
    if (($RadioButtonOtherEAD.Checked -eq $true) -or ($RadioButtonOtherWSUS.Checked -eq $true) -or ($RadioButtonOtherADK.Checked -eq $true) -or ($RadioButtonOtherSMC.Checked -eq $true)) {
        if ($RadioButtonOtherEAD.Checked -eq $true) {
            Write-OutputBox -OutputBoxMessage "Begin validation checks for extending Active Directory" -Type "INFO: " -Object Other
            Extend-ActiveDirectorySchema
        }
        if ($RadioButtonOtherWSUS.Checked -eq $true) {
            if (($ComboBoxOtherWSUS.Text -eq "SQL") -or ($ComboBoxOtherWSUS.Text -eq "WID")) {
                Write-OutputBox -OutputBoxMessage "Preparing to install WSUS features configured for $($ComboBoxOtherWSUS.Text)" -Type "INFO: " -Object Other
                Install-WSUS
            }
            else {
                Write-OutputBox -OutputBoxMessage "Please select where to install the WSUS database" -Type "INFO: " -Object Other
            }
        }
        if ($RadioButtonOtherADK.Checked -eq $true) {
            if (($ComboBoxOtherADK.Text -eq "Online") -or ($ComboBoxOtherADK.Text -eq "Offline")) {
                Write-OutputBox -OutputBoxMessage "Preparing for an $(($ComboBoxOtherADK.Text).ToLower()) installation of Windows ADK" -Type "INFO: " -Object Other
                Install-ADK
            }
            else {
                Write-OutputBox -OutputBoxMessage "Please select an installation option" -Type "INFO: " -Object Other
            }
        }
        if ($RadioButtonOtherSMC.Checked -eq $true) {
            Search-SMC
        }
    }
    elseif ($RadioButtonOtherNoSMS.Checked -eq $true) {
        Create-NoSMSOnDrive
    }
    else {
        Write-OutputBox -OutputBoxMessage "Nothing has been selected, please make a selection first" -Type "INFO: " -Object Other
    }
})
$ButtonSystemManagementContainerGroupSearch = New-Object System.Windows.Forms.Button 
$ButtonSystemManagementContainerGroupSearch.Location = New-Object System.Drawing.Size(380,20) 
$ButtonSystemManagementContainerGroupSearch.Size = New-Object System.Drawing.Size(100,30) 
$ButtonSystemManagementContainerGroupSearch.Text = "Search"
$ButtonSystemManagementContainerGroupSearch.TabIndex = "1"
$ButtonSystemManagementContainerGroupSearch.Add_Click({
    Search-ADGroup
})
$ButtonSMCOK = New-Object System.Windows.Forms.Button 
$ButtonSMCOK.Location = New-Object System.Drawing.Size(380,385) 
$ButtonSMCOK.Size = New-Object System.Drawing.Size(100,30) 
$ButtonSMCOK.Text = "OK"
$ButtonSMCOK.TabIndex = "1"
$ButtonSMCOK.Enabled = $false
$ButtonSMCOK.Add_Click({
    $Global:SMCSharedData = $TextBoxSMCGroupResult.Text
    Write-OutputBox -OutputBoxMessage "Selected Active Directory group: $($Global:SMCSharedData)" -Type "INFO: " -Object Other
    $FormSMCSearch.Close()
    Configure-SystemManagementContainer
})

# WaterMarks
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
$TextBoxWSUSSQLServer.Name = "WSUS"
$WaterMarkWSUSSQLInstance = "Enter SQL Server instance"
$TextBoxWSUSSQLInstance.ForeColor = "LightGray"
$TextBoxWSUSSQLInstance.Text = $WaterMarkWSUSSQLInstance
$TextBoxWSUSSQLInstance.add_Enter({Enter-WaterMark -InputObject $TextBoxWSUSSQLInstance -Text $WaterMarkWSUSSQLInstance})
$TextBoxWSUSSQLInstance.add_Leave({Leave-WaterMark -InputObject $TextBoxWSUSSQLInstance -Text $WaterMarkWSUSSQLInstance})
$TextBoxWSUSSQLInstance.Name = "WSUS"

# Labels
$LabelHeader = New-Object System.Windows.Forms.Label
$LabelHeader.Location = New-Object System.Drawing.Size(257,23)
$LabelHeader.Size = New-Object System.Drawing.Size(500,30)
$LabelHeader.Text = "Install ConfigMgr Prerequisites"
$LabelHeader.Font = New-Object System.Drawing.Font("Verdana",12,[System.Drawing.FontStyle]::Bold)
$LabelGeneralRestart = New-Object System.Windows.Forms.Label
$LabelGeneralRestart.Size = New-Object System.Drawing.Size(150,15)
$LabelGeneralRestart.Location = New-Object System.Drawing.Size(38,52)
$LabelGeneralRestart.Font = New-Object System.Drawing.Font("Microsoft Sans Serif","8.25",[System.Drawing.FontStyle]::Bold)
$LabelGeneralRestart.Text = "Reboot required"
$LabelGeneralOS = New-Object System.Windows.Forms.Label
$LabelGeneralOS.Size = New-Object System.Drawing.Size(160,15)
$LabelGeneralOS.Location = New-Object System.Drawing.Size(38,92)
$LabelGeneralOS.Font = New-Object System.Drawing.Font("Microsoft Sans Serif","8.25",[System.Drawing.FontStyle]::Bold)
$LabelGeneralOS.Text = "Supported platform"
$LabelGeneralPS = New-Object System.Windows.Forms.Label
$LabelGeneralPS.Size = New-Object System.Drawing.Size(160,15)
$LabelGeneralPS.Location = New-Object System.Drawing.Size(38,132)
$LabelGeneralPS.Font = New-Object System.Drawing.Font("Microsoft Sans Serif","8.25",[System.Drawing.FontStyle]::Bold)
$LabelGeneralPS.Text = "PowerShell version"
$LabelGeneralElevated = New-Object System.Windows.Forms.Label
$LabelGeneralElevated.Size = New-Object System.Drawing.Size(160,15)
$LabelGeneralElevated.Location = New-Object System.Drawing.Size(38,172)
$LabelGeneralElevated.Font = New-Object System.Drawing.Font("Microsoft Sans Serif","8.25",[System.Drawing.FontStyle]::Bold)
$LabelGeneralElevated.Text = "Elevated launch"
$LabelSMCCreate = New-Object System.Windows.Forms.Label
$LabelSMCCreate.Location = New-Object System.Drawing.Size(418,395)
$LabelSMCCreate.Size = New-Object System.Drawing.Size(150,20)
$LabelSMCCreate.Text = "Create the container"

# Links
$OpenLink = {[System.Diagnostics.Process]::Start("http://www.scconfigmgr.com")}
$BlogLink = New-Object System.Windows.Forms.LinkLabel
$BlogLink.Location = New-Object System.Drawing.Size(20,440) 
$BlogLink.Size = New-Object System.Drawing.Size(150,25)
$BlogLink.Text = "www.scconfigmgr.com"
$BlogLink.Add_Click($OpenLink)

# RadioButtons
$RadioButtonSiteRoleMP = New-Object System.Windows.Forms.RadioButton
$RadioButtonSiteRoleMP.Location = New-Object System.Drawing.Size(25,35)
$RadioButtonSiteRoleMP.Size = New-Object System.Drawing.Size(120,25)
$RadioButtonSiteRoleMP.Text = "Management Point"
$RadioButtonSiteRoleMP.Name = "Option Management Point"
$RadioButtonSiteRoleMP.Checked = $false
$RadioButtonSiteRoleMP.Add_Click({
    if ($RadioButtonSiteRoleMP.Checked -eq $true) {
        $OutputBoxSiteRoles.ResetText()
    }
    $OutputBoxSiteRoles.ResetText()
    $ProgressBarSiteRoles.Value = 0
    Write-OutputBox -OutputBoxMessage "Management Point selections loaded" -Type "INFO: " -Object SiteRoles
    Write-OutputBox -OutputBoxMessage "Click on the Install button to install the required Windows Features for a Management Point site system role" -Type "INFO: " -Object SiteRoles
    Interactive-SiteRolesControlVisibility -Mode Disable -Module DP
    Interactive-SiteRolesControlVisibility -Mode Disable -Module AppCat
    Interactive-SiteRolesControlVisibility -Mode Disable -Module EP
    Interactive-SiteRolesControlVisibility -Mode Disable -Module SMP
    $TabPageSiteRoles.Controls.AddRange(@($TextBoxSiteSystemRolesMP, $GBSiteSystemRolesMP))
    Interactive-SiteRolesControlVisibility -Mode Enable -Module MP
})
$RadioButtonSiteRoleDP = New-Object System.Windows.Forms.RadioButton
$RadioButtonSiteRoleDP.Location = New-Object System.Drawing.Size(25,65)
$RadioButtonSiteRoleDP.Size = New-Object System.Drawing.Size(120,25)
$RadioButtonSiteRoleDP.Text = "Distribution Point"
$RadioButtonSiteRoleDP.Name = "Option Distribution Point"
$RadioButtonSiteRoleDP.Checked = $false
$RadioButtonSiteRoleDP.Add_Click({
    if ($RadioButtonSiteRoleDP.Checked -eq $true) {
        $OutputBoxSiteRoles.ResetText()
    }
    $OutputBoxSiteRoles.ResetText()
    $ProgressBarSiteRoles.Value = 0
    Write-OutputBox -OutputBoxMessage "Distribution Point selections loaded" -Type "INFO: " -Object SiteRoles
    Write-OutputBox -OutputBoxMessage "Click on the Install button to install the required Windows Features for a Distribution Point site system role" -Type "INFO: " -Object SiteRoles
    Interactive-SiteRolesControlVisibility -Mode Disable -Module MP
    Interactive-SiteRolesControlVisibility -Mode Disable -Module AppCat
    Interactive-SiteRolesControlVisibility -Mode Disable -Module EP
    Interactive-SiteRolesControlVisibility -Mode Disable -Module SMP
    $TabPageSiteRoles.Controls.AddRange(@($TextBoxSiteSystemRolesDP, $GBSiteSystemRolesDP))
    Interactive-SiteRolesControlVisibility -Mode Enable -Module DP
})
$RadioButtonSiteRoleAppCat = New-Object System.Windows.Forms.RadioButton
$RadioButtonSiteRoleAppCat.Location = New-Object System.Drawing.Size(25,95)
$RadioButtonSiteRoleAppCat.Size = New-Object System.Drawing.Size(120,25)
$RadioButtonSiteRoleAppCat.Text = "Application Catalog"
$RadioButtonSiteRoleAppCat.Name = "Option Application Catalog"
$RadioButtonSiteRoleAppCat.Checked = $false
$RadioButtonSiteRoleAppCat.Add_Click({
    if ($RadioButtonSiteRoleAppCat.Checked -eq $true) {
        $OutputBoxSiteRoles.ResetText()
    }
    $OutputBoxSiteRoles.ResetText()
    $ProgressBarSiteRoles.Value = 0
    Write-OutputBox -OutputBoxMessage "Application Catalog selections loaded" -Type "INFO: " -Object SiteRoles
    Write-OutputBox -OutputBoxMessage "Click on the Install button to install the required Windows Features for the Application Catalog site system roles" -Type "INFO: " -Object SiteRoles
    Interactive-SiteRolesControlVisibility -Mode Disable -Module MP
    Interactive-SiteRolesControlVisibility -Mode Disable -Module DP
    Interactive-SiteRolesControlVisibility -Mode Disable -Module EP
    Interactive-SiteRolesControlVisibility -Mode Disable -Module SMP
    $TabPageSiteRoles.Controls.AddRange(@($TextBoxSiteSystemRolesAppCat, $GBSiteSystemRolesAppCat))
    Interactive-SiteRolesControlVisibility -Mode Enable -Module AppCat
})
$RadioButtonSiteRoleEP = New-Object System.Windows.Forms.RadioButton
$RadioButtonSiteRoleEP.Location = New-Object System.Drawing.Size(25,125)
$RadioButtonSiteRoleEP.Size = New-Object System.Drawing.Size(120,25)
$RadioButtonSiteRoleEP.Text = "Enrollment Point"
$RadioButtonSiteRoleEP.Name = "Option Enrollment Point"
$RadioButtonSiteRoleEP.Checked = $false
$RadioButtonSiteRoleEP.Add_Click({
    if ($RadioButtonSiteRoleEP.Checked -eq $true) {
        $OutputBoxSiteRoles.ResetText()
    }
    $ProgressBarSiteRoles.Value = 0
    $ComboBoxSiteRolesEP.SelectedIndex = -1
    Write-OutputBox -OutputBoxMessage "Enrollment Point selections loaded" -Type "INFO: " -Object SiteRoles
    Write-OutputBox -OutputBoxMessage "Select to install required Windows Features for either an Enrollment Point or an Enrollment Proxy Point site system role" -Type "INFO: " -Object SiteRoles
    Interactive-SiteRolesControlVisibility -Mode Disable -Module MP
    Interactive-SiteRolesControlVisibility -Mode Disable -Module DP
    Interactive-SiteRolesControlVisibility -Mode Disable -Module AppCat
    Interactive-SiteRolesControlVisibility -Mode Disable -Module SMP
    $TabPageSiteRoles.Controls.AddRange(@($ComboBoxSiteRolesEP, $TextBoxSiteSystemRolesEP, $GBEP, $GBSiteSystemRolesEP))
    Interactive-SiteRolesControlVisibility -Mode Enable -Module EP
})

$RadioButtonSiteRoleSMP = New-Object System.Windows.Forms.RadioButton
$RadioButtonSiteRoleSMP.Location = New-Object System.Drawing.Size(25,155)
$RadioButtonSiteRoleSMP.Size = New-Object System.Drawing.Size(170,25)
$RadioButtonSiteRoleSMP.Text = "State Migration Point"
$RadioButtonSiteRoleSMP.Name = "Option State Migration Point"
$RadioButtonSiteRoleSMP.Checked = $false
$RadioButtonSiteRoleSMP.Add_Click({
    if ($RadioButtonSiteRoleSMP.Checked -eq $true) {
        $OutputBoxSiteRoles.ResetText()
    }
    $ProgressBarSiteRoles.Value = 0
    Write-OutputBox -OutputBoxMessage "State Migration Point selections loaded" -Type "INFO: " -Object SiteRoles
    Write-OutputBox -OutputBoxMessage "Click on the Install button to install the required Windows Features for the State Migration Point site system role" -Type "INFO: " -Object SiteRoles
    Interactive-SiteRolesControlVisibility -Mode Disable -Module MP
    Interactive-SiteRolesControlVisibility -Mode Disable -Module DP
    Interactive-SiteRolesControlVisibility -Mode Disable -Module AppCat
    Interactive-SiteRolesControlVisibility -Mode Disable -Module EP
    $TabPageSiteRoles.Controls.AddRange(@($TextBoxSiteSystemRolesSMP, $GBSiteSystemRolesSMP))
    Interactive-SiteRolesControlVisibility -Mode Enable -Module SMP
})

$RadioButtonOtherEAD = New-Object System.Windows.Forms.RadioButton
$RadioButtonOtherEAD.Location = New-Object System.Drawing.Size(25,35)
$RadioButtonOtherEAD.Size = New-Object System.Drawing.Size(170,25)
$RadioButtonOtherEAD.Text = "Extend Active Directory"
$RadioButtonOtherEAD.Name = "Option Extend Active Directory"
$RadioButtonOtherEAD.Checked = $false
$RadioButtonOtherEAD.Add_MouseClick({
    if ($RadioButtonOtherEAD.Checked -eq $true) {
        $OutputBoxOther.ResetText()
    }
    $ProgressBarOther.Value = 0
    $ButtonInstallOther.Text = "Extend"
    if ($TextBoxDC.Enabled -eq $false) {
        $TextBoxDC.Enabled = $true
    }
    Write-OutputBox -OutputBoxMessage "Extend Active Directory selections loaded" -Type "INFO: " -Object Other
    Write-OutputBox -OutputBoxMessage "Enter the server name of the Schema Master server in the textbox below" -Type "INFO: " -Object Other
    Interactive-OtherControlVisibility -Mode Disable -Module WSUS
    Interactive-OtherControlVisibility -Mode Disable -Module ADK
    Interactive-OtherControlVisibility -Mode Disable -Module SMC
    Interactive-OtherControlVisibility -Mode Disable -Module NoSMS
    $TabPageOther.Controls.AddRange(@($TextBoxDC, $GBExtendAD))
    Interactive-OtherControlVisibility -Mode Enable -Module EAD
})
$RadioButtonOtherWSUS = New-Object System.Windows.Forms.RadioButton
$RadioButtonOtherWSUS.Location = New-Object System.Drawing.Size(25,65)
$RadioButtonOtherWSUS.Size = New-Object System.Drawing.Size(170,25)
$RadioButtonOtherWSUS.Text = "Install WSUS"
$RadioButtonOtherWSUS.Name = "Option Install WSUS"
$RadioButtonOtherWSUS.Checked = $false
$RadioButtonOtherWSUS.Add_Click({
    if ($RadioButtonOtherWSUS.Checked -eq $true) {
        $OutputBoxOther.ResetText()
    }
    $TextBoxWSUSSQLServer.Enabled = $false
    $TextBoxWSUSSQLInstance.Enabled = $false
    $ProgressBarOther.Value = 0
    if (-not($ButtonInstallOther.Text -eq "Install")) {
        $ButtonInstallOther.Text = "Install"
    }
    $ComboBoxOtherWSUS.SelectedIndex = -1
    Write-OutputBox -OutputBoxMessage "Install WSUS selections loaded" -Type "INFO: " -Object Other
    Write-OutputBox -OutputBoxMessage "Select whether the WSUS database should be created on a SQL Server or by creating a local Windows Internal Database (WID)" -Type "INFO: " -Object Other
    Interactive-OtherControlVisibility -Mode Disable -Module EAD
    Interactive-OtherControlVisibility -Mode Disable -Module ADK
    Interactive-OtherControlVisibility -Mode Disable -Module SMC
    Interactive-OtherControlVisibility -Mode Disable -Module NoSMS
    $TabPageOther.Controls.AddRange(@($ComboBoxOtherWSUS, $TextBoxWSUSSQLServer, $TextBoxWSUSSQLInstance, $GBWSUS, $GBWSUSSQL))
    Interactive-OtherControlVisibility -Mode Enable -Module WSUS
})
$RadioButtonOtherADK = New-Object System.Windows.Forms.RadioButton
$RadioButtonOtherADK.Location = New-Object System.Drawing.Size(25,95)
$RadioButtonOtherADK.Size = New-Object System.Drawing.Size(170,25)
$RadioButtonOtherADK.Text = "Install Windows ADK"
$RadioButtonOtherADK.Name = "Option Install Windows ADK"
$RadioButtonOtherADK.Checked = $false
$RadioButtonOtherADK.Add_Click({
    if ($RadioButtonOtherADK.Checked -eq $true) {
        $OutputBoxOther.ResetText()
    }
    $ProgressBarOther.Value = 0
    if (-not($ButtonInstallOther.Text -eq "Install")) {
        $ButtonInstallOther.Text = "Install"
    }
    $ComboBoxOtherADK.SelectedIndex = -1
    Write-OutputBox -OutputBoxMessage "Install Windows ADK selections loaded" -Type "INFO: " -Object Other
    Write-OutputBox -OutputBoxMessage "Select whether to install Windows ADK by downloading the setup bootstrapper from the internet (Online), or by pointing to a folder where the complete redistributed Windows ADK setup files have been downloaded locally (Offline)" -Type "INFO: " -Object Other
    Interactive-OtherControlVisibility -Mode Disable -Module EAD
    Interactive-OtherControlVisibility -Mode Disable -Module WSUS
    Interactive-OtherControlVisibility -Mode Disable -Module SMC
    Interactive-OtherControlVisibility -Mode Disable -Module NoSMS
    $TabPageOther.Controls.AddRange(@($ComboBoxOtherADK, $GBADK))
    Interactive-OtherControlVisibility -Mode Enable -Module ADK
})
$RadioButtonOtherSMC = New-Object System.Windows.Forms.RadioButton
$RadioButtonOtherSMC.Location = New-Object System.Drawing.Size(25,125)
$RadioButtonOtherSMC.Size = New-Object System.Drawing.Size(181,25)
$RadioButtonOtherSMC.Text = "System Management Container"
$RadioButtonOtherSMC.Name = "Option System Management Container"
$RadioButtonOtherSMC.Font = New-Object System.Drawing.Font("Microsoft Sans Serif","8.25",[System.Drawing.FontStyle]::Regular)
$RadioButtonOtherSMC.Checked = $false
$RadioButtonOtherSMC.Add_Click({
    if ($RadioButtonOtherSMC.Checked -eq $true) {
        $OutputBoxOther.ResetText()
    }
    $ProgressBarOther.Value = 0
    if (-not($ButtonInstallOther.Text -eq "Search")) {
        $ButtonInstallOther.Text = "Search"
    }
    Write-OutputBox -OutputBoxMessage "System Management Container selections loaded" -Type "INFO: " -Object Other
    Write-OutputBox -OutputBoxMessage "Click on the Search button to find an Active Directory group that contains all Site servers that will be given Full Control permissions on the System Management container. If you havn't yet created such a group containing all the Site server, please do so before you continue" -Type "INFO: " -Object Other
    Interactive-OtherControlVisibility -Mode Disable -Module EAD
    Interactive-OtherControlVisibility -Mode Disable -Module ADK
    Interactive-OtherControlVisibility -Mode Disable -Module WSUS
    Interactive-OtherControlVisibility -Mode Disable -Module NoSMS
    $TabPageOther.Controls.Add($CBSMCCreate)
    Interactive-OtherControlVisibility -Mode Enable -Module SMC
})

$RadioButtonOtherNoSMS = New-Object System.Windows.Forms.RadioButton
$RadioButtonOtherNoSMS.Location = New-Object System.Drawing.Size(25,155)
$RadioButtonOtherNoSMS.Size = New-Object System.Drawing.Size(181,25)
$RadioButtonOtherNoSMS.Text = "No SMS on drive"
$RadioButtonOtherNoSMS.Name = "Option No SMS on drive"
$RadioButtonOtherNoSMS.Font = New-Object System.Drawing.Font("Microsoft Sans Serif","8.25",[System.Drawing.FontStyle]::Regular)
$RadioButtonOtherNoSMS.Checked = $false
$RadioButtonOtherNoSMS.Add_Click({
    if ($RadioButtonOtherNoSMS.Checked -eq $true) {
        $OutputBoxOther.ResetText()
    }
    $ProgressBarOther.Value = 0
    if (-not($ButtonInstallOther.Text -eq "Create")) {
        $ButtonInstallOther.Text = "Create"
    }
    Write-OutputBox -OutputBoxMessage "No SMS on drive selections loaded" -Type "INFO: " -Object Other
    Write-OutputBox -OutputBoxMessage "Click on the Create button to create a NO_SMS_ON_DRIVE.SMS file that will instruct ConfigMgr not to use the drive for content, binaries etc" -Type "INFO: " -Object Other
    Interactive-OtherControlVisibility -Mode Disable -Module EAD
    Interactive-OtherControlVisibility -Mode Disable -Module ADK
    Interactive-OtherControlVisibility -Mode Disable -Module WSUS
    Interactive-OtherControlVisibility -Mode Disable -Module SMC
    $TabPageOther.Controls.AddRange(@($ComboBoxOtherNoSMS, $GBNoSMS))
    $FixedDriveDeviceIDs = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $env:COMPUTERNAME -Filter "DriveType = '3'" | Select-Object -ExpandProperty DeviceID | Sort-Object
    $ComboBoxOtherNoSMS.Items.AddRange(@($FixedDriveDeviceIDs))
    Interactive-OtherControlVisibility -Mode Enable -Module NoSMS
})

$RadioButtonOnline = New-Object System.Windows.Forms.RadioButton
$RadioButtonOnline.Location = New-Object System.Drawing.Size(20,417)
$RadioButtonOnline.Size = New-Object System.Drawing.Size(60,24)
$RadioButtonOnline.Text = "Online"
$RadioButtonOffline = New-Object System.Windows.Forms.RadioButton
$RadioButtonOffline.Location = New-Object System.Drawing.Size(90,417)
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
$RadioButtonWID = New-Object System.Windows.Forms.RadioButton
$RadioButtonWID.Location = New-Object System.Drawing.Size(20,417)
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

# CheckBoxes
$CBValidationOverride = New-Object System.Windows.Forms.CheckBox
$CBValidationOverride.Location = New-Object System.Drawing.Size(30,205)
$CBValidationOverride.Size = New-Object System.Drawing.Size(180,20)
$CBValidationOverride.Text = "Override validation results"
$CBValidationOverride.Name = "ValidationOverride"
$CBValidationOverride.Add_CheckedChanged({
    switch ($CBValidationOverride.Checked) {
        $true { Interactive-TabPages -Mode Enable }
        $false { Interactive-TabPages -Mode Disable }
    }
})
$CBSMCCreate = New-Object System.Windows.Forms.CheckBox
$CBSMCCreate.Location = New-Object System.Drawing.Size(10,425)
$CBSMCCreate.Size = New-Object System.Drawing.Size(250,20)
$CBSMCCreate.Text = "Create the System Management container"
$CBSMCCreate.Name = "SMC"
$CBCASDownloadPrereqs = New-Object System.Windows.Forms.CheckBox
$CBCASDownloadPrereqs.Location = New-Object System.Drawing.Size(10,425)
$CBCASDownloadPrereqs.Size = New-Object System.Drawing.Size(190,20)
$CBCASDownloadPrereqs.Text = "Download prerequisite files"
$CBPrimaryDownloadPrereqs = New-Object System.Windows.Forms.CheckBox
$CBPrimaryDownloadPrereqs.Location = New-Object System.Drawing.Size(10,425)
$CBPrimaryDownloadPrereqs.Size = New-Object System.Drawing.Size(190,20)
$CBPrimaryDownloadPrereqs.Text = "Download prerequisite files"

# GroupBoxes
$GBGeneralValidation = New-Object System.Windows.Forms.GroupBox
$GBGeneralValidation.Location = New-Object System.Drawing.Size(20,20) 
$GBGeneralValidation.Size = New-Object System.Drawing.Size(220,210)
$GBGeneralValidation.Text = "Validation checks"
$GBGeneralVersion = New-Object System.Windows.Forms.GroupBox
$GBGeneralVersion.Location = New-Object System.Drawing.Size(20,250) 
$GBGeneralVersion.Size = New-Object System.Drawing.Size(220,110)
$GBGeneralVersion.Text = "Supported ConfigMgr versions"
$GBGeneralReboot = New-Object System.Windows.Forms.GroupBox
$GBGeneralReboot.Location = New-Object System.Drawing.Size(30,35) 
$GBGeneralReboot.Size = New-Object System.Drawing.Size(200,40) 
$GBGeneralOS = New-Object System.Windows.Forms.GroupBox
$GBGeneralOS.Location = New-Object System.Drawing.Size(30,75) 
$GBGeneralOS.Size = New-Object System.Drawing.Size(200,40) 
$GBGeneralPS = New-Object System.Windows.Forms.GroupBox
$GBGeneralPS.Location = New-Object System.Drawing.Size(30,115) 
$GBGeneralPS.Size = New-Object System.Drawing.Size(200,40) 
$GBGeneralElevated = New-Object System.Windows.Forms.GroupBox
$GBGeneralElevated.Location = New-Object System.Drawing.Size(30,155) 
$GBGeneralElevated.Size = New-Object System.Drawing.Size(200,40) 
$GBSiteSystemRoles = New-Object System.Windows.Forms.GroupBox
$GBSiteSystemRoles.Location = New-Object System.Drawing.Size(10,10) 
$GBSiteSystemRoles.Size = New-Object System.Drawing.Size(190,350) 
$GBSiteSystemRoles.Text = "Select a Site System Role"
$GBSiteSystemRoles.Name = "Option Site System Roles"
$GBSiteSystemRolesMP = New-Object System.Windows.Forms.GroupBox
$GBSiteSystemRolesMP.Location = New-Object System.Drawing.Size(10,410) 
$GBSiteSystemRolesMP.Size = New-Object System.Drawing.Size(220,45) 
$GBSiteSystemRolesMP.Text = "Add Site Server to Administrators group"
$GBSiteSystemRolesMP.Name = "MP"
$GBSiteSystemRolesDP = New-Object System.Windows.Forms.GroupBox
$GBSiteSystemRolesDP.Location = New-Object System.Drawing.Size(10,410) 
$GBSiteSystemRolesDP.Size = New-Object System.Drawing.Size(220,45) 
$GBSiteSystemRolesDP.Text = "Add Site Server to Administrators group"
$GBSiteSystemRolesDP.Name = "DP"
$GBSiteSystemRolesAppCat = New-Object System.Windows.Forms.GroupBox
$GBSiteSystemRolesAppCat.Location = New-Object System.Drawing.Size(10,410) 
$GBSiteSystemRolesAppCat.Size = New-Object System.Drawing.Size(220,45) 
$GBSiteSystemRolesAppCat.Text = "Add Site Server to Administrators group"
$GBSiteSystemRolesAppCat.Name = "AppCat"
$GBSiteSystemRolesEP = New-Object System.Windows.Forms.GroupBox
$GBSiteSystemRolesEP.Location = New-Object System.Drawing.Size(190,410) 
$GBSiteSystemRolesEP.Size = New-Object System.Drawing.Size(220,45) 
$GBSiteSystemRolesEP.Text = "Add Site Server to Administrators group"
$GBSiteSystemRolesEP.Name = "EP"
$GBSiteSystemRolesSMP = New-Object System.Windows.Forms.GroupBox
$GBSiteSystemRolesSMP.Location = New-Object System.Drawing.Size(10,410) 
$GBSiteSystemRolesSMP.Size = New-Object System.Drawing.Size(220,45) 
$GBSiteSystemRolesSMP.Text = "Add Site Server to Administrators group"
$GBSiteSystemRolesSMP.Name = "SMP"
$GBOther = New-Object System.Windows.Forms.GroupBox
$GBOther.Location = New-Object System.Drawing.Size(10,10) 
$GBOther.Size = New-Object System.Drawing.Size(200,350) 
$GBOther.Text = "Make a selection"
$GBOther.Name = "Option Make a selection"
$GBADK = New-Object System.Windows.Forms.GroupBox
$GBADK.Location = New-Object System.Drawing.Size(10,410) 
$GBADK.Size = New-Object System.Drawing.Size(150,45) 
$GBADK.Text = "Installation methods"
$GBADK.Name = "ADK"
$GBWSUS = New-Object System.Windows.Forms.GroupBox
$GBWSUS.Location = New-Object System.Drawing.Size(10,410) 
$GBWSUS.Size = New-Object System.Drawing.Size(130,45) 
$GBWSUS.Text = "Database options"
$GBWSUS.Name = "WSUS"
$GBWSUSSQL = New-Object System.Windows.Forms.GroupBox
$GBWSUSSQL.Location = New-Object System.Drawing.Size(150,410) 
$GBWSUSSQL.Size = New-Object System.Drawing.Size(310,45) 
$GBWSUSSQL.Text = "SQL Server details"
$GBWSUSSQL.Name = "WSUS"
$GBExtendAD = New-Object System.Windows.Forms.GroupBox
$GBExtendAD.Location = New-Object System.Drawing.Size(10,410) 
$GBExtendAD.Size = New-Object System.Drawing.Size(190,45) 
$GBExtendAD.Text = "Schema Master server name"
$GBExtendAD.Name = "EAD"
$GBSystemManagementContainer = New-Object System.Windows.Forms.GroupBox
$GBSystemManagementContainer.Location = New-Object System.Drawing.Size(10,375) 
$GBSystemManagementContainer.Size = New-Object System.Drawing.Size(360,45) 
$GBSystemManagementContainer.Text = "Add computer account to the System Management container"
$GBSystemManagementContainerGroup = New-Object System.Windows.Forms.GroupBox
$GBSystemManagementContainerGroup.Location = New-Object System.Drawing.Size(10,375) 
$GBSystemManagementContainerGroup.Size = New-Object System.Drawing.Size(360,45) 
$GBSystemManagementContainerGroup.Text = "Selected Active Directory group"
$GBSystemManagementContainerGroupSearch = New-Object System.Windows.Forms.GroupBox
$GBSystemManagementContainerGroupSearch.Location = New-Object System.Drawing.Size(10,10) 
$GBSystemManagementContainerGroupSearch.Size = New-Object System.Drawing.Size(360,45) 
$GBSystemManagementContainerGroupSearch.Text = "Search for an Active Directory group"
$GBNoSMS = New-Object System.Windows.Forms.GroupBox
$GBNoSMS.Location = New-Object System.Drawing.Size(10,410) 
$GBNoSMS.Size = New-Object System.Drawing.Size(150,45) 
$GBNoSMS.Text = "Select drive"
$GBNoSMS.Name = "NoSMS"
$GBEP = New-Object System.Windows.Forms.GroupBox
$GBEP.Location = New-Object System.Drawing.Size(10,410) 
$GBEP.Size = New-Object System.Drawing.Size(170,45) 
$GBEP.Text = "Select a site system role"
$GBEP.Name = "EP"

# ComboBoxes
$ComboBoxSiteRolesEP = New-Object System.Windows.Forms.ComboBox
$ComboBoxSiteRolesEP.Location = New-Object System.Drawing.Size(20,427)
$ComboBoxSiteRolesEP.Size = New-Object System.Drawing.Size(150,20)
$ComboBoxSiteRolesEP.DropDownStyle = "DropDownList"
$ComboBoxSiteRolesEP.Items.AddRange(@("Enrollment Point","Enrollment Proxy Point"))
$ComboBoxSiteRolesEP.Name = "EP"
$ComboBoxOtherWSUS = New-Object System.Windows.Forms.ComboBox
$ComboBoxOtherWSUS.Location = New-Object System.Drawing.Size(20,427)
$ComboBoxOtherWSUS.Size = New-Object System.Drawing.Size(110,20)
$ComboBoxOtherWSUS.DropDownStyle = "DropDownList"
$ComboBoxOtherWSUS.Items.AddRange(@("SQL","WID"))
$ComboBoxOtherWSUS.Name = "WSUS"
$ComboBoxOtherWSUS.Add_SelectedValueChanged({
    if ($ComboBoxOtherWSUS.SelectedItem -eq "SQL") {
        $TextBoxWSUSSQLServer.Enabled = $true
        $TextBoxWSUSSQLInstance.Enabled = $true
    }
    if ($ComboBoxOtherWSUS.SelectedItem -eq "WID") {
        $TextBoxWSUSSQLServer.Enabled = $false
        $TextBoxWSUSSQLInstance.Enabled = $false
    }
})
$ComboBoxOtherADK = New-Object System.Windows.Forms.ComboBox
$ComboBoxOtherADK.Location = New-Object System.Drawing.Size(20,427)
$ComboBoxOtherADK.Size = New-Object System.Drawing.Size(130,20)
$ComboBoxOtherADK.DropDownStyle = "DropDownList"
$ComboBoxOtherADK.Items.AddRange(@("Online","Offline"))
$ComboBoxOtherADK.Name = "ADK"
$ComboBoxOtherNoSMS = New-Object System.Windows.Forms.ComboBox
$ComboBoxOtherNoSMS.Location = New-Object System.Drawing.Size(20,427)
$ComboBoxOtherNoSMS.Size = New-Object System.Drawing.Size(130,20)
$ComboBoxOtherNoSMS.DropDownStyle = "DropDownList"
$ComboBoxOtherNoSMS.Name = "NoSMS"

#Load Form
Load-Form