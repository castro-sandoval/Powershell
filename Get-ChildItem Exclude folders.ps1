

$FoldersToCheck = @("C:\temp\*")
$Exclusions = @("c:\Temp\DumpToCSV",
                "c:\Temp\Read_CSV_to_Redshift"
                )

$ExclusionString=[string]::join("|", $Exclusions)
$ExclusionString=$ExclusionString.Replace("\","\\")
foreach($folder in $FoldersToCheck)
{
    (Get-ChildItem -Path $folder -Recurse | Where-Object {($_.FullName -notmatch $ExclusionString)}).Count
}