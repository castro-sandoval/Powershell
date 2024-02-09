

#******************** List files from a S3 Bucket ***************************
cls
(Get-S3Object -BucketName lcp2-sql-backups-us-east-1 -KeyPrefix /bin/  -AccessKey AKIAIK6ODY2F7MFNUVBQ -SecretKey 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).Key

Set-AWSCredential -AccessKey AKIAIK6ODY2F7MFNUVBQ -SecretKey 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
(Get-S3Object  -Bucket "lcp2-sql-backups-us-east-1" -KeyPrefix "/Bin/").Key


#******************** Download file from S3 Bucket ***************************
$DestFolder = "C:\Install"
$FileName   = "SSMS-Setup-ENU (18.4).exe"
if (!(Test-Path -Path $DestFolder)) {
    New-Item -Path $DestFolder -ItemType Directory
}
Read-S3Object -BucketName lcp2-sql-backups-us-east-1 -Key ("Dataops/"+$FileName) -File ($DestFolder+"\"+$FileName)  -AccessKey AKIAIK6ODY2F7MFNUVBQ -SecretKey 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



#******************** Upload file To Dataops S3 Bucket ***************************

$Filepath   = "C:\Install\SQLServer\"
$FileName   = "en_sql_server_2016_standard_with_service_pack_2_x64_dvd_12124191.iso"
Write-S3Object -BucketName lcp2-sql-backups-us-east-1 -Key ("Dataops/"+$FileName) -File ($Filepath+"\"+$FileName)  -AccessKey AKIAIK6ODY2F7MFNUVBQ -SecretKey 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



