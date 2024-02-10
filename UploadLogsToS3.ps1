Param ([Parameter(Mandatory)]$BackupDevice, [Parameter(Mandatory)]$InstanceName)


#*********************************************************
function LastMondayyyyyMMdd {
    if ((Get-date).DayOfWeek.value__ -gt 0)
    {
        $ThisWeekMonday = (Get-date).AddDays(1- (Get-date).DayOfWeek.value__)
    } else {
        $ThisWeekMonday = (Get-date).AddDays(-6)
    }
    return $ThisWeekMonday.ToString("yyyyMMdd")   
}

#******************** Copy new backups to S3 ***************************
#************* Create a folder in a S3 buket ********************************************
$LogFileName     = "AWS_S3LOG_"+(Get-Date).ToString("yyyyMMdd_HHmm")+".log"
$LogFileFullName = ($BackupDevice+$LogFileName)
$BulkFolder = "lcp2-sql-backups-us-east-1/"+$InstanceName.Replace("\","/")+"/TransacLogs/Week_"+(LastMondayyyyyMMdd)

#*********************************************************
Add-Content -Path $LogFileFullName -Value ("BackupDevice ="+$BackupDevice)
Add-Content -Path $LogFileFullName -Value ("InstanceName ="+$InstanceName)
Add-Content -Path $LogFileFullName -Value ("keyPrefix    ="+$keyPrefix)
Add-Content -Path $LogFileFullName -Value ("BulkFolder   ="+$BulkFolder)
#*********************************************************

$filesToCopy = (Get-ChildItem ($BackupDevice+"LOG_*.bak") | Where-Object {($_.CreationTime -gt ((Get-Date).AddHours(-2)))})
Add-Content -Path $LogFileFullName -Value ($filesToCopy.Count.ToString()+" files to upload to S3 bucket.")
foreach ($file in $filesToCopy)
{
    Add-Content -Path $LogFileFullName -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" Uploading "+$file.FullName+"  TO  "+$BulkFolder+"  -> File creation: "+$file.CreationTime.ToString("yyyy-MM-dd HH:mm"))
    Write-S3Object -BucketName $BulkFolder -Key $file.Name -File $file.FullName
}
Write-S3Object -BucketName $BulkFolder -Key $LogFileName -File $LogFileFullName
Add-Content -Path $LogFileFullName -Value ("=========================================================================================================================================================================")
Add-Content -Path $LogFileFullName -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" Finished")
Add-Content -Path $LogFileFullName -Value ("=========================================================================================================================================================================")
Add-Content -Path $LogFileFullName -Value ("")