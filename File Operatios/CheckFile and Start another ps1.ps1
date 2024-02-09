<#************************************************************************************************************************
*  This script will check when a file pops into a folder and kick another PS script
************************************************************************************************************************#>
cls
$CheckInterval   = 5 # in seconds
$FolderToCheck   = "c:\temp"
$FileToCheck     = "MyFile.txt"

$LogFile         = "c:\temp\FileCheck.log"
$PS1bName        = "c:\temp\Script1.ps1 -LogfileName "+$LogFile

### SET FOLDER TO WATCH + FILES TO WATCH + SUBFOLDERS YES/NO
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $FolderToCheck
    $watcher.Filter = $FileToCheck
    $watcher.IncludeSubdirectories = $false
    $watcher.EnableRaisingEvents = $true

### DEFINE ACTIONS AFTER AN EVENT IS DETECTED
    $action = { $path = $Event.SourceEventArgs.FullPath
                $changeType = $Event.SourceEventArgs.ChangeType
                Add-content $LogFile -value "File detected! $FolderToCheck\$FileToCheck"

                Start-Process powershell.exe -ArgumentList ($PS1bName) -WindowStyle Hidden
                Add-content $LogFile -value "Script $PS1bName finished."
                sleep $CheckInterval
                Remove-Item -Path ($FolderToCheck+"\"+$FileToCheck) -Force
                Add-content $LogFile -value "File $FolderToCheck\$FileToCheck deleted."
              }    

### DECIDE WHICH EVENTS SHOULD BE WATCHED 
    Register-ObjectEvent $watcher "Created" -Action $action
    while ($true) 
    {
        sleep $CheckInterval
        $logline = "$(Get-Date), Checking $path"
        Add-content $LogFile -value $logline
            
    }
