Set-AWSCredentials -AccessKey  -SecretKey 

$key_to_download = "I-0F587E7A4C125/Backups/Week_20210426/FULL_20210426060000_e5381ff2-2ead-4318-b496-16735ec5c527.bak"
$file="I:\Backups\FULL_20210426060000_e5381ff2-2ead-4318-b496-16735ec5c527.bak"

Read-S3Object -BucketName "lcp2-sql-backups-us-east-1" -Key $key_to_download -File $file

$key_to_download = "I-0F587E7A4C125/Backups/Week_20210426/DIFF_20210429060102_e5381ff2-2ead-4318-b496-16735ec5c527.bak"
$file="I:\Backups\DIFF_20210429060102_e5381ff2-2ead-4318-b496-16735ec5c527.bak"

Read-S3Object -BucketName "lcp2-sql-backups-us-east-1" -Key $key_to_download -File $file




