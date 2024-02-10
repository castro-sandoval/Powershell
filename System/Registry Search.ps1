cls

#$RegFolders = (Get-ChildItem 'HKLM:\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server' -Recurse).Name

$RegKeys = Get-ChildItem 'HKLM:\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server' –rec –ea SilentlyContinue | % { if((Get-ItemProperty –Path $_.PsPath) -match "backup") {$_.PsPath} } 
foreach($key in $RegKeys) {
    Write-Host ($key + " = "+ (Get-ItemProperty -Path $key | Select -Property BackupDirectory).BackupDirectory)
}

