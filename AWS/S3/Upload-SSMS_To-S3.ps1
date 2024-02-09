
Set-AWSCredential -AccessKey AKIAQ7FRZQP3ZO7BLDLL -SecretKey 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

$BulkFolder      = "lcp2-sql-backups-us-east-1/Dataops/"

$FileFolder = "C:\Users\Sandoval.CastroNeto\Downloads\"
$FileName = "SSMS-Setup-ENU.exe"

Write-S3Object -BucketName $BulkFolder -Key $FileName -File ($FileFolder+$FileName)
