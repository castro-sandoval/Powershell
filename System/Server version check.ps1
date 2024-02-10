cls
Get-Date | Out-File "C:\TEMP\ServerInfo.txt" -Append default
"PowerShell version: "+$PSVersionTable.PSVersion | Out-File "C:\TEMP\ServerInfo.txt" -Append default
"CLR Version: "+[System.Runtime.InteropServices.RuntimeEnvironment]::GetSystemVersion() | Out-File "C:\TEMP\ServerInfo.txt" -Append default
".NET Framework Version: "+(Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse | Get-ItemProperty -name Version,Release -EA 0 | Where { $_.PSChildName -match '^(?!S)\p{L}'} | Select PSChildName, Version | where {$_.PSChildName -eq "Full"} | select Version | ft -HideTableHeaders | Out-String).TrimStart().TrimEnd()  | Out-File "C:\TEMP\ServerInfo.txt" -Append default
systeminfo | Out-File "C:\TEMP\ServerInfo.txt" -Append default
$FirstDate = Get-Date
Get-EventLog -LogName System -After ($FirstDate.AddDays(-5)) -EntryType Error | Out-File "C:\TEMP\ServerInfo.txt" -Append default
Get-EventLog -LogName Application -After ($FirstDate.AddDays(-5)) -EntryType Error | Out-File "C:\TEMP\ServerInfo.txt" -Append default
