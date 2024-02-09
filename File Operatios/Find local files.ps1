$Path="C:\Users\sandoval.castroneto\Desktop\checks.d\conf.d\*.*"
$FileTypesToSearch=@("*.yaml")
$Exclusions=@("*.abc, *.def")


#Get-ChildItem -Path $Path -Recurse | select -Property FullName, Length, LastWriteTime


#Get-ChildItem -Path $Path -Recurse -Include $FileTypesToSearch -Exclude $Exclusions | select -Property FullName, Length, LastWriteTime

$files = (Get-ChildItem -Path $Path -Recurse -Include $FileTypesToSearch -Exclude $Exclusions | select -Property FullName, Length, LastWriteTime)

foreach($file in $files) {
$file.LastWriteTime.ToString("yyyy-MM-dd")+" : "+$file.FullName+" = "+([math]::Round($file.Length/1MB)).ToString()+" MB"
}