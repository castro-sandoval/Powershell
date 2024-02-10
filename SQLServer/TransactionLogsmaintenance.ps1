$instanceName="EC2AMAZ-RO6HDEV"
$Username="***" 
$Password="***"
$orfanFilesFolder="E:\orphanFiles\"
Clear-Host

<#=======================================================================================================================
    SHRINK files
=======================================================================================================================#>
$dbNames = @()
$query = "select name, DATEDIFF(month, create_date, getdate()) as age_months from sys.databases where database_id>4"
$Databases = (Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query)

foreach ($Database in $Databases) {
    $dbNames += $Database.name
    
    $query = "select name, filename, size*8/1024 as 'sizeMB' from ["+$Database.name+"].sys.sysfiles where groupid=0"
    $logFile= (Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query).name
    
        
    if ($Database.age_months -gt 12) {
        $size="1"
    } else {
        $size="100"
    }
    if ($logFile.sizeMB -gt $size) {
        $query = "USE ["+$Database.name+"]; ALTER DATABASE ["+$Database.name+"] SET RECOVERY SIMPLE; DBCC SHRINKFILE ('"+$logFile+"', "+$size+");  ALTER DATABASE ["+$Database.name+"] SET RECOVERY FULL"
        Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query
    }
}

<#=======================================================================================================================
    Looking for orphan files ( mdf or ldf files not linked to any database
=======================================================================================================================#>

# Find data and log folders
$query = "select top 1 [name] from [master].sys.databases where name like'%-%' and database_id>4"
$dbname = (Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query).name
$query = "select top 1 physical_name from ["+$dbname+"].sys.database_files where [state]=0 and [type]=1"
$logFolder = (Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query).physical_name
$query = "select top 1 physical_name from ["+$dbname+"].sys.database_files where [state]=0 and [type]=0"
$dataFolder = (Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query).physical_name
$folders = @()
$folders += (Split-Path $logFolder -Parent)+"\*.ldf"
$folders += (Split-Path $dataFolder -Parent)+"\*.mdf"

#======= Find orphan files =======
$orphanDatabases = @()
foreach($folder in $folders) {
    Write-Host $folder -BackgroundColor Gray -ForegroundColor Blue
    $files = (Get-ChildItem -Path $folder)
    foreach ($file in $files) {
        if ($file.BaseName -match "_log") {
            $dbNameFromFile = ($file.BaseName).Replace("_log","")
        }

        if (($dbNames -notcontains $dbNameFromFile) -and ($orphanDatabases -notcontains $dbNameFromFile)) {
            $orphanDatabases += $file.FullName
            Write-Host $file.FullName -ForegroundColor Yellow
            Move-Item -Path $file.FullName -Destination ($orfanFilesFolder+$file.BaseName) -Force
        } 
    }
}
