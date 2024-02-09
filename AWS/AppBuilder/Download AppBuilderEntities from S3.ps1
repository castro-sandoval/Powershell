
Set-AWSCredentials -AccessKey  -SecretKey 


$File   = "FULL_20200804122500_AssetEntities.bak"

$Folder = "C:\Databases\Backup\"
$BulkFolder      = "lcp2-sql-backups-us-east-1/RDS_DEV"


#-------------- download backups ----------
Read-S3Object -BucketName $BulkFolder -Key $File -File ($Folder+$File)

