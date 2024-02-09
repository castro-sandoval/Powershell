
$Sort1 = @{Expression='Version'; Ascending=$true }
$Sort2 = @{Expression='name'; Descending=$true }
Get-ChildItem -Path "C:\Temp\Update SCID databases\SCID_DB_UPDATES\8.3.2\SCID_LZ\*.*" -Recurse | select name, @{name="Version";expression = {[System.IO.Path]::GetFileNameWithoutExtension($_.name).split("_")[1]}} | Sort-Object $Sort1, $Sort2
