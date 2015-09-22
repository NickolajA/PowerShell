$TSEnvironment = New-Object -ComObject Microsoft.SMS.TSEnvironment
$Variables = $TSEnvironment.GetVariables()
$Variables | ForEach-Object {
    Add-Content -Path "$($env:SystemDrive)\Windows\Temp\OSDVariables.log" -Value "############ Variable: $($_) ############"
    Add-Content -Path "$($env:SystemDrive)\Windows\Temp\OSDVariables.log" -Value $TSEnvironment.Value("$($_)")
    Add-Content -Path "$($env:SystemDrive)\Windows\Temp\OSDVariables.log" -Value "#########################################"
}