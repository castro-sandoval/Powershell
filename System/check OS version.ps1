cls
systeminfo | findstr /B /C:"OS Name" /C:"OS Version" /C:"System Type"

#$Hostname
(Get-ChildItem -path env:computername | select -Property Value -Verbose).Value

#OS details
get-ciminstance -ClassName Win32_OperatingSystem | Select-Object -Property Caption, Version, OSArchitecture
