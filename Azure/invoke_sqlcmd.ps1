cls
<#

#------------------------------ Login -------------------
$User = ""
$Password = ConvertTo-SecureString "" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Password
#--- Login to azure account
Login-AzureRmAccount -Credential $Credential


#>

$resourcegroupname = "DBresourcegroup1"
$servername = "dbserver1scn"
$dbUser = ""
$dbPassword = ""
$databasename = "mySampleDatabase"
$ServerInstance = "tcp:dbserver1scn.database.windows.net,1433"
$TSQL_query = "select id, name from table1"

$dataset = (Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $databasename -Username $dbUser -Password $dbPassword -Query $TSQL_query)
$dataset.Count
foreach($row in $dataset)
{
	$row.id
	$row.name
}