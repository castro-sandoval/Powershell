<#************************************************************************************************************************
*  This script will check when a file pops into a folder and kick a SQL Agent Job
************************************************************************************************************************#>
cls
$CheckInterval   = 5 # in seconds
$FolderToCheck   = "c:\temp"
$FilesToCheck    = "MyFile.txt"
$LogFile         = "c:\temp\FileCheck.log"
$JobName         = "job test1"


$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $FolderToCheck
$watcher.Filter = $FilesToCheck
$watcher.IncludeSubdirectories = $false
$watcher.EnableRaisingEvents = $true
$action = { $path = $Event.SourceEventArgs.FullPath
            $changeType = $Event.SourceEventArgs.ChangeType
            Add-content $LogFile -value "File detected! $LogFile"
            $dt = new-object "System.Data.DataTable"
            $cn = new-object System.Data.SqlClient.SqlConnection "server=.;database=msdb;Integrated Security=sspi"
            $cn.Open()
            $sql = $cn.CreateCommand()
            $sql.CommandText = "exec msdb.dbo.sp_start_job @job_name = '"+$JobName+"'"
            $rdr = $sql.ExecuteNonQuery()
            $cn.Close()
           }    
Register-ObjectEvent $watcher "Created" -Action $action
while ($true) { sleep $CheckInterval}
