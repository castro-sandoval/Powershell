
<#======================================================================
            Clean remote server
======================================================================#>
cls
$RemoteServerName = 'SCASTRO-T460S'

$loadInfo = [Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices")

$RemoteServer = New-Object Microsoft.AnalysisServices.Server
$RemoteServer.connect($RemoteServerName)

if ($RemoteServer.name -eq $null) {
    Write-Output ("Server ‘{0}’ not found" -f $RemoteServerName)
    break 
    } 
else {
    foreach($db in $RemoteServer.Databases) {
        $delete_cmd = '<Delete xmlns="http://schemas.microsoft.com/analysisservices/2003/engine"><Object><DatabaseID>'+$db.Name+'</DatabaseID></Object></Delete>'
        $errorMessage = ($RemoteServer.Execute($delete_cmd)).Messages
        if ($errorMessage.count -gt 0) {
            $errorMessage } 
        else {
            write-host($db.Name+" succesfuly deleted.")
        }
    }

}