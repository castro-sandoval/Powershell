
$dt = new-object "System.Data.DataTable"
$cn = new-object System.Data.SqlClient.SqlConnection "server=.;database=msdb;Integrated Security=sspi"
$cn.Open()
$sql = $cn.CreateCommand()
$sql.CommandText = "SELECT * from sys.databases"
$rdr = $sql.ExecuteReader()
$dt.Load($rdr)

$cn.Close()
$dt | Export-Csv -Path "C:\temp\test.csv" -Delimiter ";" -NoTypeInformation
$dt.Clear();