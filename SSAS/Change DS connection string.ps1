
<#======================================================================
            Fix the connection string
======================================================================#>
cls
$RemoteServerName = 'SCASTRO-T460S'

$loadInfo = [Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices")

$RemoteServer = New-Object Microsoft.AnalysisServices.Server
$RemoteServer.connect($RemoteServerName)

Write-Host ("Fix the connection strings")

foreach ($db in $RemoteServer.Databases ) {
    "--------------------------------------------------------------------------------------------"
    write-host ("Fixing DB: "+$DB.Name)
    foreach($ds in $db.DataSources) {
        $new_connstr = ($ds.ConnectionString -replace "SCASTRO-T460S","NEW-SERVER")
        $alter_cmd  = '<Alter ObjectExpansion="ExpandFull" xmlns="http://schemas.microsoft.com/analysisservices/2003/engine"><Object><DatabaseID>'+$DB.Name+'</DatabaseID><DataSourceID>'+$ds.Name+'</DataSourceID></Object>'
        $alter_cmd += '<ObjectDefinition><DataSource xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:ddl2="http://schemas.microsoft.com/analysisservices/2003/engine/2" xmlns:ddl2_2="http://schemas.microsoft.com/analysisservices/2003/engine/2/2" xmlns:ddl100_100="http://schemas.microsoft.com/analysisservices/2008/engine/100/100" xmlns:ddl200="http://schemas.microsoft.com/analysisservices/2010/engine/200" xmlns:ddl200_200="http://schemas.microsoft.com/analysisservices/2010/engine/200/200" xmlns:ddl300="http://schemas.microsoft.com/analysisservices/2011/engine/300" xmlns:ddl300_300="http://schemas.microsoft.com/analysisservices/2011/engine/300/300" xmlns:ddl400="http://schemas.microsoft.com/analysisservices/2012/engine/400" xmlns:ddl400_400="http://schemas.microsoft.com/analysisservices/2012/engine/400/400" xmlns:ddl500="http://schemas.microsoft.com/analysisservices/2013/engine/500" xmlns:ddl500_500="http://schemas.microsoft.com/analysisservices/2013/engine/500/500" xsi:type="RelationalDataSource">'
        $alter_cmd += '<ID>'+$ds.Name+'</ID><Name>'+$ds.Name+'</Name><ConnectionString>'+$new_connstr+'</ConnectionString>'
        $alter_cmd += '<ImpersonationInfo><ImpersonationMode>'+$ds.ImpersonationInfo.ImpersonationMode+'</ImpersonationMode><Account>'+$ds.ImpersonationInfo.Account+'</Account></ImpersonationInfo></DataSource></ObjectDefinition></Alter>'
        $errorMessage = ($RemoteServer.Execute($alter_cmd)).Messages
        if ($errorMessage.count -gt 0) {
            $errorMessage } 
        else {
            write-host("Data Source "+$ds.Name+": Connection string succesfuly changed.")
        }

    }
}
