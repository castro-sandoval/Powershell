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

#*********************************************************
$BucketName      = "lcp2-sql-backups-us-east-1"
$InstanceName    = $InstanceName.Replace("\","/")
$LogFileName     = "AWS_UploadTMItoS3_"+(Get-Date).ToString("yyyyMMdd_HHmm")+".log"
$LogFileFullName = $BackupDevice+$LogFileName
$keyPrefix       = "/"+$InstanceName+"/Backups/Week_"+(LastMondayyyyyMMdd)
$BulkFolder      = $BucketName+$keyPrefix


Add-Content -Path $LogFileFullName -Value ("BackupDevice ="+$BackupDevice)
Add-Content -Path $LogFileFullName -Value ("InstanceName ="+$InstanceName)
Add-Content -Path $LogFileFullName -Value ("keyPrefix    ="+$keyPrefix)
Add-Content -Path $LogFileFullName -Value ("BulkFolder   ="+$BulkFolder)

#=========================================================================================================================================================================
$filesToCopy = (Get-ChildItem -Path ($BackupDevice+"FULL_*_MasterQueue_*.bak") )

Add-Content -Path $LogFileFullName -Value ($filesToCopy.Count.ToString()+" TMI files to upload to S3 bucket.")
foreach ($file in $filesToCopy)
{
    $filekey = ($keyPrefix.Substring(1,$keyPrefix.Length-1)+"/"+$file.Name)
    
    #Check if file is already there before copying
    if ((Get-S3Object -BucketName $BucketName -KeyPrefix $keyPrefix | Where-Object {$_.key -eq $filekey }) ) {
        Add-Content -Path $LogFileFullName -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" File already exists in S3 "+$BulkFolder+"  -> "+$file.FullName+" "+$file.CreationTime.ToString("yyyy-MM-dd HH:mm"))
    } else {
        Add-Content -Path $LogFileFullName -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" Uploading "+$file.FullName+"  TO  "+$BulkFolder+"  -> File creation: "+$file.CreationTime.ToString("yyyy-MM-dd HH:mm"))
        Write-S3Object -BucketName $BulkFolder -Key $file.Name -File $file.FullName
    }
}
Add-Content -Path $LogFileFullName -Value ("=========================================================================================================================================================================")
Add-Content -Path $LogFileFullName -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" Finished")
Add-Content -Path $LogFileFullName -Value ("=========================================================================================================================================================================")
Add-Content -Path $LogFileFullName -Value ("")