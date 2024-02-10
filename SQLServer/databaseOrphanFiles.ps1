<#=======================================================================================================================
 Looking for orphan files ( mdf or ldf files not linked to any database )
    - This script will find all SQLServer instances running on this server
    - for each instance, find the data path defined as SERVER PROPERTY
    - for each instance, it will check all existing ONLINE databases
    - find all files used per database
    - compare all files in the data path with the files used by databases and determine the orphan files that could
    be move or deleted.

    Orphan files are result of operations like take the database offline or detach databases
=======================================================================================================================#>

$Username="****" 
$Password="*******"
Clear-Host
$instances = (Get-Service -Name "*MSSQL*" | Where-Object {(($_.ServiceName -eq "MSSQLSERVER") -or ($_.ServiceName -like "MSSQL$*")) -and ($_.Status -eq "Running")} | Select-Object -Property Name)

foreach($instance in $instances.Name) {

    $instanceName=$instance.Replace("MSSQL$",$env:COMPUTERNAME+"\").Replace("MSSQLSERVER",$env:COMPUTERNAME+"\")

    $query = "SELECT SERVERPROPERTY('InstanceDefaultDataPath') as DataFolder"
    $dataFolder = (Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query).ItemArray[0]
    $orfanFilesFolder=$dataFolder.Substring(0,3)+"orphanFiles\"+$instanceName
    if (!(Test-Path -Path $orfanFilesFolder)) {
        New-Item -Path $orfanFilesFolder -ItemType Directory -Force
    }
    
    $orfanFileslog = ($orfanFilesFolder+"\OrphanFiles_"+(Get-Date).ToString("yyyyMMddhhmmss")+".log")

    Add-Content -Path $orfanFileslog -Value ("Start: "+(Get-Date).ToString("yyyy-MM-dd hh:mm:ss"))
    Add-Content -Path $orfanFileslog -Value ("Checking instance: "+$instanceName)
    Add-Content -Path $orfanFileslog -Value ("    Data folder: "+$dataFolder)


    # Find data and log folders
    $query = "select [name] from [master].sys.databases where [state]=0"
    $dbnames = (Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query).name
    Add-Content -Path $orfanFileslog -Value ("    Databases count: "+$dbnames.Count.ToString())

    $existingDBs = @()
    foreach ($dbname in $dbnames) {
        $query = "select top 1 physical_name from ["+$dbname+"].sys.database_files where [state]=0 and [type]=1"
        $dbLogfile = (Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query).physical_name
    
        $query = "select top 1 physical_name from ["+$dbname+"].sys.database_files where [state]=0 and [type]=0"
        $dbDatafile = (Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query).physical_name
    
        #---- save files used by databases ------
        $existingDBs+=(Split-Path $dbDatafile -Leaf)
        $existingDBs+=(Split-Path $dbLogfile -Leaf)
    }
    $orfanFiles = (Get-ChildItem -Path $dataFolder -Exclude $existingDBs | Where-Object {($_.Extension -in (".mdf", ".ldf"))})
    Add-Content -Path $orfanFileslog -Value ("    Orphan files count: "+$orfanFiles.Count.ToString())
    $totalSpace=0
    foreach($file in $orfanFiles) {
        Add-Content -Path $orfanFileslog -Value ($file.FullName+"  ("+ [math]::Round( ($file.Length/1Mb), 2).ToString() +" MB = "+ [math]::Round( ($file.Length/1Gb), 2).ToString() +" GB)" )
        $totalSpace+=$file.Length
    }
    Add-Content -Path $orfanFileslog -Value ("Total space: "+$totalSpace.ToString()+" bytes = "+[math]::Round( ($totalSpace/1Mb), 2).ToString()+" MB = "+[math]::Round( ($totalSpace/1Gb), 2).ToString()+" GB")
}

