param ($BackupFolder, $SQLuser, $SQLpswd)

$FullBackups = (Get-ChildItem -Path ($BackupFolder+"FULL*.bak") )
$CheckedDBs = New-Object Collections.Generic.List[String]
$SelectedCatalogs = New-Object Collections.Generic.List[String]
foreach($FullBackup in $FullBackups) 
{
    $dbname = $FullBackup.Name.Substring(20,$FullBackup.Name.Length-20-4)
    if ($CheckedDBs.IndexOf($dbname) -eq -1) 
    {
        $CheckedDBs.Add($dbname);
        #============ Find last Full backup of this catalog ===========
        $CatalogFullBackups = (Get-ChildItem -Path ($BackupFolder+"FULL_*"+$dbname+".bak"))
        $LastCatalogFullBAK = $CatalogFullBackups[0];
        foreach($CatalogFullBackup in $CatalogFullBackups)
        {
            if ($CatalogFullBackup.CreationTimeUtc -gt $LastCatalogFullBAK.CreationTimeUtc)
            {
                $LastCatalogFullBAK=$CatalogFullBackup
            }
        }
        #============ Find DIFF backups after LastFull ===========
        $DiffBackups = (Get-ChildItem -Path ($BackupFolder+"DIFF_*"+$dbname+".bak") | Where-Object {($_.CreationTimeUtc -gt $LastCatalogFullBAK.CreationTimeUtc)}   )
        if ($DiffBackups.Length -gt 0)
        {
            $LastCatalogDiffBAK = $DiffBackups[0];
            foreach($CatalogDiffBackup in $DiffBackups)
            {
                if ($CatalogDiffBackup.CreationTimeUtc -gt $LastCatalogDiffBAK.CreationTimeUtc)
                {
                    $LastCatalogDiffBAK=$CatalogDiffBackup
                }
            }
            if ($LastCatalogDiffBAK.Length -ge ($LastCatalogFullBAK.Length/2)) 
            {
                $SelectedCatalogs.Add($dbname)
                break
            }
        }
    }
}

for($i=0;$i -lt $SelectedCatalogs.Count; $i++) {
    
    $Query = "INSERT INTO [DataOps].[IntermediateFullBackups]([catalog]) VALUES ('"+$SelectedCatalogs[$i]+"')"
    Invoke-Sqlcmd -ServerInstance "." -Username $SQLuser -Password $SQLpswd -Database "msdb" -Query $Query
    
}
