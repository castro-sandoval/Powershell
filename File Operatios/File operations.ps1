
Split-Path -Path "C:\Test\Logs\myfile.log" -Leaf 

#===============================
Add-Content -Path <path> -Value <value>


((Get-ChildItem -Path "E:\log\*.*" -Recurse) | Measure-Object -Maximum Length | Select-Object Maximum).Maximum/1024/1024
(Get-ChildItem -Path "E:\log\*.*" -Recurse) | Measure-Object -Sum Length | Select-Object Count, Sum

if (!(Test-Path $BaseFolder)) {
    New-Item -ItemType Directory $BaseFolder
}

#======================================================

Add-Content -Path "c:\temp\test.txt" -Value "Text"

#======================================================

$FileContent = Get-Content -Path $File.FullName
foreach($line in $FileContent)
{
            
    if($line.IndexOf($StrToFind) -ge 0) {
        $StrFound = $StrFound + 1
    }
}
