
$LocalServerName  = 'SCASTRO-T460S\MSSQLSERVER2014'
$RemoteServerName = 'SCASTRO-T460S'
$BackupFilePath   = "C:\Temp\SSAS_Backup\"
cls
<#======================================================================
            Check if able to connect to servers
======================================================================#>

$loadInfo = [Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices")
$LocalServer  = New-Object Microsoft.AnalysisServices.Server

$LocalServer.connect($LocalServerName)
if ($LocalServer.name -eq $null) {
    Write-Output ("Server ‘{0}’ not found" -f $LocalServerName)
break
}


$RemoteServer = New-Object Microsoft.AnalysisServices.Server
$RemoteServer.connect($RemoteServerName)
if ($RemoteServer.name -eq $null) {
    Write-Output ("Server ‘{0}’ not found" -f $RemoteServerName)
break
}


<#======================================================================
    Backup each database on the Local Server   TO   $BackupFilePath
======================================================================#>

foreach ($db in $LocalServer.Databases ) {
    $filename = $BackupFilePath+$db.Name+'.abf'
    
    Write-Host("Backing up "+$db.Name+" to "+$BackupFilePath+$db.Name+'.abf')

    if (Test-Path($BackupFilePath+$db.Name+'.abf')) {
        Remove-Item -Path ($BackupFilePath+$db.Name+'.abf') -Force
    }
    
    $backup_cmd  = '<Backup xmlns="http://schemas.microsoft.com/analysisservices/2003/engine"><Object><DatabaseID>'+$db.Name+'</DatabaseID></Object><File>'+$filename+'</File><ApplyCompression>false</ApplyCompression></Backup>'

    $errorMessage = ($LocalServer.Execute($backup_cmd)).Messages
    if ($errorMessage.count -gt 0) {
        $errorMessage } 
    else {
        write-host($db.Name+" succesfuly backed up")
    }
 
}



<#======================================================================
    RESTORE all files on $BackupFilePath on Remote Server
======================================================================#>
Write-Host ("Restore on "+$RemoteServerName)

$BackupFiles = Get-ChildItem -Path $BackupFilePath
foreach($file in $BackupFiles) {
    Write-Host ("Restoring "+$file.FullName+"  to Database name: "+[System.IO.Path]::GetFileNameWithoutExtension($file.Name))
    $restore_cmd = '<Restore xmlns="http://schemas.microsoft.com/analysisservices/2003/engine"><File>'+$file.Fullname+'</File><DatabaseName>'+[System.IO.Path]::GetFileNameWithoutExtension($file.Name)+'</DatabaseName><DatabaseID>'+[System.IO.Path]::GetFileNameWithoutExtension($file.Name)+'</DatabaseID><AllowOverwrite>true</AllowOverwrite></Restore>'
    
    
    
    $errorMessage = ($RemoteServer.Execute($restore_cmd)).Messages
    if ($errorMessage.count -gt 0) {
        $errorMessage } 
    else {
        write-host([System.IO.Path]::GetFileNameWithoutExtension($file.Name)+" succesfuly restored")

    }
}
