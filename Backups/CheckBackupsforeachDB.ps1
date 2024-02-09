$query="select [name] from sys.databases where [state]=0 and user_access=0 and database_id>4 and [name] not like 'masterQueue_%'"
$dbnames = (Invoke-Sqlcmd -ServerInstance "IP-0AE87D14\PLATFORM" -Username "lldba" -Password "Dataops123!" -Database "master" -Query $query)


$dbnames.rows.count
$found = 0
$notFound=0
foreach($dbname in $dbnames)
{
    $filename = "B:\Backups\PLATFORM\FULL_20200713*"+$dbname.name+".bak"
    if (Get-ChildItem -Path $filename)
    {
        $found++
    }
    else
    {
        "Nao achou "+$filename
        $notFound++
        exit
    }
    
        

}

$found
$notFound

$Found+$notFound