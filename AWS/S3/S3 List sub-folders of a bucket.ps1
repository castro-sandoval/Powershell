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
<#
# Get all target servers, retention period
$query = "select T.server_name, A.tag_name, S.servergroup_id as retention_weeks, [location] as env from dbo.systargetservergroupmembers M inner join dbo.systargetservers T on M.server_id=T.server_id inner join dbo.systargetservergroups S on S.servergroup_id=M.servergroup_id	inner join [dbo].[systargetserverstag] A on T.server_id=A.server_id"

$TargetServers = (Invoke-Sqlcmd -ServerInstance "." -Username "sa" -Password "llama123!" -Database "msdb" -Query $query)

$TargetServers.Count
#>
# List all sub-folders for a bucket
#Get-Subdirectories -BucketName lcp2-sql-backups-us-east-1 -KeyPrefix "IP-0AE87D14/PLATFORM/Backups/" -Recurse $false
Get-Subdirectories -BucketName lcp2-sql-backups-us-east-1 -KeyPrefix "/ProjMonarch/" -Recurse $false