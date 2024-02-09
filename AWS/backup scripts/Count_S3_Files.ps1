<#
tag_name	tag_IP	server_id	Server_name
us-east-1	10.232.124.248	2	IP-0AE87CF8
us-east-1	10.232.124.49	6	IP-0AE87C31\PLATFORM
us-east-1	10.232.121.79	15	IP-0AE8794F-STA
us-east-1	10.232.123.133,50000	23	MON-SQL2016
us-east-1	10.232.125.117	3	IP-0AE87D75
us-east-1	10.232.125.20	7	IP-0AE87D14\PLATFORM
us-east-1	10.232.121.141	14	IP-0AE8798D
#>
$server_name = "IP-0AE87D14\PLATFORM"

$LogFile = "c:\temp\Count_s3_files.txt"
if (Test-Path -Path $LogFile)
{
    Remove-Item -Path $LogFile
}

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
$LogPrefix = "/"+$server_name.Replace("\","/")+"/TransacLogs/Week_"+$ThisWeekMonday.ToString("yyyyMMdd")+"/"

Add-Content -Path $LogFile -Value ("Start at "+(Get-Date).ToString("yyyy-MM-dd hh:mm:ss"))
Add-Content -Path $LogFile -Value ("Total of "+(Get-S3Object -BucketName lcp2-sql-backups-us-east-1 -Keyprefix $Prefix -Region us-east-1).Count.ToString()+" found in "+$Prefix)
Add-Content -Path $LogFile -Value ("FULL_ = "+(Get-S3Object -BucketName lcp2-sql-backups-us-east-1 -Keyprefix $Prefix -Region us-east-1 | Where-Object {($_.key -like "*FULL_"+$ThisWeekMonday.ToString("yyyyMMdd")+"*")}).Count.ToString())
Add-Content -Path $LogFile -Value ("DIFF_ = "+(Get-S3Object -BucketName lcp2-sql-backups-us-east-1 -Keyprefix $Prefix -Region us-east-1 | Where-Object {($_.key -like "*DIFF_"+$ThisWeekMonday.ToString("yyyyMMdd")+"*")}).Count.ToString())
Add-Content -Path $LogFile -Value ("Total of "+(Get-S3Object -BucketName lcp2-sql-backups-us-east-1 -Keyprefix $LogPrefix -Region us-east-1).Count.ToString()+" found in "+$LogPrefix)
Add-Content -Path $LogFile -Value ("LOG_  = "+(Get-S3Object -BucketName lcp2-sql-backups-us-east-1 -Keyprefix $LogPrefix -Region us-east-1 | Where-Object {($_.key -like "*LOG_"+$ThisWeekMonday.ToString("yyyyMMdd")+"*")}).Count.ToString())
Add-Content -Path $LogFile -Value ""

Get-Content -Path $LogFile | Write-Host
