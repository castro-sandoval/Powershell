

$ServerInstance   = (Get-ChildItem -path env:computername | select -Property Value -Verbose).Value
$TSQL_restoreFile = "D:\Backups\restore.sql"
$LogFile          = "D:\Backups\RestorationTestProcess.log"
$ErrorFile        = "D:\Backups\RestorationTestProcessErrors.log"

if (Test-Path -Path $TSQL_restoreFile) {
    $ErrorsFound = $FALSE
    $file = (Get-Content -Path $TSQL_restoreFile)

    if (Test-Path -Path $LogFile) {
        Remove-Item -Path $LogFile -Force
    }
    if (Test-Path -Path $ErrorFile) {
        Remove-Item -Path $ErrorFile -Force
    }


    foreach($line in $file) {
        if ($line.Contains("RESTORE DATABASE")) {
            $line=$line.TrimEnd()
            $dbName= $line.Substring($line.IndexOf("RESTORE DATABASE")+18, $line.IndexOf("]  FROM DISK")-$line.IndexOf("RESTORE DATABASE")-18)
            $filePath = $line.Substring($line.IndexOf("]  FROM DISK")+15, $line.IndexOf("  WITH FILE")-$line.IndexOf("]  FROM DISK")-16)
            $fileName = $filePath.Substring($filePath.IndexOf("d:\Backups\")+11, $filePath.Length-$filePath.IndexOf("d:\Backups\")-11)
            $sqlcmd= "restore filelistonly"+$line.Substring($line.IndexOf("]  FROM DISK")+1, $line.IndexOf("  WITH FILE")-$line.IndexOf("]  FROM DISK")-1)
            $line=$line.Substring($line.IndexOf("*/")+2, $line.Length-$line.IndexOf("*/")-4)
            $lineEnd=$line.Substring($line.IndexOf(" WITH FILE = ")+15, $line.Length-$line.IndexOf(" WITH FILE = ")-15)
            $line=$line.Substring(1, $line.IndexOf(" WITH FILE = ")+15)

            #============ Download file from S3 to local D:\Backups folder ================
            $fileKey = (Get-S3Object -BucketName lcp2-sql-backups-us-east-1 -KeyPrefix "/" | Where-Object {($_.Key -like ("*/"+$fileName) ) }).key
            $LogMessage = (Read-S3Object -BucketName lcp2-sql-backups-us-east-1 -Key $fileKey -File ("D:\Backups\"+$fileName))
            Add-Content -Path $LogFile -Value $LogMessage

            if (Test-Path -Path $filePath) {
                $sqlFiles = (Invoke-Sqlcmd -Query $sqlcmd -ServerInstance $ServerInstance -Username "uuuu" -Password "******" -Database "master")
           
                # Extract internal file structure from backup file to build the restore local command
                foreach($sqlFile in $sqlFiles) {
                    $sqlFileName = $sqlFile.PhysicalName.Substring($sqlFile.PhysicalName.IndexOf($dbName), $sqlFile.PhysicalName.Length-$sqlFile.PhysicalName.IndexOf($dbName))
                    $line=$line+(" move '"+$sqlFile.LogicalName+"' TO 'D:\Backups\"+$sqlFileName+"', ")
                }           
                $sqlRestorecmd = ($line+$lineEnd)
                Add-Content -Path $LogFile -Value $sqlRestorecmd

                Invoke-Sqlcmd -Query $sqlRestorecmd -ServerInstance $ServerInstance -Username "uuuu" -Password "******" -Database "master"

                #============= Test the database ===============
                if ($sqlRestorecmd.Contains(" RECOVERY")) {
                    Invoke-Sqlcmd -Query ("DBCC CHECKDB (["+$dbname+"], NOINDEX) WITH PHYSICAL_ONLY") -ServerInstance $ServerInstance -Username "uuuu" -Password "******" -Database "master"
                    $CheckDB_Results = (Get-EventLog -LogName Application -Newest 1 | Where-Object {($_.EventID -eq 8957 -and $_.Source -eq "MSSQLSERVER" -and $_.Message -contains $dbname)} | select -Property TimeGenerated, Message)
                    
                    if ($CheckDB_Results.Message.IndexOf("sa found 0 errors and repaired 0 erros")) {
                        Add-Content -Path $LogFile -Value ($CheckDB_Results.TimeGenerated.ToString("yyyy-MM-dd HH:mm:ss")+" : Database: "+$dbname+" checked successfully.")
                        Add-Content -Path $LogFile -Value ($CheckDB_Results.Message)

                        Invoke-Sqlcmd -Query ("DROP DATABASE ["+$dbname+"]") -ServerInstance $ServerInstance -Username "uuuu" -Password "******" -Database "master"
                        Get-ChildItem -Path ("D:\Backups\*"+$dbname+".bak") | Remove-Item -Force

                    } 
                    else {
                        $LogMessage = ($CheckDB_Results.TimeGenerated.ToString("yyyy-MM-dd HH:mm:ss")+" **WARNING** : Database: "+$dbname+"   Error message: "+$CheckDB_Results.Message)
                        Add-Content -Path $LogFile -Value $LogMessage
                        Add-Content -Path $ErrorFile -Value $LogMessage
                        $ErrorsFound = $TRUE
                    }
                
                    $LogMessage = "----------------------------------------------------------------------------------------------------"
                    Add-Content -Path $LogFile -Value $LogMessage
                
                }

            } else {
                $LogMessage = ("ERROR: "+$filePath+" not found.")
                Add-Content -Path $LogFile -Value $LogMessage
            }
         }
         if ($ErrorsFound = $TRUE) {
            # send notification
            $cmd = "EXEC msdb.dbo.sp_send_dbmail @profile_name='BackupMonitor', @recipients = 'DIST_DevOps@llamasoft.com', @body = 'The restoration process failed for one or more databases on server "+$ServerInstance+". Check attached file for details and re-do the backups.', @subject = 'Backup ALERT - Restauration error on server "+$ServerInstance+"', @file_attachments='"+$ErrorFile+"' ; "
            Invoke-Sqlcmd -Query $cmd -ServerInstance $ServerInstance -Username "uuuu" -Password "******" -Database "master"
         }
    }
} else {
    Add-Content -Path $LogFile -Value ("File not found. "+$TSQL_restoreFile)
}