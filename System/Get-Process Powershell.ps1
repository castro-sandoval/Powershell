Clear-Host
# Identify powershell_ise running
Get-Process | Where-Object {($_.Name -eq "powershell_ise")} | select -Property Id, Name, Responding, HasExited, SessionId, StartTime, UserProcessorTime, MainWindowTitle, Handle, ProcessName, Threads | Format-Table *
(Get-Process | Where-Object {($_.Name -eq "powershell_ise") -and ($_.Id -eq 128008)}).Threads.Count