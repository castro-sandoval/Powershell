$files = (Get-ChildItem -Path "D:\data\backup\espsandbox\*.bak").FullName
foreach ($file in $files) {
    $filename = Split-Path $file -Leaf
    $newName = (Split-Path $file -Parent)+"\"+"FULL_"+$filename.Substring(20, $filename.Length-20)
    Rename-Item -Path $file -NewName $newName
}