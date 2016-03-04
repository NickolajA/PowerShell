<#
.SYNOPSIS
    Dynamically install Microsoft Visual C++ Redistributables by architecture

.DESCRIPTION
    This script will install Microsoft Visual C++ Redistributables by specified architecture.
    It requires a supported folder layout e.g. like the following:

    .\Install-VisualCRedist.ps1
    .\Source\2008x86
    .\Source\2008x64
    .\Source\2010x86
    .\Source\2010x64

    Place the script in the same folder where you create the 'Source' folder. The 'Source' folder is hard-coded
    into the script and cannot be named something else. If the source folder does not exist, the script will fail.
    There's a requirement of either x86 or x64 in the sub-folder names, or the script will fail as well. 
    Desired executables for each version and architecture should be placed in the supported sub-folders.

.PARAMETER Architecture
    Select desired architecture to install Visual C++ applications on. You can specify both x86 and x64 as a string array.

.PARAMETER ShowProgress
    Show a progressbar displaying the current operation.

.EXAMPLE
    Install Visual C++ Redistributables for both x86 and x64 architectures, in addition to show the current progress:
    .\Install-VisualCRedist.ps1 -Architecture x86, x64 -ShowProgress
    
.NOTES
    Script name: Install-VisualCRedist.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    DateCreated: 2016-02-29
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Select desired architecture to install Visual C++ applications on. You can specify both x86 and x64 as a string array.")]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("x86","x64")]
    [string[]]$Architecture = "x86, x64",
    [parameter(Mandatory=$false, HelpMessage="Show a progressbar displaying the current operation.")]
    [switch]$ShowProgress = $true
)
Process {
    # Functions
    function Install-ApplicationExectuable {
        param(
            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [ValidateSet("x86","x64")]
            [string]$ApplicationArchitecture,
            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$CurrentWorkingDirectory
        )
        if ($Script:PSBoundParameters["ShowProgress"]) {
            $ProgressCount = 0
        }
        # Determine application executable list
        $ApplicationExecutableFolders = Get-ChildItem -LiteralPath $CurrentWorkingDirectory -Filter "*$($ApplicationArchitecture)*" | Select-Object -ExpandProperty FullName
        # Validate that the Source directory is not empty
        if ($ApplicationExecutableFolders -ne $null) {
            $ApplicationExecutableFolderCount = ($ApplicationExecutableFolders | Measure-Object).Count
            foreach ($ApplicationExecutableFolder in $ApplicationExecutableFolders) {
                $CurrentApplicationPath = Get-ChildItem -LiteralPath $ApplicationExecutableFolder | Select-Object -ExpandProperty FullName
                # Validate executable count
                if (($CurrentApplicationPath | Measure-Object).Count -eq 1) {
                    # Validate that executable file exists
                    if (($CurrentApplicationPath -ne $null) -and ([System.IO.Path]::GetExtension((Split-Path -Path $CurrentApplicationPath -Leaf)) -like ".exe")) {
                        $CurrentFileDescription = (Get-Item -LiteralPath $CurrentApplicationPath | Select-Object -Property VersionInfo).VersionInfo.FileDescription
                        if ($Script:PSBoundParameters["ShowProgress"]) {
                            $ProgressCount++
                            Write-Progress -Activity "Installing Microsoft Visual C++ Redistributables ($($ApplicationArchitecture))" -Id 1 -Status "$($ProgressCount) / $($ApplicationExecutableFolderCount)" -CurrentOperation "Installing: $($CurrentFileDescription)" -PercentComplete (($ProgressCount / $ApplicationExecutableFolderCount) * 100)
                        }
                        Write-Verbose -Message "Installing: $($CurrentFileDescription)"
                        # Install the current executable
                        $ReturnValue = Start-Process -FilePath $CurrentApplicationPath -ArgumentList "/q /norestart" -Wait -PassThru
                        if (($ReturnValue.ExitCode -eq 0) -or ($ReturnValue.ExitCode -eq 3010)) {
                            Write-Verbose -Message "Successfully installed: $($CurrentFileDescription)"
                        }
                        else {
                            Write-Verbose -Message "Failed to install: $($CurrentFileDescription)"
                        }
                    }
                    else {
                        Write-Warning -Message "Unsupported file extension found in folder: $($ApplicationExecutableFolder)"
                    }
                }
                else {
                    Write-Warning -Message "Skipping folder due to unsupported number of files in: $($ApplicationExecutableFolder)"
                }
            }
            if ($Script:PSBoundParameters["ShowProgress"]) {
                Write-Progress -Activity "Installing Microsoft Visual C++ Redistributables ($($ApplicationArchitecture))" -Id 1 -Completed -Status "Completed"
            }
        }
    }

    # Install Microsoft Visual C++ Redistributables
    foreach ($Arch in $Architecture) {
        Install-ApplicationExectuable -ApplicationArchitecture $Arch -CurrentWorkingDirectory (Join-Path -Path (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent) -ChildPath "\Source")
    }
}
