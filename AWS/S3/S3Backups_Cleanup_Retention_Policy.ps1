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


function Delete-Week
{
  param
  (
    [string] $prefix
  )

    $keysToDelete = @((Get-S3Object -BucketName lcp2-sql-backups-us-east-1 -KeyPrefix $prefix).key)
    $returnValue = $keysToDelete.Count
    if ($returnValue -gt 0) 
    {
        if ($keysToDelete.Count -gt 1000) {
            $Subset_size = 1000
        } else {
            $Subset_size=$keysToDelete.Count
        }
        $init = 0
        while(($init+$Subset_size) -lt $keysToDelete.Count) {
            $subset = @()
            for($i=$init;$i -lt ($init+$Subset_size) ;$i++) {
                $subset+=$keysToDelete[$i]
            }
            Remove-S3Object -BucketName lcp2-sql-backups-us-east-1 -KeyCollection $subset -force | Out-Null    
            $init+=$Subset_size
        }
        $keysToDelete = @((get-s3object -BucketName lcp2-sql-backups-us-east-1 -KeyPrefix $prefix).key)
        if ($keysToDelete.Count -gt 0) {
            Remove-S3Object -BucketName lcp2-sql-backups-us-east-1 -KeyCollection $keysToDelete -force | Out-Null
        }
        $keysToDelete=@()
        $subset = @()
    }
    return $returnValue 
}




$LocalLog = "D:\Jobs\S3_CleanUp_RetentionPolicy_"+(Get-Date).ToString("yyyyMMdd_HHmmss")+".log"
Add-Content -Path $LocalLog -Value ("Backup retention policy - S3 bulcket clean up ")
Add-Content -Path $LocalLog -Value ("Start: "+(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))
$start = Get-Date

# --- retrieve each server retention period in weeks
$query = "select T.server_name, A.tag_name, S.servergroup_id as retention_weeks, [location] as env from dbo.systargetservergroupmembers M inner join dbo.systargetservers T on M.server_id=T.server_id inner join dbo.systargetservergroups S on S.servergroup_id=M.servergroup_id	inner join [dbo].[systargetserverstag] A on T.server_id=A.server_id"
$TargetServers = (Invoke-Sqlcmd -ServerInstance "." -Username "sa" -Password "llama123!" -Database "msdb" -Query $query)
Add-Content -Path $LocalLog -Value ($TargetServers.Count.ToString()+" target servers found.")


$subFolders = @("/Backups/","/TransacLogs/")

foreach ($target in $TargetServers) 
{

    $LastWeek = (Split-Path($target.server_name,"\")[0]) +"/backups/Week_"+(Get-Date).AddDays(-(Get-Date).DayOfWeek.value__ + 1).AddDays(-$target.retention_weeks * 7).ToString("yyyyMMdd")+"/"
    $LastWeek = $LastWeek.Substring($LastWeek.IndexOf("/Week_")+6, 8)

    Add-Content -Path $LocalLog -Value ""
    Add-Content -Path $LocalLog -Value ("Server: "+$target.server_name+" ("+$target.env+")      Tag name:"+$target.tag_name+"     Retention:"+$target.retention_weeks.ToString()+"   Last week:"+$LastWeek)


    foreach($subfolder in $subFolders)
    {

        Add-Content -Path $LocalLog -Value ("    - checking old "+$subfolder)
        
        $S3Weeks= (Get-Subdirectories -BucketName lcp2-sql-backups-us-east-1 -KeyPrefix ("/"+$target.server_name+$subfolder) -Recurse $false)
        if ($S3Weeks.Count -gt 0) 
        {

            foreach($S3Week in $S3Weeks)
            {
                $Week = $S3Week.Substring($S3Week.IndexOf("/Week_")+6, 8)
                if ($Week -lt $LastWeek) 
                {
                    $keysToDelete = Delete-Week -prefix $S3Week
                    Add-Content -Path $LocalLog -Value ("        - Delete "+$S3Week+"  ("+$keysToDelete.ToString()+" objects)")
                } else 
                {
                    Add-Content -Path $LocalLog -Value ("        + Keep "+$S3Week)
                }
            }
        }
        else {
            Add-Content -Path $LocalLog -Value ("        * 0 files in "+"/"+$target.server_name+$subfolder)
        }  
    }
    Add-Content -Path $LocalLog -Value ("----------------------------------------------------------------------------------------------------------------------------------------------")

}
Add-Content -Path $LocalLog -Value ("Finish: "+(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))
$Duration = (New-TimeSpan -Start $start -End (Get-Date))
Add-Content -Path $LocalLog -Value ("Duration (HH:MM:SS.ms): "+$duration.Hours.ToString("00")+":"+$duration.Minutes.ToString("00")+":"+$duration.Seconds.ToString("00")+"."+$duration.Milliseconds.ToString())
