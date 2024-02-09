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


$file= "LOG_20220120153532_ebd655c7-d722-425f-97f7-0d9b3211fd27.bak"
#$file= "LOG_20220120133549_ebd655c7-d722-425f-97f7-0d9b3211fd27.bak"
#$file= "DIFF_20220120113432_ebd655c7-d722-425f-97f7-0d9b3211fd27.bak"
#$file= "FULL_20220117024358_ebd655c7-d722-425f-97f7-0d9b3211fd27.bak"

$FSX_Folder = "\\amznfsxqf9zdq6f.scg.guru\share\Backups\IP-0AE87D14\PLATFORM\"
$DestFolder = "B:\Backups\JZ\"

$source = $FSX_Folder+$File
$destination = $DestFolder+$File
#get-childitem -Path "\\amznfsxqf9zdq6f.scg.guru\share\Backups\IP-0AE87D14\PLATFORM\"+$File
Copy-Item -Path $source -Destination $destination



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


