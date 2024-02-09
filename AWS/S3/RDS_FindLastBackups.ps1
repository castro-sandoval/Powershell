cls
Set-AWSCredential -AccessKey AKIAQ7FRZQP3ZO7BLDLL -SecretKey 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

$search_dbname="StorageEntities"

$BucketName = "lcp2-sql-backups-us-east-1"
$Last_Full=""
$Last_Full_timestamp=""
$Last_Diff=""
$Last_Diff_timestamp=""

$AllS3Backups = (Get-S3Object -BucketName $BucketName -KeyPrefix "/RDS_DEV/" | Where-Object {$_.Key -like "*"+$search_dbname+".bak" } ) | Select key, @{name="date";expression = {[System.IO.Path]::GetFileNameWithoutExtension($_.key).split("_")[1]} } | Sort-Object date -Descending
foreach ($S3Backup in $AllS3Backups)
{
    $BackupDetails = $S3Backup.key.Split("_")
    
    $Type = $BackupDetails[1].Split("/")[1]
    $TS = $BackupDetails[2]
    if ($Type -eq "FULL")
    {
        if ($Last_Full_timestamp -lt $TS)
        {
            $Last_Full_timestamp=$TS
            $Last_Full=$S3Backup.key
            $FULL_arn = "arn:aws:s3:::"+$BucketName+"/"+$S3Backup.key
            $dbname=$BackupDetails[3]
        }
    }
    else
    {
        if ($Last_Diff_timestamp -lt $TS)
        {
            $Last_Diff_timestamp=$TS
            $Last_Diff=$S3Backup.key
            $Diff_arn = "arn:aws:s3:::"+$BucketName+"/"+$S3Backup.key
        }
    }
}


$Last_Full
"exec msdb.dbo.rds_restore_database @restore_db_name='"+$dbname+"', @s3_arn_to_restore_from='"+$FULL_arn+"', @type='FULL', @with_norecovery=1;"
$Last_Diff
"exec msdb.dbo.rds_restore_database @restore_db_name='"+$dbname+"', @s3_arn_to_restore_from='"+$DIFF_arn+"', @type='DIFFERENTIAL', @with_norecovery=0;"