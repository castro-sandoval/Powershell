 -OutputSqlErrors $true 
Indicates that this cmdlet displays error messages in the Invoke-Sqlcmd output.

-ConnectionTimeout
Specifies the number of seconds when this cmdlet times out if it cannot successfully connect to an instance of the Database Engine. The timeout value must be an integer value between 0 and 65534. If 0 is specified, connection attempts do not time out.

-QueryTimeout
Specifies the number of seconds before the queries time out. If a timeout value is not specified, the queries do not time out. The timeout must be an integer value between 1 and  65535.



### EXECUTE QUERY ###########

$query="CREATE DATABASE ["+$dbname+"]"
Invoke-Sqlcmd -ServerInstance $servername -Username $sqllogin -Password $sqlpwrd -Database "master" -Query $query -ErrorAction Stop


######### EXECUTE FILE #########

$SQLfilePath=$basefolder+"\RCDB.sql"
Invoke-Sqlcmd -ServerInstance $SQLinstance -Username $sqllogin -Password $sqlpwrd -Database $dbname -InputFile $SQLfilePath -ErrorAction Stop

######### USING CONN STRING #########
Invoke-Sqlcmd -Query "SELECT COUNT(*) AS Count FROM MyTable" -ConnectionString "Data Source=MYSERVER;Initial Catalog=MyDatabase;Integrated Security=True;ApplicationIntent=ReadOnly"


######### OUTPUT TO FILE #########
Invoke-Sqlcmd -InputFile "C:\ScriptFolder\TestSqlCmd.sql" | Out-File -FilePath "C:\ScriptFolder\TestSqlCmd.rpt"
Output sent to TestSqlCmd.rpt.

######### OUTPUT TO data object #########
$DS = Invoke-Sqlcmd -ServerInstance "MyComputer" -Query "SELECT  ID, Item FROM MyDB.dbo.MyTable" -As DataSet
$DS.Tables[0].Rows | %{ echo "{ $($_['ID']), $($_['Item']) }" }

{ 10, AAA }
{ 20, BBB }
{ 30, CCC }



