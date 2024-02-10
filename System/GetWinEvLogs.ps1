$dateLimit = Get-Date
$dateLimit = $dateLimit.AddDays(-1)
$table = @{Expression={$_.TimeGenerated};Label="Log Date Time";width=22},
@{Expression={$_.EntryType};Label="Type";width=15},
@{Expression={$_.Source};Label="Source";width=15},
@{Expression={$_.Message};Label="Log Message";width=255}
Get-EventLog -LogName Application -After $dateLimit -EntryType Error,Warning | select -Property TimeGenerated, EntryType, Source, Message | where Source -NE "MSSQLSERVER" | where Source -NE "Perflib" | Format-Table $table | Out-File "C:\Users\Sandoval.castro\Documents\ITOperations\evAppTKOPT6.txt"
Get-EventLog -LogName Application -After $dateLimit | select -Property TimeGenerated, EntryType, Source, Message | where Source -EQ "MSSQLSERVER" | Format-Table $table | Out-File "C:\Users\Sandoval.castro\Documents\ITOperations\evSqlTKOPT6.txt"
Get-EventLog -LogName System -After $dateLimit -EntryType Error,Warning | select -Property TimeGenerated, EntryType, Source, Message | where Message -NotLike "*policy*" | Format-Table $table | Out-File "C:\Users\Sandoval.castro\Documents\ITOperations\evSysTKOPT6.txt"
Copy-Item -Path "\\808803-TKOPT6\C$\Users\Sandoval.castro\Documents\ITOperations\evAppTKOPT6.txt" -Destination "\\808806-TKSQL2\C$\Users\Sandoval.castro\Documents\ITOperations\evAppTKOPT6.txt"
Copy-Item -Path "\\808803-TKOPT6\C$\Users\Sandoval.castro\Documents\ITOperations\evSqlTKOPT6.txt" -Destination "\\808806-TKSQL2\C$\Users\Sandoval.castro\Documents\ITOperations\evSqlTKOPT6.txt"
Copy-Item -Path "\\808803-TKOPT6\C$\Users\Sandoval.castro\Documents\ITOperations\evSysTKOPT6.txt" -Destination "\\808806-TKSQL2\C$\Users\Sandoval.castro\Documents\ITOperations\evSysTKOPT6.txt"