#------------------------------ Login -------------------
$User = ""
$Password = ConvertTo-SecureString "" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Password
#--- Login to azure account
Login-AzureRmAccount -Credential $Credential

#--------- List all resource groups available -----------
Find-AzureRmResourceGroup | Where-Object {($_.location -EQ "westeurope" -and $_.Properties -like "*provisioningState=Succeeded*")}

Find-AzureRmResource -ResourceType "Microsoft.Sql/servers"

Find-AzureRmResource -ResourceType "Microsoft.Sql/servers/databases" -ExpandProperties | Where-Object {$_.Name -eq "mySampleDatabase"}

Get-AzureRmSqlServerActiveDirectoryAdministrator -ResourceGroupName "DBresourcegroup1" -ServerName "dbserver1scn" 

#========= create the SQL Server database ==============
cls
# Set the resource group name and location for your server
$resourcegroupname = "DBresourcegroup1"
$location = "westeurope"
$servername = "dbserver1scn"

# Set an admin login and password for your server
$adminlogin = "sandoval"
$password = "Benedito@83"


$databasename = "mySampleDatabase"
$startip = "0.0.0.0"
$endip = "0.0.0.0"


$database = New-AzureRmSqlDatabase  -ResourceGroupName $resourcegroupname `
    -ServerName $servername `
    -DatabaseName $databasename `
    -RequestedServiceObjectiveName "S0" `
    -SampleName "AdventureWorksLT"

#---------- Get all databases on server --------------
Get-AzureRmSqlDatabase -ResourceGroupName "DBresourcegroup1" -ServerName "dbserver1scn" | select -Property DatabaseName, DatabaseId, Status, Edition, CollationName | Format-Table

#---------- Get DB connection Policy
Get-AzureRmSqlServerFirewallRule -ResourceGroupName "DBresourcegroup1" -ServerName "dbserver1scn"




#---------- Get DB connection Policy for a Database
Get-AzureRmSqlDatabaseSecureConnectionPolicy -ResourceGroupName "DBresourcegroup1" -ServerName "dbserver1scn" -DatabaseName "mySampleDatabase"
