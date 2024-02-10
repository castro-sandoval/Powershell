
cls
$LocalComputerName  = (Get-ChildItem -path env:computername | select -Property Value -Verbose).Value
$TotalRAM = [math]::round((Get-WmiObject -Class Win32_OperatingSystem -Computer $LocalComputerName).TotalVisibleMemorySize/ 1047553,1)

Get-Service | Where {($_.Status -eq "Running") -and ($_.Name -like "*MSSQL*") -and ($_.Name -notlike "*OLAP*")}