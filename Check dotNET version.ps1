[System.Runtime.InteropServices.RuntimeEnvironment]::GetSystemVersion()

(Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse | Get-ItemProperty -name Version,Release -EA 0 | Where { $_.PSChildName -match '^(?!S)\p{L}'} | Select PSChildName, Version | where {$_.PSChildName -eq "Full"} | select Version | ft -HideTableHeaders | Out-String).TrimStart().TrimEnd()