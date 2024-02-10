Get-WmiObject -Class Win32_Service | Where-Object {($_.ProcessId -eq 1384)} | Select -Property Name, State, Status


Get-NetTCPConnection -LocalPort 5001 | Select -Property *