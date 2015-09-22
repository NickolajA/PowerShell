[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Specify a single or an array of either IP addresses, NetBIOS names or FQDNs")]
    [string[]]$Targets,
    [parameter(Mandatory=$true, HelpMessage="Specify a single or an array or ports to validate")]
    [string[]]$Ports,
    [parameter(Mandatory=$true, HelpMessage="Specify what protocol to use, valid options are: TCP or UDP")]
    [ValidateSet("TCP","UDP")]
    [string]$Protocol,
    [parameter(Mandatory=$false, HelpMessage="Specify path and file name for results to be exported in CSV format")]
    [ValidateScript({$_ -like "*.csv"})]
    [string]$ExportPath
)

Begin {
    Write-Verbose -Message "Starting to process"
    $HostName = $env:COMPUTERNAME
}
Process {
    function Write-CustomObject {
        param(
        [parameter(Mandatory=$true)]
        [string]$HostName,
        [parameter(Mandatory=$true)]
        [string]$IPAddress,
        [parameter(Mandatory=$true)]
        [ValidateSet("Success","Failure")]
        [string]$Results,
        [parameter(Mandatory=$true)]
        [string]$Protocol,
        [parameter(Mandatory=$true)]
        [string]$Port
        )
        $PSObject = New-Object -TypeName PSObject
        $PSObject | Add-Member -MemberType NoteProperty -Name "From" -Value $HostName
        $PSObject | Add-Member -MemberType NoteProperty -Name "To" -Value $IPAddress
        $PSObject | Add-Member -MemberType NoteProperty -Name "Results" -Value $Results
        $PSObject | Add-Member -MemberType NoteProperty -Name "Protocol" -Value $Protocol
        $PSObject | Add-Member -MemberType NoteProperty -Name "Port" -Value $Port
        if ($ExportPath.Length -ge 8) {
            $PSObject | Export-Csv -Path $ExportPath -NoClobber -NoTypeInformation -Append -Force
        }
        return $PSObject
    }
    foreach ($Target in $Targets) {
        foreach ($Port in $Ports) {
            if ($Protocol -like "TCP") {
                try {
                    Write-Verbose -Message "Trying to establish a connection from '$($HostName)' to '$($Target)' using '$($Protocol) $($Port)'"
                    $TCPConnection = New-Object System.Net.Sockets.TcpClient($Target, $Port)
                    if ($TCPConnection -ne $null) {    
                        Write-CustomObject -HostName $HostName -IPAddress $Target -Results Success -Protocol TCP -Port $Port
                    }
                }
                catch {                 
                    Write-CustomObject -HostName $HostName -IPAddress $Target -Results Failure -Protocol TCP -Port $Port
                } 
                finally {
                    $TCPConnection.Close | Out-Null
                    $TCPConnection.Dispose | Out-Null
                }
            }
            if ($Protocol -like "UDP") {
                try {
                    Write-Verbose -Message "Trying to establish a connection from '$($HostName)' to '$($Target)' using '$($Protocol) $($Port)'"
                    $UDPConnection = New-Object System.Net.Sockets.UdpClient($Target, $Port)
                    if ($UDPConnection -ne $null) {    
                        Write-CustomObject -HostName $HostName -IPAddress $Target -Results Success -Protocol UDP -Port $Port
                    }
                }
                catch {                 
                    Write-CustomObject -HostName $HostName -IPAddress $Target -Results Failure -Protocol UDP -Port $Port
                } 
                finally {
                    $UDPConnection.Close | Out-Null
                    $UDPConnection.Dispose | Out-Null
                }
            }
        }
    }
}
End {
    Write-Verbose -Message "Finished processing"
}