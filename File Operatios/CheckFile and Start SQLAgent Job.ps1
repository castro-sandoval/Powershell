<#************************************************************************************************************************
*  This script will check when a file pops into a folder and kick a SQL Job
************************************************************************************************************************#>
cls
$CheckInterval   = 5 # in seconds
$FolderToCheck   = "c:\temp"
$FileToCheck     = "MyFile.txt"
$LogFile         = "c:\temp\FileCheck.log"
$JobName         = "job test1"

### SET FOLDER TO WATCH + FILES TO WATCH + SUBFOLDERS YES/NO
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $FolderToCheck
    $watcher.Filter = $FileToCheck
    $watcher.IncludeSubdirectories = $false
    $watcher.EnableRaisingEvents = $true

### DEFINE ACTIONS AFTER AN EVENT IS DETECTED
    $action = { $path = $Event.SourceEventArgs.FullPath
                $changeType = $Event.SourceEventArgs.ChangeType
                $EventTime  = $Event.TimeGenerated

                Add-content $LogFile -value ($FolderToCheck+"\"+$FileToCheck+" was "+$changeType+" at "+$EventTime)

                <#
                $dt = new-object "System.Data.DataTable"
                $cn = new-object System.Data.SqlClient.SqlConnection "server=.;database=msdb;Integrated Security=sspi"
                $cn.Open()
                $sql = $cn.CreateCommand()
                $sql.CommandText = "exec msdb.dbo.sp_start_job @job_name = '"+$JobName+"'"
                $rdr = $sql.ExecuteNonQuery()
                $cn.Close()
                #>
                
              }    

### DECIDE WHICH EVENTS SHOULD BE WATCHED 
### Event to be monitored:   'Created', 'Changed' and 'Deleted'
    Register-ObjectEvent $watcher "Deleted" -Action $action
    while ($true) 
    {
        sleep $CheckInterval
        $logline = "$(Get-Date), Checking "+$FolderToCheck+"\"+$FileToCheck
        #Add-content $LogFile -value $logline
        Write-Output $logline
            
    }
