Set-AWSCredentials -AccessKey  -SecretKey 

$Medtronic_AllBU_SCID="6f770248-8a71-4487-9f7e-f633452cb6a9"
$Medtronic_AllBU_SCID_Instance="IP-0AE87D14\PLATFORM"



Function ExtractFilenameFromS3Key {
    param (
        [string] $S3key
    )
    $a = $S3key.ToCharArray()
    [array]::Reverse($a)
    $Filename = -join($a)
    $Filename=$Filename.Split("/")[0]
    $a = $Filename.ToCharArray()
    [array]::Reverse($a)
    $Filename = -join($a)

    return $Filename
}
Function Get-LastMonday
{
  param
  (
    [datetime] $RefDate
  )
    #-- calculate last Monday ---------
    $Monday = [datetime]::parseexact($RefDate.ToString("yyyyMMdd"), 'yyyyMMdd', $null)
    if ($Monday.DayOfWeek.value__ -eq 0)
    {
        $Monday=$Monday.AddDays(-6)
    }
    else {
        $Monday=$Monday.AddDays(1-$Monday.DayOfWeek.value__)
    }
    return $Monday
}
Clear-Host


$LastMonday = (Get-LastMonday -RefDate (Get-date)).ToString("yyyyMMdd")
$PreviousMonday = (Get-LastMonday -RefDate (Get-date).AddDays(-7)).ToString("yyyyMMdd")

#=========================================================================
$SQLinstance  = $Medtronic_AllBU_SCID_Instance
$catalog      = $Medtronic_AllBU_SCID
$BackupFolder = "I:\Backups"

#==========================================================================
# search local disk for file
#==========================================================================
$Medtronic_AllBU_SCID_FULL=""
Get-ChildItem -Path ($BackupFolder+"\FULL*"+$catalog+".bak")

#==========================================================================
# search S3 for file
#==========================================================================
$KeyPrefix = $SQLinstance.Replace("\","/")+"/Backups/Week_"+$LastMonday+"/"

Write-Host("Searching "+$KeyPrefix+ "*FULL*"+$catalog+".bak")
$key_to_download = (Get-S3Object -BucketName "lcp2-sql-backups-us-east-1" -KeyPrefix $KeyPrefix | Where-Object {($_.Key -like ("*/FULL_*"+$catalog+".bak"))} | Select -Property Key).Key
$file="C:\Databases\Backup\"+(ExtractFilenameFromS3Key($key_to_download))

Write-Host("Downloading to "+$file)


#Read-S3Object -BucketName "lcp2-sql-backups-us-east-1" -Key $key_to_download -File $file