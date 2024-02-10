



#===================================================================================
$ErrorList = New-Object System.Collections.ArrayList

$ExclusionList = @("*.exe,*.nupkg,*.msi,*.dgproj,*.bak,*.zip,*.dll,*.mdf,*.ldf,*.lnk")

$IsOutlookRunning = Get-Process | Where-Object {($_.processname -eq "OUTLOOK")} | select -Property Id

if ($IsOutlookRunning) {
    $ExclusionList += "*.pst"
    Write-Host (".pst files will be excluded because OUTLOOK is running...")
} 



#===================================================================================




if ($FoldersToCheck.Contains("C:\Databases\*.*") -eq $TRUE) {
    Stop-Service -Name SQLSERVERAGENT
    Stop-Service -Name MSSQLSERVER
}



if ($FoldersToCheck.Contains("C:\Databases\*.*") -eq $TRUE) {
    Start-Service -Name MSSQLSERVER
    Start-Service -Name SQLSERVERAGENT
}
