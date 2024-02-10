param ([Parameter(Mandatory)] $folder)

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

$datelimit = Get-LastMonday -RefDate (Get-date)
$logFile= $folder+"DeleteOldFiles_"+ (Get-Date).ToString("yyyyMMddhhmmss") +".log"

$files = (Get-Item -Path ($folder+"*.bak") | Where-Object {($_.LastWriteTime -lt $datelimit)} ).FullName
Add-Content -Path $logFile -Value ($files.Length.ToString()+" BAK files older than "+$datelimit.ToString()+" found to delete from "+$folder)

foreach ($file in $files)
{
    Add-Content -Path $logFile -Value $file
    Remove-Item -Path $file -Force
}

Add-Content -Path $logFile -Value ""
Add-Content -Path $logFile -Value ("=" * 100)
Add-Content -Path $logFile -Value ""
$datelimit = $datelimit.AddDays(-10)

$files = (Get-Item -Path ($folder+"*.log") | Where-Object {($_.LastWriteTime -lt $datelimit)} ).FullName
Add-Content -Path $logFile -Value ($files.Length.ToString()+" LOG files older than "+$datelimit.ToString()+" found to delete from "+$folder)

foreach ($file in $files)
{
    Add-Content -Path $logFile -Value $file
    Remove-Item -Path $file -Force
}


Add-Content -Path $logFile -Value ""
Add-Content -Path $logFile -Value ("=" * 100)
Add-Content -Path $logFile -Value ("Finish at "+(Get-date).ToString())
Add-Content -Path $logFile -Value ""