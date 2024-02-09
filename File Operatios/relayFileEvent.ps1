$CheckInterval   = 15 # in seconds
$FolderToCheck   = 'D:\K2Reports'
$FilesToCheck    = 'K2DataServices_*.bak'
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $FolderToCheck
$watcher.Filter = $FilesToCheck
$watcher.IncludeSubdirectories = $false
$watcher.EnableRaisingEvents = $true
$action = { $path = $Event.SourceEventArgs.FullPath
            $changeType = $Event.SourceEventArgs.ChangeType
            if (!(Test-Path -Path "R:\")) {
                $secpasswd = ConvertTo-SecureString "llama123!" -AsPlainText -Force
                $mycreds = New-Object System.Management.Automation.PSCredential ("DCHSSQL\K2ReportsUser", $secpasswd)
                New-PSDrive -Name R -PSProvider FileSystem -Root "\\DCHSSQL\K2Reports" -Credential $mycreds
            }
            if (Test-Path -Path "R:\") {
                Copy-Item -Path "D:\K2Reports\K2DataServices_*.bak" -Destination "R:\"
                Remove-Item -Path "D:\K2Reports\K2DataServices_*.bak" -Force
            }
            Add-Content -Path "D:\K2Reports\K2Reports.log" -Value ((Get-Date).ToString()+" : File was copied to SAASDSRPT")
          }    
Register-ObjectEvent $watcher "Created" -Action $action
while ($true) { sleep $CheckInterval}




