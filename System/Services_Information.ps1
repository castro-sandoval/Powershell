cls


$host_name = (Get-ChildItem -path env:computername | select -Property Value -Verbose).Value
$services = (Get-WmiObject "win32_service" | Where-Object {($_.Name -like "*SQL*" -and ($_.Name -notlike "*TELEMETRY*" -and $_.Name -notlike "*Launcher*" -and $_.name -notlike "SQLWriter" -and $_.Name -notlike "*dts*")) -or $_.Name -like "*report*" } | Sort-Object -Property State ) # | select -Property PSComputerName,ProcessID,Name,Status,Started,State,StartName,StartMode,Path,Caption  | Export-Csv -Path "c:\temp\services.txt" -Encoding Unicode -NoTypeInformation
foreach ($service in $services)
{
    write-host ($host_name+";"+$service.State.ToString()+";"+$service.Caption+";"+$service.name)

}