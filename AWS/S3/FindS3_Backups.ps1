Clear-Host

Import-Module -Name ("C:\Dataops\bin\DFTlibrary.dll")
$awsaccessKey = Get-awsaccessKey
$awssecretkey = Get-awssecretkey

Set-AWSCredential -AccessKey $awsaccessKey -SecretKey $awssecretkey


$catalog="02375411-2e3f-418c-98d5-5a90dc938870"
$servername="I-04A299006679A"

$S3Bucket="lcp2-sql-backups-us-east-1"

Function BAKTimestampToDatetime
{
  param
  (
    [string] $BackupFileName # "FULL_20211220013235_K2Users.bak"
  )
  return [datetime]::parseexact($BackupFileName.Split("_")[1], 'yyyyMMddHHmmss', $null)
}


#FULL
#$last_FULL = (Get-S3Object -BucketName $S3Bucket -KeyPrefix ("/"+$servername+"/")  | Where-Object {($_.Key -like ("*/FULL*"+$catalog+"*.bak"))} | Select -Property Key).Key | Sort-Object -Descending | select -First 1
$last_FULL = "I-04A299006679A/FULL_20230303000502_02375411-2e3f-418c-98d5-5a90dc938870.bak"

if ($last_FULL) {
    $FULL_Datetime = [datetime]::parseexact($last_FULL.split("/")[1].split("_")[1], 'yyyyMMddHHmmss', $null)


    Write-Host $last_FULL -ForegroundColor Green
    Write-Host ($FULL_Datetime)
    Write-Host ("--------------------------------------------------------------------------------------------") -ForegroundColor Gray

    # DIFF
    $last_DIFF = (Get-S3Object -BucketName $S3Bucket -KeyPrefix ("/"+$servername+"/")  | Where-Object {($_.Key -like ("*/DIFF*"+$catalog+"*.bak")) -and ($_.LastModified -gt $FULL_Datetime)} | Select -Property Key).Key | Sort-Object -Descending | select -First 1
    if ($last_DIFF) {
        $DIFF_Datetime = [datetime]::parseexact($last_DIFF.split("/")[1].split("_")[1], 'yyyyMMddHHmmss', $null)
        Write-Host $last_DIFF -ForegroundColor Green
        Write-Host ($DIFF_Datetime)
        Write-Host ("--------------------------------------------------------------------------------------------") -ForegroundColor Gray
    }


    # LOG
    $Min_Logkey = $last_DIFF.Replace("DIFF","LOG")
    $AllLogBackups = (Get-S3Object -BucketName $S3Bucket -KeyPrefix ("/"+$servername+"/")  | Where-Object {($_.Key -like ("*/LOG*"+$catalog+"*.bak")) -and ($_.key -gt $Min_Logkey)} | Select -Property Key).Key
    foreach($LogBackup in $AllLogBackups) {
        $LOG_Datetime = [datetime]::parseexact($LogBackup.split("/")[1].split("_")[1], 'yyyyMMddHHmmss', $null)
        Write-Host $LogBackup -ForegroundColor Green
        Write-Host ($LOG_Datetime)
    }


}
else {
    Write-Host ("Full backup not found from "+$catalog+" on server "+$servername) -ForegroundColor red
}

