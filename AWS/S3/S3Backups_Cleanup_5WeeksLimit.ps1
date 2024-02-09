cls
Set-AWSCredential -AccessKey AKIAIK6ODY2F7MFNUVBQ -SecretKey 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

function Get-Subdirectories
{
  param
  (
    [string] $BucketName,
    [string] $KeyPrefix,
    [bool] $Recurse
  )

  @(get-s3object -BucketName $BucketName -KeyPrefix $KeyPrefix -Delimiter '/') | Out-Null

  if($AWSHistory.LastCommand.Responses.Last.CommonPrefixes.Count -eq 0)
  {
    return
  }

  $AWSHistory.LastCommand.Responses.Last.CommonPrefixes

  if($Recurse)
  {
    $AWSHistory.LastCommand.Responses.Last.CommonPrefixes | % { Get-Subdirectories -BucketName $BucketName -KeyPrefix $_ -Recurse $Recurse }
  }
}

function Get-S3Directories
{
  param
  (
    [string] $BucketName,
    [bool] $Recurse = $false
  )

  Get-Subdirectories -BucketName $BucketName -KeyPrefix '/' -Recurse $Recurse
}


cls
$retention_weeks=5
$LastWeek = (Get-Date).AddDays(-(Get-Date).DayOfWeek.value__ + 1).AddDays(-$retention_weeks * 7).ToString("yyyyMMdd")
$DateLimit= (Get-Date).AddDays(-(Get-Date).DayOfWeek.value__ + 1).AddDays(-$retention_weeks * 7)
$LocalLog = "D:\Jobs\S3_CleanUp_4weeks_"+(Get-Date).ToString("yyyyMMdd_HHmm")+".log"
$start = Get-Date
Add-Content -Path $LocalLog -Value ("S3 backup bucket clean up ")
Add-Content -Path $LocalLog -Value ("Start: "+(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))


Add-Content -Path $LocalLog -Value " "
Add-Content -Path $LocalLog -Value ("Delete keys older than Week_"+$LastWeek+" or files olders than "+$DateLimit.ToString("yyyy-MM-dd HH:mm"))


Add-Content -Path $LocalLog -Value "======================================================================================================================="

$targets = (Get-Subdirectories -BucketName lcp2-sql-backups-us-east-1 -KeyPrefix "/" -Recurse $false)
foreach ($target in $targets)
{
    $folders = $targets = (Get-Subdirectories -BucketName lcp2-sql-backups-us-east-1 -KeyPrefix ("/"+$target) -Recurse $false)
    foreach($folder in $folders)
    {
        $subset = @()
        $objects = (Get-S3object -BucketName lcp2-sql-backups-us-east-1 -KeyPrefix ("/"+$folder))
        write-host ("/"+$folder+" = "+$objects.Length.ToString()) -ForegroundColor Yellow

        Add-Content -Path $LocalLog -Value ""
        Add-Content -Path $LocalLog -Value ("/"+$folder+" = "+$objects.Length.ToString())

        foreach ($obj in $objects) {
            $KeyWeek = $obj.key.Substring($obj.key.IndexOf("/Week_")+6, 8)
            if ((($KeyWeek -lt $LastWeek)  -or ($obj.LastModified -lt $DateLimit)) ) # -and ($obj.Key.Substring($obj.Key.Length-4,4) -ne ".log"))
            {
                $subset += $obj.key
                Add-Content -Path $LocalLog -Value ($obj.Key)

                if ($subset.Count -eq 1000) {
                    #Remove-S3Object -BucketName lcp2-sql-backups-us-east-1 -KeyCollection $subset -force | Out-Null
                    $subset = @()
                }
            }
        }

    }
    
}

Add-Content -Path $LocalLog -Value ("Finish: "+(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))
$Duration = (New-TimeSpan -Start $start -End (Get-Date))
Add-Content -Path $LocalLog -Value ("Duration (HH:MM:SS.ms): "+$duration.Hours.ToString("00")+":"+$duration.Minutes.ToString("00")+":"+$duration.Seconds.ToString("00")+"."+$duration.Milliseconds.ToString())
