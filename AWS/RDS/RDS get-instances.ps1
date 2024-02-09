cls
$region = "us-east-1"
$ARN="arn:aws:rds:us-east-1:066944861175:db:platform-sql-staging"
Get-RDSDBInstance -DBInstanceIdentifier $ARN -AccessKey  -SecretKey -Region $region 