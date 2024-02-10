Invoke-Sqlcmd -ServerInstance "." -Username $SQLuser -Password $SQLpswd -Database "master" -Query $query | Export-Csv $outputFile

# Using Windows Authentication
$resultset = Invoke-Sqlcmd -ServerInstance "." -Database "master" -Query $query 

$resultset.rows.count
($resultset).ItemArray.Count # columns count

==========================================================================
# more secure windows authentication with current account
Invoke-Sqlcmd  -ConnectionString "Data Source=$SqlServer;Initial Catalog=$Database; Integrated Security=True;" -Query "$Query" | Format-Table

==========================================================================
Invoke-Sqlcmd -Query "SELECT COUNT(*) AS Count FROM MyTable" -ConnectionString "Data Source=MYSERVER;Initial Catalog=MyDatabase;Integrated Security=True;ApplicationIntent=ReadOnly"

==========================================================================

Import-Module SQLServer
Invoke-Sqlcmd -ServerInstance localhost -StatisticsVariable stats `
              -Query 'CREATE TABLE #Table (ID int); INSERT INTO #Table VALUES(1), (2); INSERT INTO #Table VALUES(3); SELECT * FROM #Table'

Write-Host "Number of rows affected......: $($stats.IduRows)"
Write-Host "Number of insert statements..: $($stats.IduCount)"
Write-Host "Number of select statements..: $($stats.SelectCount)"
Write-Host "Total execution time.........: $($stats.ExecutionTime)ms"

# When you run the code fragment above, is going to be something like this:  
#
# Number of rows affected......: 3
# Number of insert statements..: 2
# Number of select statements..: 1
# Total execution time.........: 5ms

This example shows how to use the -StatisticsVariable parameter to capture informations about the connection, the statements executed, and the execution time when running some T-SQL that creates a temporary table, insert some value, and finally issues a select to get all the inserted rows.

Note: when the same query is executed against multiple servers (e.g. by piping the server names thru the cmdlet), the StatisticsVariable captures an array of statistics, one for each connection. Results can then be aggregated by using, for example, ($stats.IduRows | Measure-Object -Sum).Sum.





