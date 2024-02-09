$BackupFolder="B:\Backups\PLATFORM\"


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

$RefDate = Get-LastMonday -RefDate (Get-date)

Write-Host ("FULL_"+$RefDate.ToString("yyyyMMdd")+" = "+ (Get-ChildItem -Path ($BackupFolder+"FULL_"+$RefDate.ToString("yyyyMMdd")+"*.bak")).Length.ToString()  )
Write-Host ("LOG_"+$RefDate.ToString("yyyyMMdd")+"  = "+ (Get-ChildItem -Path ($BackupFolder+"LOG_"+$RefDate.ToString("yyyyMMdd")+"*.bak")).Length.ToString()  )
$RefDate=$RefDate.AddDays(1)
while ($RefDate -le (GET-DATE) ) {
    Write-Host ("DIFF_"+$RefDate.ToString("yyyyMMdd")+" = "+ (Get-ChildItem -Path ($BackupFolder+"DIFF_"+$RefDate.ToString("yyyyMMdd")+"*.bak")).Length.ToString()  )
    Write-Host ("LOG_"+$RefDate.ToString("yyyyMMdd")+"  = "+ (Get-ChildItem -Path ($BackupFolder+"LOG_"+$RefDate.ToString("yyyyMMdd")+"*.bak")).Length.ToString()  )
    $RefDate=$RefDate.AddDays(1)
}

