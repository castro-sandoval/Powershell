Clear-Host
$StartDate = (Get-Date).AddMilliseconds(-239028)

(NEW-TIMESPAN –Start $StartDate –End (Get-Date)).ToString()+" (Hours:Min:Sec.ms)"