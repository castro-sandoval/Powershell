function Test-Administrator
{
$user = [Security.Principal.WindowsIdentity]::GetCurrent() 
(New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

If(Test-Administrator)
{
    Write-Host "It is Administrator"
}
else
{
    $ElevatedProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell" # Process to run as administrator
    $ElevatedProcess.Arguments =  "file.ps1" # file to run
    $ElevatedProcess.Verb = "runas"     
    [System.Diagnostics.Process]::Start($ElevatedProcess)     
    exit
}
