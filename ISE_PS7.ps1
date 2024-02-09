$Process = Start-Process PWSH -ArgumentList @("-NoExit") -PassThru -WindowStyle Hidden
$ci = New-Object -TypeName System.Management.Automation.Runspaces.NamedPipeConnectionInfo -ArgumentList @($Process.Id)
$tt = [System.Management.Automation.Runspaces.TypeTable]::LoadDefaultTypeFiles()
$Runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($ci, $Host, $tt)
$Runspace.Open()
$Runspace
$Host.PushRunspace($Runspace)

$PSVersionTable.PSVersion.Major

#Install-Module -Name SqlServer

