cls
Set-AWSCredential -AccessKey  -SecretKey

$BucketName="platform-sql-backups-prod"
$key="PermissionEntities_ 201905020833.BAK"
$file = "C:\Databases\Download\PermissionEntities_ 201905020833.BAK"


Read-S3Object -BucketName $BucketName -Key $key -File $file