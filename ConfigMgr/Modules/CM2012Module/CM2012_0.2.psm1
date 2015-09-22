function New-NoSMSOnDrive {
    <#  
    .SYNOPSIS  
        This function can be run against a server to create the NO_SMS_ON_DRIVE.SMS file.
    .DESCRIPTION
        This function can be run against a server to create the NO_SMS_ON_DRIVE.SMS file.
    .PARAMETER Drive
        Destination drive letter where the file will be created.
    .NOTES  
        Name: New-NoSMSOnDrive
        Author: Nickolaj Andersen
        DateCreated: 2014-01-07
         
    .LINK  
        http://www.scconfigmgr.com
    .EXAMPLE  
    New-NoSMSOnDrive -Drive C:

    Description
    -----------
    This command will create a file called 'NO_SMS_ON_DRIVE.SMS' on the specified drive.
          
    #> 
    [CmdletBinding()]
    param(
    [ValidateScript({$_ -match "^[A-Z]*\:$"})]
    [ValidateCount(1,2)]
    [ValidateNotNull()]
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
    [string[]]$Drive
    )
    Process {
        foreach ($Object in $Drive) {
            $NoSMSOnDrive = Get-Item -Path "$($Object)\"
            if (Test-Path -Path "$($NoSMSOnDrive.FullName)\NO_SMS_ON_DRIVE.SMS") {
                Write-Output "Found file NO_SMS_ON_DRIVE.SMS on the $($Object) drive, will not create a new file"
            }
            else {
                try {
                    New-Item -ItemType file -Name NO_SMS_ON_DRIVE.SMS -Path $NoSMSOnDrive | Out-Null
                }
                catch {
                    Write-Output $_.Exception.Message
                }
            }
        }
    }
}

function New-SkipSoftwareInventory {
    <#  
    .SYNOPSIS  
        This function can be run against a server to create the skpswi.dat file that prevents Software Inventory of a directory.
    .DESCRIPTION
        This function can be run against a server to create the skpswi.dat file that prevents Software Inventory of a directory.
    .PARAMETER Path
        Destination path where the file will be created.
    .NOTES  
        Name: New-SkipSoftwareInventory
        Author: Nickolaj Andersen
        DateCreated: 2014-01-07
         
    .LINK  
        http://www.scconfigmgr.com
    .EXAMPLE  
    New-SkipSoftwareInventory -Path 'C:\Windows\Temp'

    Description
    -----------
    This command will create a file called 'skpswi.dat' in the specified path.
          
    #> 
    [CmdletBinding()]
    param(
    [ValidateScript({Test-Path -Path $_ -PathType Container})]
    [ValidateNotNull()]
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
    $Path
    )
    Process {
        foreach ($Object in $Path) {
            $Skpswi = Get-Item -Path $Object
            if (Test-Path -Path "$($Skpswi.FullName)\skpswi.dat") {
                Write-Output "Found file skpswi.dat in the specified path, will not create a new file"
            }
            else {
                try {
                    New-Item -ItemType file -Name skpswi.dat -Path $Skpswi | Out-Null
                }
                catch {
                    Write-Output $_.Exception.Message
                }
            }
        }
    }
}

function Get-IISLogLocation {
    <#  
    .SYNOPSIS  
        This function can be run against a server to get the IIS log file location for each site.
    .DESCRIPTION
        This function can be run against a server to get the IIS log file location for each site.
    .PARAMETER ComputerName
        The NetBIOS name of the computer to run the script against.
    .NOTES  
        Name: Get-IISLogLocation
        Author: Nickolaj Andersen
        DateCreated: 2014-01-07
         
    .LINK  
        http://www.scconfigmgr.com
    .EXAMPLE  
    Get-IISLogLocation -ComputerName 'SRV001'

    Description
    -----------
    This command will get the IIS log file location configured for each site.
          
    #> 
    [CmdletBinding()]
    param(
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1})]
    [ValidateNotNull()]
    [parameter(Mandatory=$true)]
    $ComputerName
    )
    Process {
        try {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration") | Out-Null
                $IIS = New-Object Microsoft.Web.Administration.ServerManager
                $Sites = $IIS.Sites
                $Sites | ForEach-Object {
                    $LogFilePath = $_.Logfile | Select-Object Directory
                    Write-Output $LogFilePath
                }
            }
        }
        catch {
            Write-Output $_.Exception.Message
        }
    }
}

function Set-IISLogLocation {
    <#  
    .SYNOPSIS  
        This function can be run against a server to set the IIS log file location for each site.
    .DESCRIPTION
        This function can be run against a server to set the IIS log file location for each site.
    .PARAMETER ComputerName
        The NetBIOS name of the computer to run the script against.
    .PARAMETER Path
        The path to the new location of the IIS log files.
    .NOTES  
        Name: Set-IISLogLocation
        Author: Nickolaj Andersen
        DateCreated: 2014-01-07
         
    .LINK  
        http://www.scconfigmgr.com
    .EXAMPLE  
    Set-IISLogLocation -ComputerName 'SRV001' -Path 'C:\Folder\IIS'

    Description
    -----------
    This command will set the IIS log file location configured for each site.
          
    #> 
    [CmdletBinding()]
    param(
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1})]
    [ValidateNotNull()]
    [parameter(Mandatory=$true)]
    $ComputerName,
    [ValidateNotNull()]
    [parameter(Mandatory=$true)]
    [string]$Path
    )
    Process {
        try {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                param(
                [parameter(Mandatory=$true)]
                $Path
                )
                try {
                    if(-not(Test-Path -Path $Path -ErrorAction SilentlyContinue)) {
                        New-Item -Path $Path -ItemType Directory | Out-Null
                    }
                }
                catch {
                    Write-Error $_.Exception
                }
                [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration") | Out-Null
                $IIS = New-Object Microsoft.Web.Administration.ServerManager
                $Sites = $IIS.Sites
                $Sites | ForEach-Object {
                    $_.Logfile.Directory = "'$($Path)'"
                    $IIS.CommitChanges()
                }
            } -ArgumentList $Path
        }
        catch {
            Write-Output $_.Exception.Message
        }
    }
}

function Set-MaxMIFSize {
    <#  
    .SYNOPSIS  
        This function can be run against a server to set the 'Max MIF Size' registry value.
    .DESCRIPTION
        This function can be run against a server to set the 'Max MIF Size' registry value.
    .PARAMETER ComputerName
        The NetBIOS name of the computer to run the script against.
    .PARAMETER Size
        Integer value of the maximum size for MIF size that the system will handle. Specified in hex, e.g. 3200000 = 50MB.
    .NOTES  
        Name: Set-MaxMIFSize
        Author: Nickolaj Andersen
        DateCreated: 2014-01-07
         
    .LINK  
        http://www.scconfigmgr.com
    .EXAMPLE  
    Set-MaxMIFSize -ComputerName 'SRV001' -Size 3200000

    Description
    -----------
    This command will set the 'Max MIF Size' DWORD value in 'HKLM\SOFTWARE\Microsoft\SMS\Components\SMS_INVENTORY_DATA_LOADER'.
          
    #>
    [CmdletBinding()]
    param(
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1})]
    [ValidateNotNull()]
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
    $ComputerName,
    [ValidateNotNull()]
    [parameter(Mandatory=$true)]
    [int]$Size
    )
    Process {
        try {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                param(
                $Size,
                $ComputerName
                )
                $Key = "SOFTWARE\Microsoft\SMS\Components\SMS_INVENTORY_DATA_LOADER"
                $BaseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $ComputerName)
                $SubKey = $BaseKey.OpenSubkey($Key,$true)
                $SubKey.SetValue('Max MIF Size',$Size,[Microsoft.Win32.RegistryValueKind]::DWORD)
            } -ArgumentList ($Size,$ComputerName)
        }
        catch {
            Write-Output $_.Exception.Message
        }
    }
}

function Get-PXECacheExpire {
    <#  
    .SYNOPSIS  
        This function can be run against a server to get the 'CacheExpire' registry value for PXE.
    .DESCRIPTION
        This function can be run against a server to get the 'CacheExpire' registry value for PXE.
    .PARAMETER ComputerName
        The NetBIOS name of the computer to run the script against.
    .NOTES  
        Name: Get-PXECacheExpire
        Author: Nickolaj Andersen
        DateCreated: 2014-01-08
         
    .LINK  
        http://www.scconfigmgr.com
    .EXAMPLE  
    Get-PXECacheExpire -ComputerName 'SRV001'

    Description
    -----------
    This command will get the 'CacheExpire' value in 'HKLM\Software\Microsoft\SMS\DP'.
          
    #>
    [CmdletBinding()]
    param(
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1})]
    [ValidateNotNull()]
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
    $ComputerName
    )
    Process {
        $PSObject = New-Object -TypeName PSObject
        foreach ($Object in $ComputerName) {
            try {
                Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                    param(
                    $ComputerName,
                    $PSObject
                    )
                    $Key = "SOFTWARE\Microsoft\SMS\DP"
                    $BaseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $ComputerName)
                    $SubKey = $BaseKey.OpenSubkey($Key,$true)
                    $Value = $SubKey.GetValue('CacheExpire',[Microsoft.Win32.RegistryValueKind]::String)
                    if ($Value -like "String") {
                        $Value = ""
                    }
                    $PSObject | Add-Member -MemberType NoteProperty -Name Value $Value -PassThru | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName -PassThru
                } -ArgumentList ($ComputerName,$PSObject)
                Write-Output $PSObject
            }
            catch {
                Write-Output $_.Exception.Message
            }
        }
    }
}

function Set-PXECacheExpire {
    <#  
    .SYNOPSIS  
        This function can be run against a server to set the 'CacheExpire' registry value for PXE.
    .DESCRIPTION
        This function can be run against a server to set the 'CacheExpire' registry value for PXE.
    .PARAMETER ComputerName
        The NetBIOS name of the computer to run the script against.
    .PARAMETER Value
        Integer value that will be set in the 'CacheExpire' registry value.
    .NOTES  
        Name: Set-PXECacheExpire
        Author: Nickolaj Andersen
        DateCreated: 2014-01-08
         
    .LINK  
        http://www.scconfigmgr.com
    .EXAMPLE  
    Set-PXECacheExpire -ComputerName 'SRV001' -Value 120

    Description
    -----------
    This command will set the 'CacheExpire' value in 'HKLM\Software\Microsoft\SMS\DP' to 120 seconds.
          
    #>
    [CmdletBinding()]
    param(
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1})]
    [ValidateNotNull()]
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
    $ComputerName,
    [ValidateNotNull()]
    [parameter(Mandatory=$true)]
    [int]$Value
    )
    Process {
        $PSObject = New-Object -TypeName PSObject
        foreach ($Object in $ComputerName) {
            try {
                Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                    param(
                    $ComputerName,
                    $Value,
                    $PSObject
                    )
                    $Key = "SOFTWARE\Microsoft\SMS\DP"
                    $BaseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $ComputerName)
                    $SubKey = $BaseKey.OpenSubkey($Key,$true)
                    $SubKey.SetValue('CacheExpire',$Value,[Microsoft.Win32.RegistryValueKind]::String)
                    $Value = $SubKey.GetValue('CacheExpire',[Microsoft.Win32.RegistryValueKind]::String)
                    $PSObject | Add-Member -MemberType NoteProperty -Name Value $Value -PassThru | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName -PassThru
                } -ArgumentList ($ComputerName,$Value,$PSObject)
                Write-Output $PSObject
            }
            catch {
                Write-Output $_.Exception.Message
            }
        }
    }
}

function Remove-IISLogs {
    <#  
    .SYNOPSIS  
        This function can be run against a server to set the 'CacheExpire' registry value for PXE.
    .DESCRIPTION
        This function can be run against a server to set the 'CacheExpire' registry value for PXE.
    .PARAMETER ComputerName
        The NetBIOS name of the computer to run the script against.
    .PARAMETER Age
        Integer value for number of days to keep logs for.
    .NOTES  
        Name: Remove-IISLogs
        Author: Nickolaj Andersen
        DateCreated: 2014-01-08
         
    .LINK  
        http://www.scconfigmgr.com
    .EXAMPLE  
    Remove-IISLogs -ComputerName 'SRV001' -Age 7

    Description
    -----------
    This command will remove all logs files older than 7 days in each IIS site.


    Remove-IISLogs -ComputerName 'SRV001' -Age 7 -SiteName 'Default Web Site'

    Description
    -----------
    This command will remove all logs files older than 7 days in specified 'Default Web Site' IIS site.
          
    #>
    [CmdletBinding()]
    param(
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1})]
    [ValidateNotNull()]
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
    $ComputerName,
    [ValidateNotNull()]
    [parameter(Mandatory=$true)]
    [int]$Age,
    [parameter(Mandatory=$false)]
    [string]$SiteName
    )
    Process {
        $PSObject = New-Object -TypeName PSObject
        foreach ($Object in $ComputerName) {
            try {
                if (-not($SiteName)) {
                    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                        param(
                        $ComputerName,
                        $Age,
                        $PSObject
                        )
                        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration") | Out-Null
                        $IIS = New-Object Microsoft.Web.Administration.ServerManager
                        $Sites = $IIS.Sites
                        $Sites | ForEach-Object {
                            $LogFilePath = $_.Logfile | Select-Object Directory
                            $Path = $LogFilePath | Select-Object -ExpandProperty Directory
                            if ($Path -match "%SystemDrive%") {
                                $WorkPath = $Path -replace "%SystemDrive%","$env:SystemDrive" -replace "'",""
                            }
                            Get-ChildItem -Path $WorkPath -Recurse | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$Age) } | ForEach-Object { Remove-Item -Path $_.FullName -Recurse }
                            $PSObject | Add-Member -MemberType NoteProperty -Name LogFilePath $WorkPath -PassThru | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName -PassThru
                        }
                    } -ArgumentList ($ComputerName,$Age,$PSObject)
                }
                elseif (($SiteName | Measure-Object -Sum Length).Length -ge 1) {
                    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                        param(
                        $ComputerName,
                        $Age,
                        $SiteName,
                        $PSObject
                        )
                        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration") | Out-Null
                        $IIS = New-Object Microsoft.Web.Administration.ServerManager
                        $Sites = $IIS.Sites
                        $Site = $Sites | Where-Object { $_.Name -like "$($SiteName)" }
                        $LogFilePath = $Site.LogFile.Directory -replace "%SystemDrive%","$env:SystemDrive" -replace "'",""
                        Get-ChildItem -Path $LogFilePath -Recurse | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$Age) } | ForEach-Object { Remove-Item -Path $_.FullName -Recurse }
                        $PSObject | Add-Member -MemberType NoteProperty -Name LogFilePath $LogFilePath -PassThru | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName -PassThru | Add-Member -MemberType NoteProperty -Name SiteName -Value $Site.Name -PassThru
                    } -ArgumentList ($ComputerName,$Age,$SiteName,$PSObject)
                }
                Write-Output $PSObject
            }
            catch {
                Write-Output $_.Exception.Message
            }
        }
    }
}

function Rename-CMFolderNames {
    <#  
    .SYNOPSIS  
        This function can replace a portion of the name of all folders for a certain ObjectType.
    .DESCRIPTION
        This function can replace a portion of the name of all folders for a certain ObjectType.
    .PARAMETER ComputerName
        The NetBIOS name of the server where the SMS Provider is running.
    .PARAMETER ObjectType
        Integer value of the property ObjectType. Valid values:

        2       Packages Node
        8       Reports Node
        9       Software Metering Node
        14      OS Installers Node
        16      Virtual Hard Disks Node
        17      User Collections Node
        18      OS Images Node
        19      Boot Images Node
        20      Task Sequences Node
        23      Driver Packages Node
        25      Drivers Node
        1011    Software Updates Node
        2011    Configuration Baselines Node
        5000    Device Collections Node
        6000    Applications Node
        6001    Configuration Items Node
    .PARAMETER Locate
        String value to locate in the Folder name, will be replaced with the value from the Replace parameter.
    .PARAMETER Replace
        String value that will be replaced in the Folder name.
    .NOTES  
        Name: Rename-CMFolderNames
        Author: Nickolaj Andersen
        DateCreated: 2014-01-15
         
    .LINK  
        http://www.scconfigmgr.com
    .EXAMPLE  
    Rename-CMFolderNames -ComputerName 'SRV001' -ObjectType 5000 -Locate 'Updates' -Replace 'SUM'

    Description
    -----------
    This command will rename all Device Collection folders with the term 'Updates' in the name and replace it with 'SUM'.
    
    #>
    [CmdletBinding()]
    param(
    [parameter(Mandatory=$true)]
    [string]$ComputerName,
    [parameter(Mandatory=$true)]
    [int]$ObjectType,
    [parameter(Mandatory=$true)]
    [string]$Locate,
    [parameter(Mandatory=$true)]
    [string]$Replace
    )
    Process {
        $SiteCode = Get-WmiObject -Class SMS_ProviderLocation -Namespace "root\SMS" -ComputerName "$($ComputerName)" | Select-Object -ExpandProperty SiteCode
        $Folders = Get-WmiObject -Class SMS_ObjectContainerNode -Namespace "root\SMS\site_$($SiteCode)" -ComputerName "$($ComputerName)" | Where-Object { ($_.ObjectType -eq $ObjectType) -and ($_.Name -like "*$($Locate)*") }
        $Folders | ForEach-Object {
            $Object = New-Object -TypeName PSCustomObject -Property @{
                Folder = $_.Name
                NewName = $_.Name -replace "$($Locate)","$($Replace)"
            }
            try {
                $_.Name = $_.Name -replace "$($Locate)","$($Replace)"
                $_.Put() | Out-Null
            }
            catch {
                Write-Output $_.Exception.Message
            }
            Write-Output $Object
        }
    }
}

function Rename-CMCollectionNames {
    <#  
    .SYNOPSIS  
        This function can replace a portion of the name of all collections for a certain CollectionType.
    .DESCRIPTION
        This function can replace a portion of the name of all collections for a certain CollectionType.
    .PARAMETER ComputerName
        The NetBIOS name of the server where the SMS Provider is running.
    .PARAMETER CollectionType
        Integer value of the property CollectionType. Valid values:

        0    OTHER
        1    USER
        2    DEVICE
    .PARAMETER Locate
        String value to locate in the collection name, will be replaced with the value from the Replace parameter.
    .PARAMETER Replace
        String value that will be replaced in the collection name.
    .NOTES  
        Name: Rename-CMCollectionNames
        Author: Nickolaj Andersen
        DateCreated: 2014-01-15
         
    .LINK  
        http://www.scconfigmgr.com
    .EXAMPLE  
    Rename-CMCollectionNames -ComputerName 'SRV001' -CollectionType 2 -Locate 'PS2' -Replace 'PS1'

    Description
    -----------
    This command will rename all Device collections with the term 'PS2' in the name and replace it with 'PS1'.
    
    #>
    [CmdletBinding()]
    param(
    [parameter(Mandatory=$true)]
    [string]$ComputerName,
    [parameter(Mandatory=$true)]
    [int]$CollectionType,
    [parameter(Mandatory=$true)]
    [string]$Locate,
    [parameter(Mandatory=$true)]
    [string]$Replace
    )
    Process {
        $SiteCode = Get-WmiObject -Class SMS_ProviderLocation -Namespace "root\SMS" -ComputerName "$($ComputerName)" | Select-Object -ExpandProperty SiteCode
        $Collections = Get-WmiObject -Class SMS_Collection -Namespace "root\SMS\site_$($SiteCode)" -ComputerName "$($ComputerName)" | Where-Object { ($_.CollectionType -eq $CollectionType) -and ($_.Name -like "*$($Locate)*") }
        $Collections | ForEach-Object {
            $Object = New-Object -TypeName PSCustomObject -Property @{
                Collection = $_.Name
                NewName = $_.Name -replace "$($Locate)","$($Replace)"
            }
            try {
                $_.Name = $_.Name -replace "$($Locate)","$($Replace)"
                $_.Put() | Out-Null
            }
            catch {
                Write-Output $_.Exception.Message
            }
            Write-Output $Object
        }
    }
}

function Set-SQLInstanceMemory {
    <#  
    .SYNOPSIS  
        This function sets the 'MaxServerMemory' and 'MinServerMemory' configuration values on the default instance or a specified instance.
    .DESCRIPTION
        This function sets the 'MaxServerMemory' and 'MinServerMemory' configuration values on the default instance or a specified instance.
    .PARAMETER InstanceName
        String value of an instance on the local SQL server.
    .PARAMETER MaxMemory
        Integer value of MaxServerMemory.
    .PARAMETER MinMemory
        Integer value of MinServerMemory.
    .NOTES  
        Name: Set-SQLInstanceMemory
        Author: Nickolaj Andersen
        DateCreated: 2014-01-20
         
    .LINK  
        http://www.scconfigmgr.com
    .EXAMPLE  
    Set-SQLInstanceMemory -InstanceName "." -MinMemory 0 -MaxMemory 4096

    Description
    -----------
    This command will set the SQL memory configuration of the default instance, with the minimum memory value to '0' and the maximum memory value to '4096'.
    
    #>
    [CmdletBinding()]
    param(
    [parameter(Mandatory=$false)]
    [string]$InstanceName = ".",
    [parameter(Mandatory=$true)]
    [int]$MinMemory,
    [parameter(Mandatory=$true)]
    [int]$MaxMemory
    )
    Process {
        try {
            [Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
        }
        catch {
            Write-Output $_.Exception.Message
        }
        try {
            $ServerConnection = New-Object Microsoft.SQLServer.Management.Smo.Server($InstanceName)
            $ServerConnection.ConnectionContext.LoginSecure = $true
            $ServerConnection.Configuration.MaxServerMemory.ConfigValue = $MaxMemory
            $ServerConnection.Configuration.MinServerMemory.ConfigValue = $MinMemory
            $ServerConnection.Configuration.Alter()
            $Object = New-Object -TypeName PSCustomObject -Property @{
                MaxMemory = $ServerConnection.Configuration.MaxServerMemory.ConfigValue
                MinMemory = $ServerConnection.Configuration.MinServerMemory.ConfigValue
            }
            Write-Output $Object
        }
        catch {
            Write-Output $_.Exception.Message
        }
    }
}

function Get-SQLInstanceMemory {
    <#  
    .SYNOPSIS  
        This function gets the 'MaxServerMemory' and 'MinServerMemory' configuration values on the default instance or a specified instance.
    .DESCRIPTION
        This function gets the 'MaxServerMemory' and 'MinServerMemory' configuration values on the default instance or a specified instance.
    .PARAMETER InstanceName
        String value of an instance on the local SQL server.
    .NOTES  
        Name: Get-SQLInstanceMemory
        Author: Nickolaj Andersen
        DateCreated: 2014-01-20
         
    .LINK  
        http://www.scconfigmgr.com
    .EXAMPLE  
    Set-SQLInstanceMemory -InstanceName "."

    Description
    -----------
    This command will get the SQL memory configuration of the default instance.
    
    #>
    [CmdletBinding()]
    param(
    [parameter(Mandatory=$false)]
    [string]$InstanceName = "."
    )
    Process {
        try {
            [Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
        }
        catch {
            Write-Output $_.Exception.Message
        }
        try {
            $ServerConnection = New-Object Microsoft.SQLServer.Management.Smo.Server($InstanceName)
            $ServerConnection.ConnectionContext.LoginSecure = $true
            $Object = New-Object -TypeName PSCustomObject -Property @{
                MaxMemory = $ServerConnection.Configuration.MaxServerMemory.ConfigValue
                MinMemory = $ServerConnection.Configuration.MinServerMemory.ConfigValue
            }
            Write-Output $Object
        }
        catch {
            Write-Output $_.Exception.Message
        }
    }
}

function Update-CMApplicationSource {
    [CmdletBinding()]
    param(
    [parameter(Mandatory=$true,ParameterSetName="Single")]
    [parameter(ParameterSetName="Recurse")]
    [string]$SiteServer,
    [parameter(Mandatory=$false,ParameterSetName="Single")]
    $ApplicationName,
    [parameter(Mandatory=$true,ParameterSetName="Single")]
    [parameter(ParameterSetName="Recurse")]
    [string]$Locate,
    [parameter(Mandatory=$true,ParameterSetName="Single")]
    [parameter(ParameterSetName="Recurse")]
    [string]$Replace,
    [parameter(Mandatory=$false,ParameterSetName="Recurse")]
    [switch]$Recurse
    )
    function Get-CMSiteCode {
        $Script:SiteCode = Get-WmiObject -Namespace "root\sms" -Class "SMS_ProviderLocation" -ComputerName $SiteServer | Select-Object -ExpandProperty SiteCode
        return $Script:SiteCode
    }
    function Rename-ApplicationSource {
        param(
        [parameter(Mandatory=$true)]
        $AppName
        )
        $AppName | ForEach-Object {
            $LocalizedDisplayName = $_.LocalizedDisplayName
            $Application = Get-WmiObject -Namespace "root\SMS\site_$(Get-CMSiteCode)" -Class "SMS_Application" -ComputerName $SiteServer | Where-Object { ($_.IsLatest -eq $True) -and ($_.LocalizedDisplayName -like "$($LocalizedDisplayName)") }
            $CurrentApplication = [wmi]$Application.__PATH
            $ApplicationXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($CurrentApplication.SDMPackageXML,$True)
            foreach ($DeploymentType in $ApplicationXML.DeploymentTypes) {
                $Installer = $DeploymentType.Installer
                $CurrentContentLocation = $DeploymentType.Installer.Contents[0].Location
                $ContentLocation = $DeploymentType.Installer.Contents[0].Location -replace "$($Locate)", "$($Replace)"
                if ($CurrentContentLocation -match $Locate) {
                    if (Test-Path $ContentLocation -PathType Any) {
                        if ($CurrentContentLocation -ne $ContentLocation) {
                            $UpdateContent = [Microsoft.ConfigurationManagement.ApplicationManagement.ContentImporter]::CreateContentFromFolder($ContentLocation)
                            $UpdateContent.FallbackToUnprotectedDP = $True
                            $UpdateContent.OnFastNetwork = [Microsoft.ConfigurationManagement.ApplicationManagement.ContentHandlingMode]::Download
                            $UpdateContent.OnSlowNetwork = [Microsoft.ConfigurationManagement.ApplicationManagement.ContentHandlingMode]::DoNothing
                            $UpdateContent.PeerCache = $False
                            $UpdateContent.PinOnClient = $False
                            $Installer.Contents[0].ID = $UpdateContent.ID
                            $Installer.Contents[0] = $UpdateContent
                            $UpdatedXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::SerializeToString($ApplicationXML, $True)
                            $CurrentApplication.SDMPackageXML = $UpdatedXML
                            $CurrentApplication.Put() | Out-Null
                            $PSObject = New-Object -TypeName PSObject
                            $PSObject | Add-Member -MemberType NoteProperty -Name ApplicationName -Value $LocalizedDisplayName -PassThru | Add-Member -MemberType NoteProperty -Name OldContentLocation -Value $CurrentContentLocation -PassThru | Add-Member -MemberType NoteProperty -Name NewContentLocation -Value $ContentLocation -PassThru
                            Write-Output $Object
                        }
                        elseif ($CurrentContentLocation -eq $ContentLocation) {
                            Write-Warning "The current content location path matches the new location, will not update the path for '$($LocalizedDisplayName)'"
                        }
                    }
                    else {
                        Write-Warning "Unable to access $($ContentLocation), path not found."
                    }
                }
                else {
                    Write-Warning "The search term '$($Locate)' could not be matched in the content source location '$($CurrentContentLocation)'"
                }
            }
        }
    }
    try {
        [System.Reflection.Assembly]::LoadFrom((Join-Path (Get-Item $env:SMS_ADMIN_UI_PATH).Parent.FullName "Microsoft.ConfigurationManagement.ApplicationManagement.dll")) | Out-Null
        [System.Reflection.Assembly]::LoadFrom((Join-Path (Get-Item $env:SMS_ADMIN_UI_PATH).Parent.FullName "Microsoft.ConfigurationManagement.ApplicationManagement.Extender.dll")) | Out-Null
        [System.Reflection.Assembly]::LoadFrom((Join-Path (Get-Item $env:SMS_ADMIN_UI_PATH).Parent.FullName "Microsoft.ConfigurationManagement.ApplicationManagement.MsiInstaller.dll")) | Out-Null
    }
    catch {
        Write-Error $_.Exception
    }
    if (($Recurse -eq $true) -and ($ApplicationName.Length -eq 0)) {
        $ApplicationName = New-Object -TypeName System.Collections.ArrayList
        $GetApplications = Get-WmiObject -Namespace "root\SMS\site_$(Get-CMSiteCode)" -Class "SMS_Application" -ComputerName $SiteServer | Where-Object {$_.IsLatest -eq $True}
        $ApplicationCount = $GetApplications.Count
        $GetApplications | ForEach-Object {
            $ApplicationName.Add($_) | Out-Null
        }
        Rename-ApplicationSource -AppName $ApplicationName
    }
    elseif (($Recurse -eq $true) -and ($ApplicationName.Length -ge 1)) {
        Write-Warning "You cannot specify an ApplicationName and also use the Recurse switch at the same time"
    }
    if (($ApplicationName.Length -ge 1) -and ($Recurse -eq $false)) {
        $GetApplicationName = Get-WmiObject -Namespace "root\SMS\site_$(Get-CMSiteCode)" -Class "SMS_Application" -ComputerName $SiteServer | Where-Object {(($_.IsLatest -eq $True) -and ($_.LocalizedDisplayName -like "$($ApplicationName)"))}
        Rename-ApplicationSource -AppName $GetApplicationName
    }
}

function Set-SQLDBRecoveryModel {
    <#  
    .SYNOPSIS  
        This function sets the SQL Server Database 'RecoveryModel' option on a specified instance.
    .DESCRIPTION
        This function sets the SQL Server Database 'RecoveryModel' option on a specified instance.
    .PARAMETER InstanceName
        String value of an instance on the local SQL server.
    .PARAMETER DBName
        String value of a database name on the local SQL server.
    .PARAMETER RecoveryModel
        String value of the RecoveryModel option on the local SQL server. Valid sets are 'Full', 'Simple', 'Bulk-logged'.
    .NOTES  
        Name: Set-SQLDBRecoveryModel
        Author: Nickolaj Andersen
        DateCreated: 2014-04-25
         
    .LINK  
        http://www.scconfigmgr.com
    .EXAMPLE  
    Set-SQLDBRecoveryModel -InstanceName . -DBName CM_PS1 -RecoveryModel Simple

    Description
    -----------
    This command will set the RecoveryModel option for database 'CM_PS1' on the specified instance on the local SQL Server.
    
    #>
    [CmdletBinding()]
    param(
    [parameter(Mandatory=$true)]
    [string]$InstanceName,
    [parameter(Mandatory=$true)]
    [string]$DBName,
    [parameter(Mandatory=$true)]
    [ValidateSet("Full","Simple","Bulk-logged")]
    [string]$RecoveryModel
    )
    Begin {
        try {
            [Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
            [Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") | Out-Null
        }
        catch {
            Write-Error $_.Exception.Message
        }
    }
    Process {
        try {
            $ServerConnection = New-Object Microsoft.SqlServer.Management.Common.ServerConnection($env:COMPUTERNAME)
            $ServerConnection.ServerInstance = "$($InstanceName)"
            $ServerConnection.StatementTimeOut = 0
            $ServerConnection.Connect()
            $SMOConfig = New-Object Microsoft.SqlServer.Management.Smo.Server($ServerConnection)
            $OldRecoveryModel = $SMOConfig.Databases["$($DBName)"].RecoveryModel
            $SMOConfig.Databases["$($DBName)"].RecoveryModel = "$($RecoveryModel)"
            $SMOConfig.Databases["$($DBName)"].Alter()
            $NewRecoveryModel = $SMOConfig.Databases["$($DBName)"].RecoveryModel
            $PSObject = New-Object -TypeName PSObject -Property @{
                OldRecoveryModel = $OldRecoveryModel
                NewRecoveryModel = $NewRecoveryModel
            }
            return $PSObject
        }
        catch {
            Write-Error $_.Exception.Message
        }
    }
    End {
        if ($ServerConnection.IsOpen) {
            $ServerConnection.Disconnect()
        }
    }
}