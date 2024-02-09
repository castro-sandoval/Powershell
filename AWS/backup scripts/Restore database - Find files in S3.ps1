Clear-Host
$server_name="IP-0AE8798D"
$dbname="k2logs"
$Region="us-east-1"

Set-AWSCredentials -AccessKey  -SecretKey


#========================================================================================================
if ((Get-date).DayOfWeek.value__ -gt 0)
{
    $ThisWeekMonday = (Get-date).AddDays(1- (Get-date).DayOfWeek.value__)
} else {
    $ThisWeekMonday = (Get-date).AddDays(-6)
}

#======== Find FULL backup file ============
$Prefix = "/"+$server_name.Replace("\","/")+"/Backups/Week_"+$ThisWeekMonday.ToString("yyyyMMdd")+"/"
$FULL_File = Get-S3Object -BucketName lcp2-sql-backups-us-east-1 -Keyprefix $Prefix -Region us-east-1 | Where-Object {($_.key -like "*"+$dbname+".bak") -and ($_.key -like "*FULL_"+$ThisWeekMonday.ToString("yyyyMMdd")+"*")} 

#======== Find DIFF backup file ============
$DIFF_File = $FULL_File
$files = Get-S3Object -BucketName lcp2-sql-backups-us-east-1 -Keyprefix $Prefix -Region us-east-1 | Where-Object {($_.key -like "*"+$dbname+".bak") -and ($_.key -like "*DIFF_*.bak")} 
foreach ($file in $files)
{
    if ($file.LastModified -gt $DIFF_File.LastModified)
    {
        $DIFF_File = $file
    }
}

#======== Find LOG backup file ============
$Prefix = "/"+$server_name.Replace("\","/")+"/TransacLogs/Week_"+$ThisWeekMonday.ToString("yyyyMMdd")+"/"

$LOG_File = $DIFF_File
$files = Get-S3Object -BucketName lcp2-sql-backups-us-east-1 -Keyprefix $Prefix -Region us-east-1 | Where-Object {($_.key -like "*"+$dbname+".bak") -and ($_.key -like "*LOG_*.bak")} 
foreach ($file in $files)
{
    if ($file.LastModified -gt $LOG_File.LastModified)
    {
        $LOG_File = $file
    }
}

#************************************** results *****************************
$FULL_File.key
if ($FULL_File.key -ne $DIFF_File.key)
{
    $DIFF_File.key
}
if ($DIFF_File.key -ne $LOG_File.key)
{
    $LOG_File.key
}


