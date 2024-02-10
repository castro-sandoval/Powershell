Import-Module -Name ("C:\Dataops\bin\DFTlibrary.dll")
$AccessKey = Get-awsaccessKey
$SecretKey = Get-awssecretkey
$sqllogin = Get-sqllogin
$sqlpwrd  = Get-sqlpwrd

$DaysBack = 60 # Number of days prior to CuttOff to check for old files -> delete files on this range
#==================================================================================================================================================
$StartTime = Get-Date

$LogFile = "C:\Dataops\bin\log\RetentionPolicyOldFiles_"+(Get-Date).ToString("yyyyMMddHHmmss")+".log"
Add-Content -Path $LogFile -Value ("Starting at "+(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))

#==================================================================================================================================================

$Server_devices_sql = "SELECT [tag_name], FULL_backup_device_path+'Backups\'+server_name as device_path, RetentionDays_Device FROM [Targets].BackupPolicy WHERE [Policy_active]=1 "
$Server_devices_sql+= " union SELECT [tag_name], DIFF_backup_device_path+'Backups\'+server_name as device_path, RetentionDays_Device FROM [Targets].BackupPolicy WHERE [Policy_active]=1 "
$Server_devices_sql+= " union SELECT [tag_name], TRN_backup_device_path+'Backups\'+server_name as device_path, RetentionDays_Device FROM [Targets].BackupPolicy WHERE [Policy_active]=1 "
$Server_devices_sql+= " ORDER BY 1,2"
$Server_devices = (Invoke-Sqlcmd -ServerInstance "." -Username $sqllogin -Password $sqlpwrd -Database "DATAOPS" -Query $Server_devices_sql)

if ($Server_devices)
{
    Add-Content -Path $LogFile -Value ("===================================================================================================================================")
    Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" - "+$Server_devices.Count.ToString()+" servers found")
    Add-Content -Path $LogFile -Value ("Checking for files up to "+$DaysBack.ToString()+" days older than the retention policy. Delete all files in this range -> out of the retention policy")
    Add-Content -Path $LogFile -Value ("-----------------------------------------------------------------------------------------------------------------------------------")

    $BackupTypes = @('LOG','DIFF','FULL')
    foreach($server in $Server_devices)
    {
        $ServerStartTime = Get-Date
        $Cuttoff = ($StartTime).AddDays(-$server.RetentionDays_Device)
        Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" - Checking server "+$server.tag_name+" : Retention in days = "+$server.RetentionDays_Device.ToString()+" = "+$Cuttoff.ToString("yyyy-MM-dd"))
        Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" - Checking files between "+$Cuttoff.ToString("yyyy-MM-dd HH:mm:ss")+" and "+$Cuttoff.AddDays(-$DaysBack).ToString("yyyy-MM-dd HH:mm:ss")   )
    


        for($BT=0;$BT -le 2;$BT++)
        {
            $DayToCheck=$Cuttoff.AddDays(-1) # start to check files older than $Cuttoff
    
    
            While ($DayToCheck -gt $Cuttoff.AddDays(-$DaysBack))
            {
        
                $FileNameFilter = "\"+ $BackupTypes[$BT]+"_"+$DayToCheck.ToString("yyyyMMdd")+"*.BAK"
                Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" - Searching "+$server.device_path+$FileNameFilter)
                $HasFilesToDelete=(Get-ChildItem -Path ($server.device_path+$FileNameFilter)).Count
                Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" - "+$HasFilesToDelete.ToString()+" files found")

                if ($HasFilesToDelete -gt 0)
                {
                    # delete files
                    Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" - Deleting files")
                    Get-ChildItem -Path ($server.device_path+$FileNameFilter) | Where-Object {($_.CreationTime -lt $Cuttoff)} | Remove-Item -Force
                    Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" - Deletion complete")
                }
                else
                {
                    Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" - No files found")
                }
                # Check day before
                $DayToCheck=$DayToCheck.AddDays(-1)
            }
        }


        #=========================================================================================================================================================================================
        Add-Content -Path $LogFile -Value ("...................................................................................................................................")
        Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" - Duration "+$server.tag_name+" = "+(NEW-TIMESPAN –Start $ServerStartTime –End (Get-Date)).ToString()+" (Hours:Min:Sec.ms)")

        Add-Content -Path $LogFile -Value ("-----------------------------------------------------------------------------------------------------------------------------------")
    }
}
else
{
    Add-Content -Path $LogFile -Value (" ** WARNING ** No servers found in [Targets].BackupPolicy WHERE [Policy_active]=1 ")
}

Add-Content -Path $LogFile -Value ("End of task "+$ServerStartTime.ToString("yyyy-MM-dd HH:mm:ss"))
Add-Content -Path $LogFile -Value ("Total duration = "+(NEW-TIMESPAN –Start $StartTime –End (Get-Date)).ToString()+" (Hours:Min:Sec.ms)")

Add-Content -Path $LogFile -Value ("===================================================================================================================================")
