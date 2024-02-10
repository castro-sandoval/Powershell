param ([Parameter(Mandatory)] $instanceName)
$Username="*****" 
$Password="*******"

$PercentageOfMDF = 0.5
$LDFPercentOfFULLMDF = 0.2

    $query = "SELECT SERVERPROPERTY('InstanceDefaultLogPath') as LogFolder"
    $logFolder = (Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query).ItemArray[0]
    $BaseFolder = $logFolder.Substring(0,1)+":\LLamasoftScheduledTasks"
    $logFile = $BaseFolder+"\ShrinkOperation_"+$instanceName.Replace("\","-")+"_" +(Get-Date).ToString("yyyyMMddHHmmss")+".log"

    if (!(Test-Path -Path $BaseFolder)) 
    {
        New-Item -Path $BaseFolder -ItemType Directory -Force
    }



    #$query = "select replace(physical_name, '\mydevicefile.bak', '\') as BackupFolder from sys.backup_devices where name='LocalBackup'"
    $query = "SELECT [FULL_backup_device_path]+'Backups\'+@@SERVERNAME+'\' as BackupFolder FROM [msdb].[DataOps].[BackupPolicy] WHERE [server_name]=@@SERVERNAME and [Policy_active]=1"
    $FULLBackupFolder = (Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query).BackupFolder
    Add-Content -Path $logFile -Value ("FULLBackupFolder = "+$FULLBackupFolder)
    If ($FULLBackupFolder -eq "") 
    {
        Add-Content -Path $logFile -Value ("*** ERROR *** Invalid FULLBackupFolder : "+$query)
    }

    $query = "SELECT [TRN_backup_device_path]+'Backups\'+@@SERVERNAME+'\' as BackupFolder FROM [msdb].[DataOps].[BackupPolicy] WHERE [server_name]=@@SERVERNAME and [Policy_active]=1"
    $LOGBackupFolder = (Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query).BackupFolder
    Add-Content -Path $logFile -Value ("LOGBackupFolder = "+$LOGBackupFolder) 
    If ($LOGBackupFolder="") 
    {
        Add-Content -Path $logFile -Value ("*** ERROR *** Invalid LOGBackupFolder : "+$query)
    }

    Add-Content -Path $logFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" SHRINK operation - SQL Instance: "+$instanceName+"   Instance Log folder: "+$logFolder )
    Add-Content -Path $logFile -Value "======================================================================================================================"



    $PurgeDate = (Get-date).AddDays(-10)
    Add-Content -Path $logFile -Value ("Deleting log files older than "+$PurgeDate.ToString())
    Get-ChildItem -Path ($BaseFolder+"\ShrinkOperation_*.log") | Where-Object {($_.CreationTimeUtc -lt $PurgeDate)} | Remove-Item -Force
    Add-Content -Path $logFile -Value ""

    <#=======================================================================================================================
        SHRINK files - only ONLINE and MULTIUSER databases
    =======================================================================================================================#>
    Add-Content -Path $logFile -Value ("================================= Selecting databases to execute Shrink ===============================================")
    #$query = "select name, recovery_model_desc as recovery_model from sys.databases where database_id>4 and [state]=0 and [user_access]=0 and ([name] not like 'MasterQueue_%')"
    $query = "SELECT D.[name], D.recovery_model_desc as recovery_model, SUM(F.size)*8.0/1024.0 AS [TotalMB] "
    $query +="FROM sys.databases D JOIN sys.master_files F ON D.database_id=F.database_id "
    $query +="where D.database_id>4 and D.[state]=0 and D.[user_access]=0 and (D.[name] not like 'MasterQueue_%') "
    $query +="GROUP BY D.[name], D.recovery_model_desc "
    $query +="ORDER BY [TotalMB] desc "

    Add-Content -Path $logFile -Value $query 
    Add-Content -Path $logFile -Value ("=======================================================================================================================")
    $Databases = (Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query)
    Add-Content -Path $logFile -Value ($Databases.Count.ToString()+" found.")
    foreach ($Database in $Databases) 
    {
        $TransogFile=""
        Add-Content -Path $logFile -Value ""
        Add-Content -Path $logFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" Checking database ["+$Database.name+"]     Recovery model: "+$Database.recovery_model.ToString())

        #============= DATA file ======================
        $query = "select filename, sum(size*8.0/1024.0) as sizeMB from ["+$Database.name+"].sys.sysfiles where groupid=1 group by filename"
        $MDFSize= (Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query)
        Add-Content -Path $logFile -Value ("     MDF size: "+$MDFSize.sizeMB.ToString()+" MB ("+($PercentageOfMDF*100).ToString()+"% = "+($MDFSize.sizeMB*$PercentageOfMDF).ToString()+" MB)    Path: "+$MDFSize.filename)

        #============= LOG file ======================
        $query = "select top 1 name, filename, size*8.0/1024.0 as 'sizeMB' from ["+$Database.name+"].sys.sysfiles where groupid=0"
        $TransogFile= (Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query)        
        $LastWriteTime = (Get-ChildItem -Path $TransogFile.filename.Replace("/","\") ).LastWriteTime
        Add-Content -Path $logFile -Value ("     LOG Logical name: "+$TransogFile.name+" = "+$TransogFile.filename+"         Size: "+$TransogFile.sizeMB.ToString()+" MB         Last Write Time: "+$LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss"))


        #---- Check if log file is eligible
        if ( ($LastWriteTime -lt (Get-Date).AddHours(-1)) -and (($TransogFile.sizeMB -gt $MDFSize.sizeMB) -or ($TransogFile.sizeMB -gt ($MDFSize.sizeMB*$PercentageOfMDF)))  ) 
        {

            if ($Database.recovery_model -eq "SIMPLE")
            {
                if ($TransogFile.sizeMB -ge ($MDFSize.sizeMB * $PercentageOfMDF))
                {
                    #$query = "USE ["+$Database.name+"]; DBCC SHRINKFILE (N'"+$TransogFile.name+"' , 0, TRUNCATEONLY)"
                    $query = "DBCC SHRINKFILE (N'"+$TransogFile.name+"' , 64)"
                    Add-Content -Path $logFile -Value ("     "+$query)
                    $result = Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database ($Database.name) -Query $query

                    $query = "DBCC SHRINKFILE (N'"+$TransogFile.name+"' , 0, TRUNCATEONLY)"
                    Add-Content -Path $logFile -Value ("     "+$query)
                    $result = Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database ($Database.name) -Query $query
                    Add-Content -Path $logFile -Value ("     CurrentSize="+(($result.CurrentSize)*8.0/1024.0).ToString()+"MB")

                    $query = "select top 1 name, filename, size*8.0/1024.0 as 'sizeMB' from ["+$Database.name+"].sys.sysfiles where groupid=0"
                    $TransogFile= (Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query)
                    Add-Content -Path $logFile -Value ("     Size after shrink (SIMPLE): "+$TransogFile.sizeMB.ToString()+" MB     Path: "+$TransogFile.filename)
                }
                else
                {
                    Add-Content -Path $logFile -Value ("     SIMPLE recovery model size < "+($PercentageOfMDF*100).ToString()+"% of the MDF file size. It's ok. Not shrinking.")
                }
            }
            else
            {
                
                if (($TransogFile.sizeMB -gt ($MDFSize.sizeMB * $PercentageOfMDF)) -or ($TransogFile.sizeMB -gt 500000))
                {
                    
                    # Last full backup
                    $query = "select MAX(backup_start_date) as lastFullBak from msdb.dbo.backupset where [type]='D' and [database_name]='"+$Database.name+"'"
                    Add-Content -Path $logFile -Value ("     "+$query)
                    $LastFullBak = Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query -QueryTimeout 0
                    Add-Content -Path $logFile -Value ("     Last full backup: "+$LastFullBak.lastFullBak.ToString("yyyy-MM-dd HH:mm:ss"))

                    if ($LastFullBak.lastFullBak.ToString() -ne "")
                    {
                        # Perform transaction log backup
                        $query = "BACKUP LOG ["+$Database.name+"] TO  DISK = N'"+$FULLBackupFolder+"LOG_"+(Get-Date).ToString("yyyyMMddHHmmss")+"_"+$Database.name+".bak' WITH NOFORMAT, NOINIT, SKIP, COMPRESSION, STATS=50"
                        Add-Content -Path $logFile -Value ("     "+$query)
                        Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query -QueryTimeout 0
                    }
                    else
                    {
                        Add-Content -Path $logFile -Value ("     Last full backup not found. Executing new FULL Backup")
                        # New FULL backup 
                        # Add 1 second to the time stamp to set correct time sequence from previous LOG backup and following FULL backup avoiding same time
                        $query = "BACKUP DATABASE ["+$Database.name+"] TO  DISK = N'"+$FULLBackupFolder+"FULL_"+((Get-Date).AddSeconds(1)).ToString("yyyyMMddHHmmss")+"_"+$Database.name+".bak' WITH INIT,  NAME = N'"+$Database.name+"', DESCRIPTION='New full backup before DBCC SHRINKFILE log', COMPRESSION, STATS = 25"
                        Add-Content -Path $logFile -Value ("     "+$query)
                        Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query -QueryTimeout 600
                    }

                    $size= ([Math]::Round(($MDFSize.sizeMB * $LDFPercentOfFULLMDF), 0))
                    if ($size -eq 0) 
                    {
                        $size=64
                    }
                    else
                    {
                        if ($size -gt 100000) 
                        {
                            $size=100000 # 100GB
                        }
                    }

                    Add-Content -Path $logFile -Value ("     Log file target size: "+$size.ToString()+" MB ("+($LDFPercentOfFULLMDF*100).ToString()+"% of MDF or up to 100GB max)")
                    $query = "USE ["+$Database.name+"]; ALTER DATABASE ["+$Database.name+"] SET RECOVERY SIMPLE WITH NO_WAIT; DBCC SHRINKFILE ('"+$TransogFile.name+"', "+$size.ToString()+")"
                    Add-Content -Path $logFile -Value ("     "+$query)
                    Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query | Out-Null
                
                    # return the recovery model to the original value
                    $query = "USE ["+$Database.name+"]; ALTER DATABASE ["+$Database.name+"] SET RECOVERY "+$Database.recovery_model
                    Add-Content -Path $logFile -Value ("     "+$query)
                    Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query

                
                    # New FULL backup to avoid PSEUDO-SIMPLE recovery
                    Add-Content -Path $logFile -Value ("     Perform new FULL backup to avoid PSEUDO-SIMPLE recovery failure to "+$FULLBackupFolder)

                    # Add 1 second to the time stamp to set correct time sequence from previous LOG backup and following FULL backup avoiding same time
                    $query = "BACKUP DATABASE ["+$Database.name+"] TO  DISK = N'"+$FULLBackupFolder+"FULL_"+((Get-Date).AddSeconds(1)).ToString("yyyyMMddHHmmss")+"_"+$Database.name+".bak' WITH INIT,  NAME = N'"+$Database.name+"', DESCRIPTION='New full backup required after DBCC SHRINKFILE log', COMPRESSION, STATS = 25"
                    Add-Content -Path $logFile -Value ("     "+$query)
                    Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query


                    $query = "select top 1 name, filename, size*8.0/1024.0 as 'sizeMB' from ["+$Database.name+"].sys.sysfiles where groupid=0"
                    $TransogFile= (Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query)
                    Add-Content -Path $logFile -Value ("     Size after shrink (FULL): "+$TransogFile.sizeMB.ToString()+" MB     Path: "+$TransogFile.filename)


                } # if ($TransogFile.sizeMB -gt ($MDFSize * 0.8))
                else
                {
                    Add-Content -Path $logFile -Value ("     FULL recovery model size < "+($PercentageOfMDF*100).ToString()+"% of the MDF file size and <500GB. It's ok. Not shrinking.")
                }
            }


        } 
        else 
        {
            Add-Content -Path $logFile -Value ("     The file is in use recently and it is not eligible for shrinking: Last Write Time: "+$LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")+"  OR size<"+$MDFSize.sizeMB.ToString()+" MB (Current size: "+$TransogFile.sizeMB.ToString()+" MB) OR size< "+($PercentageOfMDF*100).ToString()+"% of MDF")
        }
    }
    Add-Content -Path $logFile -Value "======================================================================================================================"
    Add-Content -Path $logFile -Value ""
    Add-Content -Path $logFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" SHRINK operation finished.")
