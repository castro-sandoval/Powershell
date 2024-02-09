$diskinfo = get-WmiObject win32_logicaldisk | Select DeviceID, Size, FreeSpace | Where-Object {$_.DeviceID -eq "C:"} 
$freePercentage=$diskinfo.FreeSpace/$diskinfo.Size*100
$freeGB = $diskinfo.FreeSpace/1024/1024/1024

$FolderSize = (Get-ChildItem -Path "E:\Backup\*.*" -Recurse | Measure-Object -Sum Length | Select-Object Sum).Sum
$FreeSpace = (get-WmiObject win32_logicaldisk | Where-Object {$_.DeviceId -eq "E:"} | Select -Property FreeSpace).FreeSpace


