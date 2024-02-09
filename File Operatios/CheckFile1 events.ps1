cls
$folder    = "C:\Temp"
$filter    = "MyFile.txt"
$LogFile   = "C:\temp\FileCheck.log"
$MoveTo    = "C:\Temp\Log"
$JobName   = "TestJob"

$Watcher = New-Object IO.FileSystemWatcher $folder, $filter -Property @{ 
    IncludeSubdirectories = $false
    NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'
}

$onCreated = Register-ObjectEvent $Watcher Created -SourceIdentifier FileCreated -Action {
   $path = $Event.SourceEventArgs.FullPath
   $name = $Event.SourceEventArgs.Name
   $changeType = $Event.SourceEventArgs.ChangeType
   $timeStamp = $Event.TimeGenerated
   
   
   $Message = ("The file '$name' was $changeType at $timeStamp")
   Write-Host $Message
   Add-content $LogFile -value $Message

   
   Move-Item $path -Destination $MoveTo -Force #-Verbose


   $dt = new-object "System.Data.DataTable"
   $cn = new-object System.Data.SqlClient.SqlConnection "server=.;database=msdb;Integrated Security=sspi"
   $cn.Open()
   $sql = $cn.CreateCommand()
   $sql.CommandText = "exec msdb.dbo.sp_start_job @job_name = '"+$JobName+"'"
   $rdr = $sql.ExecuteNonQuery()
   $cn.Close()


}


#Unregister-Event FileDeleted 
#Unregister-Event FileCreated 
#Unregister-Event FileChanged