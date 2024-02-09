
# Remove backup files that does not belong to the week

# Remove files older than the week folder
$objs = (Get-S3Object -BucketName lcp2-sql-backups-us-east-1 -KeyPrefix / | Where-Object ({($_.key.Substring($_.key.IndexOf("Week_")+5,8) -gt $_.key.Substring($_.key.IndexOf("Week_")+19,8))})).key
foreach($key in $objs) {
    Remove-S3Object -BucketName lcp2-sql-backups-us-east-1 -Key $key -Force
}




