
$LocalServerName  = 'SCASTRO-T460S\MSSQLSERVER2014'
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
else {
    foreach ($db in $LocalServer.Databases ) {
        write-host ("Database ["+$DB.Name+"] found.")
        foreach($ds in $db.DataSources) {
            write-host ("     DS: ["+$ds.Name+"]   Conn str = "+$ds.ConnectionString)
        }
        Write-Host("________________________________________________________________________________________________________________________________________")
    }
}


