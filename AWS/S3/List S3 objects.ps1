cls
$AccessKey='********'
$SecretKey='*************'

Set-AWSCredential -AccessKey $AccessKey -SecretKey $SecretKey


$AllS3Backups = (Get-S3Object -BucketName bucketname -KeyPrefix "/RDS_DEV/" | Where-Object {$_.Key -like "*StorageEntities.bak" } ) | Select key, @{name="date";expression = {[System.IO.Path]::GetFileNameWithoutExtension($_.key).split("_")[1]} } | Sort-Object date -Descending
foreach ($AllS3Backup in $AllS3Backups)
{
    "arn:aws:s3:::"+$AllS3Backup.key
}

