cls
$host_name = (Get-ChildItem -path env:computername | select -Property Value -Verbose).Value

"Hostname: " + [System.Net.Dns]::GetHostName() 
get-ciminstance -ClassName Win32_OperatingSystem | Out-String 
get-ciminstance -class "cim_physicalmemory" | select -Property Name, DeviceLocator, Tag, Manufacturer, Capacity | Sort-Object DeviceLocator | Out-String
Get-Disk | select -Property Number, FriendlyName, HealthStatus, OperationalStatus, @{n='Size (GB)';e={$_.Size/1073741824}}, PartitionStyle, SerialNumber | Sort-Object Number | Out-String
Get-Partition | select -Property PartitionNumber, Type, DriveLetter,  @{n='Size (GB)';e={$_.Size/1073741824}} | Sort-Object PartitionNumber | Out-String
Get-Volume | select -Property DriveLetter, FileSystemLabel, FileSystem, DriveType, HealthStatus, OperationalStatus, @{n='Size (MB)';e={$_.Size/1048576}}, @{n='SizeRemaining (MB)';e={$_.SizeRemaining/1048576}}, @{n='PercentFree (MB)';e={$_.SizeRemaining/$_.Size}}  | Out-String
#Get-Service | Select-Object Name, Status, DisplayName | Sort-Object Status -Descending | Out-String