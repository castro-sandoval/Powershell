<#========================================================================================================
Given the database name and the server_name
this script will return the latest BAK files sequence to restore the DB from S3 backups
- It may return
 1- only one FULL backup file, if there is not any DIFF or LOG files older than that
 2- FULL + DIFF backup file
 3- FULL + DIFF + LOG backup file if database is full recovery mode and has all 3 files

========================================================================================================#>
$server_name="IP-0AE87D14\PLATFORM"
$dbname="6f770248-8a71-4487-9f7e-f633452cb6a9"
$Region="us-east-1"

Set-AWSCredentials -AccessKey  -SecretKey 
Clear-Host

#========================================================================================================
if ((Get-date).DayOfWeek.value__ -gt 0)
{
    $ThisWeekMonday = (Get-date).AddDays(1- (Get-date).DayOfWeek.value__)
} else {
    $ThisWeekMonday = (Get-date).AddDays(-6)
}
Write-Host $ThisWeekMonday.Date.ToString() -ForegroundColor Green
#======== Find FULL backup file ============
DO
{
    $Prefix = "/"+$server_name.Replace("\","/")+"/Backups/Week_"+$ThisWeekMonday.ToString("yyyyMMdd")+"/"
    Write-Host $Prefix -ForegroundColor Green

    $FULL_File = Get-S3Object -BucketName lcp2-sql-backups-us-east-1 -Keyprefix $Prefix -Region us-east-1 | Where-Object {($_.key -like "*"+$dbname+".bak") -and ($_.key -like "*FULL_*.bak")} 

    if (!($FULL_File))
    {
        $ThisWeekMonday = $ThisWeekMonday.AddDays(-7)
        Write-Host $ThisWeekMonday.Date.ToString() -ForegroundColor Cyan
    }
    else
    {
        $files=$FULL_File
        $FULL_File=$files[0]
        foreach ($file in $files)
        {
            if ($file.LastModified -gt $FULL_File.LastModified)
            {
                $FULL_File = $file
            }
        }
        break;
    }
} while(!($FULL_File))
$FULL_File.key

#======== Find DIFF backup file ============
$DIFF_File = $FULL_File
Get-S3Object -BucketName lcp2-sql-backups-us-east-1 -Keyprefix $Prefix -Region us-east-1 | Where-Object {($_.key -like "*"+$dbname+".bak") -and ($_.key -like "*DIFF_*.bak")} 

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


