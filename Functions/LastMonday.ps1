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

$LastMonday = (Get-LastMonday -RefDate (Get-date)).ToString("yyyyMMdd")
$LastMonday