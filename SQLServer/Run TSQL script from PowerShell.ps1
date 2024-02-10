$ScriptToRun = "C:\temp\SQLQuery1.sql"
$Database = "TestDB"

Start-Process -FilePath "sqlcmd.exe" -ArgumentList ("-U sa -P password -d"+$Database+" -i "+$ScriptToRun)