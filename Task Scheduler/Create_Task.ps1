$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument '"-f C:\myGithub\Powershell\AWS\backup scripts\Count_S3_Files.ps1"'

#$trigger = New-ScheduledTaskTrigger -Daily -At 11:27am

#Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "CountS3Files" -Description "Count file in S3 bucket"
Register-ScheduledTask -Action $action -TaskName "CountS3Files" -Description "Count file in S3 bucket"