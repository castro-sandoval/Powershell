Function BAKTimestampToDatetime
{
  param
  (
    [string] $BackupFileName # "FULL_20211220013235_K2Users.bak"
  )
  return [datetime]::parseexact($BackupFileName.Split("_")[1], 'yyyyMMddHHmmss', $null)
}