
$SSAS_LocalInstance       = 'IP-0AE87D75'
$SSAS_DestinationInstance = 'IP-0AE879E9\ESPSANDBOX'
$BackupFolder             = "B:\SSASdbs\"

cls

<#======================================================================
            Check if able to connect to servers
======================================================================#>

$loadInfo = [Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices")


$LocalServer  = New-Object Microsoft.AnalysisServices.Server
$LocalServer.connect($SSAS_LocalInstance)
if ($LocalServer.name -eq $null) {
    Write-Output ("Server ‘{0}’ not found" -f $SSAS_LocalInstance)
    break
} else {
    Write-Output($SSAS_LocalInstance+" connected.")
}

<#======================================================================
    Check backup folder
======================================================================#>
if (Test-Path -Path $BackupFolder) {
    Remove-item -Path ($BackupFolder+"\*.abf") -Force
} else {
    New-Item -Path $BackupFolder -ItemType Directory
}

<#======================================================================
    Backup each database on the Local Server   TO   $BackupFolder
======================================================================#>

foreach ($db in $LocalServer.Databases ) {
    $filename = $BackupFolder+$db.Name+'.abf'
    
    Write-Host("Backing up "+$db.Name+" to "+$BackupFolder+$db.Name+'.abf')

    if (Test-Path($BackupFolder+$db.Name+'.abf')) {
        Remove-Item -Path ($BackupFolder+$db.Name+'.abf') -Force
    }
    
    $backup_cmd  = '<Backup xmlns="http://schemas.microsoft.com/analysisservices/2003/engine"><Object><DatabaseID>'+$db.Name+'</DatabaseID></Object><File>'+$filename+'</File><ApplyCompression>false</ApplyCompression></Backup>'

    $errorMessage = ($LocalServer.Execute($backup_cmd)).Messages
    if ($errorMessage.count -gt 0) {
        $errorMessage } 
    else {
        write-host($db.Name+" successfully backed up")
    }
 
}
write-host("")
write-host("===============================================")
write-host("SSAS backup finished successfully")
write-host("===============================================")
