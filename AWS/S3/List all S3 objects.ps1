

Set-AWSCredential -AccessKey AKIAIK6ODY2F7MFNUVBQ -SecretKey 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


clear-host



#---- searching Backups
$prefix = "/IP-0AE87D14/PLATFORM/Backups/Week_20210531/*6f770248-8a71-4487-9f7e-f633452cb6a9.bak"

(Get-S3Object -BucketName lcp2-sql-backups-us-east-1 -Keyprefix $prefix).key


