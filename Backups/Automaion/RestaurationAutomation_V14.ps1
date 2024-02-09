
$ServerInstance   = (Get-ChildItem -path env:computername | select -Property Value -Verbose).Value
$TSQL_restoreFile = "D:\Backups\restore.sql"
$LogFile          = "D:\Backups\RestorationTestProcess.log"
$ErrorFile        = "D:\Backups\RestorationTestProcessErrors.log"
$VerboseOutput    = "D:\Backups\verbose.out"
$DIST_DevOps      = "DIST_DevOps@llamasoft.com"

if (Test-Path -Path $TSQL_restoreFile) {
    $ErrorsFound = $FALSE
    $file = (Get-Content -Path $TSQL_restoreFile)

    if (Test-Path -Path $LogFile) {
        Remove-Item -Path $LogFile -Force
    }
    if (Test-Path -Path $ErrorFile) {
        Remove-Item -Path $ErrorFile -Force
    }
    Add-Content -Path $ErrorFile -Value ("Initializing file at "+(Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff"))

    foreach($line in $file) {
        if ($line.Contains("RESTORE DATABASE")) {
            $line=$line.TrimEnd()
            
            $dbName= $line.Substring($line.IndexOf("RESTORE DATABASE")+18, $line.IndexOf("]  FROM DISK")-$line.IndexOf("RESTORE DATABASE")-18)
            if ($dbName.Contains("?")) {  # Check database name with special characters not exported correctly by sqlcmd.exe
                $LogMessage = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | Invalid database name: "+$dbName
                Add-Content -Path $LogFile -Value $LogMessage
            }
            else {
                $filePath = $line.Substring($line.IndexOf("]  FROM DISK")+15, $line.IndexOf("  WITH FILE")-$line.IndexOf("]  FROM DISK")-16)
                $StrIndex = $filePath.IndexOf("FULL_")
                if ($StrIndex -lt 0) {
                    $StrIndex = $filePath.IndexOf("DIFF_")
                }
                $filePath = "d:\Backups\"+$filePath.Substring($StrIndex, $filePath.Length-$StrIndex)
                $fileName = $filePath.Substring($filePath.IndexOf("d:\Backups\")+11, $filePath.Length-$filePath.IndexOf("d:\Backups\")-11)
                $filename = Split-Path ($filename) -leaf
            
                $LogMessage = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | Checking file "+$filename+" from restore.sql file"
                Add-Content -Path $LogFile -Value $LogMessage

                $filePath = "d:\Backups\"+$fileName
                $lineEnd=$line.Substring($line.IndexOf(" WITH FILE = ")+15, $line.Length-$line.IndexOf(" WITH FILE = ")-15)
                $Prefix = ("/"+$line.Substring(3, $line.IndexOf("*/")-4)+"/Backups/Week_"+(Get-Date).AddDays(-(Get-Date).DayOfWeek.value__ + 1).AddHours(-((Get-Date).Hour)).AddMinutes(-((Get-Date).Minute)).ToString("yyyyMMdd")+"/")
            
                $line=$line.Substring($line.IndexOf("*/")+2, $line.Length-$line.IndexOf("*/")-2)

                # check if it is a named instance or not to fix the file path
                if ($line.IndexOf(":\Backups\"+$fileName) -lt 0) 
                {
                    #Remove named instance name from path
                    $StrIndex = $line.IndexOf("\FULL_")
                    if ($StrIndex -lt 0) {
                        $StrIndex = $line.IndexOf("\DIFF_")
                    }
                    $lineBegin=$line
                    $line= $line.Substring($StrIndex, $line.Length-$StrIndex)
                    $StrIndex=($lineBegin.IndexOf(":\Backups\")+(":\Backups\").Length)-1
                    $line=$lineBegin.SubString(0,$StrIndex)+$line
                }

                #============ Download file from S3 to local D:\Backups folder ================
                $LogMessage = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | Checking S3 for file "+$Prefix+$fileName
                Add-Content -Path $LogFile -Value $LogMessage
            
            
                $fileKey = (Get-S3Object -BucketName lcp2-sql-backups-us-east-1 -KeyPrefix $Prefix | Where-Object {($_.Key -like ("*/"+$filename) ) }).key

                if ($fileKey.Length -le 0) {
                    $LogMessage = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | ERROR: fileKey=Get-S3Object key = "+$Prefix+$fileName+" not found!"
                    Add-Content -Path $LogFile -Value $LogMessage
                }

                if (Test-Path -Path ("D:\Backups\"+$fileName)) {
                    Remove-Item -Path ("D:\Backups\"+$fileName) -Force
                }

                if ($fileKey.Length -gt 0) {
                    Read-S3Object -BucketName lcp2-sql-backups-us-east-1 -Key $fileKey -File ("D:\Backups\"+$fileName)
                } 
                else {
                    $LogMessage = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | ERROR: not able to download "+$Prefix+$fileKey
                    Add-Content -Path $LogFile -Value $LogMessage
                }
            
                $LogMessage = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | Downloading "+$fileKey
                Add-Content -Path $LogFile -Value $LogMessage
                
                if (Test-Path -Path $filePath) {
                    $line=$line.Substring(0, $line.IndexOf($lineEnd))
                    $sqlcmd= "restore filelistonly FROM DISK=N'"+$filePath+"'"
                    $sqlFiles = (Invoke-Sqlcmd -Query $sqlcmd -ServerInstance $ServerInstance -Username "uuu" -Password "******" -Database "master")
           
                    # Extract internal file structure from backup file to build the restore local command
                    foreach($sqlFile in $sqlFiles) {
                        $sqlFileName = Split-Path ($sqlFile.PhysicalName) -leaf
                        $line=$line+(" move '"+$sqlFile.LogicalName+"' TO 'D:\Backups\"+$sqlFileName+"', ")
                    }           
                    $sqlRestorecmd = ($line+$lineEnd)
                    Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | Running "+$sqlRestorecmd)
                    Invoke-Sqlcmd -Query $sqlRestorecmd -ServerInstance $ServerInstance -Username "uuu" -Password "*****" -Database "master" -QueryTimeout 2400
                    #============= Test the database ===============
                    if ($sqlRestorecmd.Contains(" RECOVERY")) {
                        $checkdbCmd = "DBCC CHECKDB (["+$dbname+"], NOINDEX) WITH PHYSICAL_ONLY"
                        Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | Running "+$checkdbCmd)

                        if (Test-Path -Path $VerboseOutput) {
                            Remove-Item -Path $VerboseOutput -Force
                        }
                        #Add-Content -Path $VerboseOutput -Value $checkdbCmd
                        Invoke-Sqlcmd -Query $checkdbCmd -ServerInstance $ServerInstance -Username "uuu" -Password "*****" -Database "master" -Verbose 4> $VerboseOutput
                        $CheckDB_Results = Get-Content -Path $VerboseOutput
                        if (Test-Path -Path $VerboseOutput) {
                            Remove-Item -Path $VerboseOutput -Force
                        }

                        # Verify CHECKDB output
                        if ($CheckDB_Results.Length -ge 4) {
                            # Format CheckDB_Results
                            if ($CheckDB_Results[3].IndexOf(". If DBCC printed error messages") -gt 0) {
                                $CheckDB_Msg = ($CheckDB_Results[2]+" "+$CheckDB_Results[3].Substring(0, $CheckDB_Results[3].IndexOf(". If DBCC printed error messages")))
                            }
                            else 
                            {
                                $CheckDB_Msg = ($CheckDB_Results[2]+" "+$CheckDB_Results[3])
                            }
                        
                            # Validade CheckDB_Results
                            if ($CheckDB_Msg.IndexOf("CHECKDB found 0 allocation errors and 0 consistency errors in database") -lt 0) {
                                $ErrorsFound = $TRUE
                                for($a=0;$a -lt $CheckDB_Results.Count;$a++) {
                                    Add-Content -Path $ErrorFile -Value ($CheckDB_Results[$a])
                                }
                            } # if ($CheckDB_Msg.IndexOf("CHECKDB found 0 allocation errors and 0 consistency errors in database") -lt 0)
                            else
                            {
                                Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | "+$CheckDB_Msg)
                            }

                        } # if ($CheckDB_Results.Length -ge 4)
                        else
                        {
                            Add-Content -Path $ErrorFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | CHECKDB did not return expected message related to database "+$dbname+" on "+$ServerInstance)
                            foreach($line in $CheckDB_Results) {
                                Add-Content -Path $ErrorFile -Value $line
                            }
                            $ErrorsFound = $TRUE
                        }

                        Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | Running DROP DATABASE ["+$dbname+"]")
                        Invoke-Sqlcmd -Query ("DROP DATABASE ["+$dbname+"]") -ServerInstance $ServerInstance -Username "uuu" -Password "*****" -Database "master"
                    
                        Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | Removing "+"D:\Backups\*"+$dbname+".bak")
                        Get-ChildItem -Path ("D:\Backups\*"+$dbname+".bak") | Remove-Item -Force

                        $LogMessage = "----------------------------------------------------------------------------------------------------"
                        Add-Content -Path $LogFile -Value $LogMessage


                    } #if ($sqlRestorecmd.Contains(" RECOVERY")) {
                
                } else {
                    $LogMessage = ("ERROR: "+$filePath+" not found.")
                    Add-Content -Path $LogFile -Value $LogMessage                
                } #if (Test-Path -Path $filePath) {
            } # if ($dbName.Contains("?")) {  # Check database name with special characters not exported correctly by sqlcmd.exe

         } #if ($line.Contains("RESTORE DATABASE")) {
    } # foreach file


    if ($ErrorsFound -eq $TRUE) {
        # send notification
        $cmd = "EXEC msdb.dbo.sp_send_dbmail @profile_name='BackupMonitor', @recipients = '"+$DIST_DevOps+"', @body = 'The restoration process failed for one or more databases on server "+$ServerInstance+". Check D:\Backups\RestorationTestProcess.log file on the master server MSX for details and re-do the backups that failed.', @subject = 'Backup ALERT - Restauration test found errors on server "+$ServerInstance+"', @file_attachments='"+$ErrorFile+"'"
        Invoke-Sqlcmd -Query $cmd -ServerInstance $ServerInstance -Username "uuu" -Password "*****" -Database "master"
    }


} #if (Test-Path -Path $TSQL_restoreFile) {
else {
    Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | File not found on master's local drive: "+$TSQL_restoreFile)
    $cmd = "EXEC msdb.dbo.sp_send_dbmail @profile_name='BackupMonitor', @recipients = '"+$DIST_DevOps+"', @body = 'The restoration process failed on the master server MSX. Check attached log file.', @subject = 'Backup ALERT - Restauration test found errors on server "+$ServerInstance+"', @file_attachments='"+$LogFile+"'"
}


