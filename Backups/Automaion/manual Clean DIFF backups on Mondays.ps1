
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


function Delete-Week-DIFF
{
  param
  (
    [string] $prefix
  )

    $keysToDelete = @((Get-S3Object -BucketName lcp2-sql-backups-us-east-1 -KeyPrefix $prefix | Where-Object {$_.key -like "*DIFF*"}).key)
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
        $keysToDelete = @((get-s3object -BucketName lcp2-sql-backups-us-east-1 -KeyPrefix $prefix | Where-Object {$_.key -like "*DIFF*"}).key)
        if ($keysToDelete.Count -gt 0) {
            Remove-S3Object -BucketName lcp2-sql-backups-us-east-1 -KeyCollection $keysToDelete -force | Out-Null
        }
        $keysToDelete=@()
        $subset = @()
    }
    return $returnValue 
}

cls
$query = "select T.server_name, A.tag_name, S.servergroup_id as retention_weeks, [location] as env from dbo.systargetservergroupmembers M inner join dbo.systargetservers T on M.server_id=T.server_id inner join dbo.systargetservergroups S on S.servergroup_id=M.servergroup_id	inner join [dbo].[systargetserverstag] A on T.server_id=A.server_id"
$TargetServers = (Invoke-Sqlcmd -ServerInstance "." -Username "sa" -Password "llama123!" -Database "msdb" -Query $query)

foreach ($target in $TargetServers) 
{
    $InstanceName = $target.server_name
    $BulkFolder = "lcp2-sql-backups-us-east-1/"+($InstanceName).Replace("\","/")+"/Backups/Week_"+(Get-Date).AddDays(-(Get-Date).DayOfWeek.value__ + 1).ToString("yyyyMMdd")
    $keyPrefix = $BulkFolder.Replace("lcp2-sql-backups-us-east-1","")

    $BulkFolder
    
    $keyPrefix
    "  "
    if ((Get-Date).DayOfWeek.value__ -eq 1) 
    {
        Write-Host "It's a Monday. Clean week before FULL backup" -ForegroundColor Yellow
        $keysToDelete = Delete-Week-DIFF -prefix $keyPrefix
        Write-Host ($keysToDelete.ToString()+ " files removed from "+$keyPrefix) -ForegroundColor Cyan
    }
}


"   "
"-------------------------------------------------------------------------------------------------------------------"
"  "