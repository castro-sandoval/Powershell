$servername = 'I-0F587E7A4C125' 
$date = "20221110"
$fromDevicePath = '\\fsxpath\share\'

$location = $fromDevicePath+"Backups\"+$servername+"\DIFF_"+$date+"*.bak"
$files = Get-ChildItem -Path $location | Select-Object -Last 50
$files.count
