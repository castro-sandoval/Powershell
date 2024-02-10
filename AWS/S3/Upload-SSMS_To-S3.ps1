
Set-AWSCredential -AccessKey  -SecretKey 

$BulkFolder      = "lcp2-sql-backups-us-east-1/Dataops/"

$FileFolder = "C:\Users\Sandoval.CastroNeto\Downloads\"
$FileName = "SSMS-Setup-ENU.exe"

Write-S3Object -BucketName $BulkFolder -Key $FileName -File ($FileFolder+$FileName)
