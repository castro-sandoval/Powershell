$FirstDate = Get-Date
Get-EventLog -LogName Application -After ($FirstDate.AddDays(-10)) | Out-File c:\temp\WinApp.log
Get-EventLog -LogName System -After ($FirstDate.AddDays(-10)) | Out-File c:\temp\WinSys.log
