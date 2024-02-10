$Username="***" 
$Password="******"
Clear-Host
$instances = (Get-Service -Name "*MSSQL*" | Where-Object {(($_.ServiceName -eq "MSSQLSERVER") -or ($_.ServiceName -like "MSSQL$*")) -and ($_.Status -eq "Running")} | Select-Object -Property Name)

foreach($instance in $instances.Name) {

    $instanceName=$instance.Replace("MSSQL$",$env:COMPUTERNAME+"\").Replace("MSSQLSERVER",$env:COMPUTERNAME+"\")
    
    $query = "SELECT SERVERPROPERTY('InstanceDefaultLogPath') as LogFolder"
    $logFolder = (Invoke-Sqlcmd -ServerInstance $instanceName -Username "sa" -Password "llama123!" -Database "master" -Query $query).ItemArray[0]
    $logFile = $logFolder+"\ShrinkOperation_"+(Get-Date).ToString("yyyyMMddHHmmss")+".log"
    if (!(Test-Path -Path $logFolder)) {
        New-Item -Path $logFolder -ItemType Directory -Force
    }
    Add-Content -Path $logFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" SHRINK operation - SQL Instance: "+$instanceName+"   Instance Log folder: "+$logFolder )
    Add-Content -Path $logFile -Value "======================================================================================================================"

    <#=======================================================================================================================
        SHRINK files
    =======================================================================================================================#>
    $query = "select name, DATEDIFF(month, create_date, getdate()) as age_months, recovery_model_desc as recovery_model from sys.databases where database_id>4 and [state]=0"
    $Databases = (Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query)

    foreach ($Database in $Databases) {
        Add-Content -Path $logFile -Value ("Checking database ["+$Database.name+"]")
        Add-Content -Path $logFile -Value ("     Database age: "+$Database.age_months.ToString()+" months old")
        Add-Content -Path $logFile -Value ("     Recovery model: "+$Database.recovery_model)
        $query = "select name, filename, size*8/1024 as 'sizeMB' from ["+$Database.name+"].sys.sysfiles where groupid=0"
        $TransogFile= (Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query)
        Add-Content -Path $logFile -Value ("     Logical name: "+$TransogFile.name)
        Add-Content -Path $logFile -Value ("     Size: "+$TransogFile.sizeMB.ToString()+" MB")
        Add-Content -Path $logFile -Value ("     Path: "+$TransogFile.filename)
        if ($Database.age_months -gt 12) {
            $size="5"
        } else {
            $size="100"
        }
        if ($TransogFile.sizeMB -gt $size) {
            Add-Content -Path $logFile -Value ("     Log file target size: "+$size.ToString()+" MB")
            $query = "USE ["+$Database.name+"]; ALTER DATABASE ["+$Database.name+"] SET RECOVERY SIMPLE WITH NO_WAIT; DBCC SHRINKFILE ('"+$TransogFile.name+"', "+$size+")"
            Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query | Out-Null
            Add-Content -Path $logFile -Value ("     "+$query)

            # return the database to previous recovery model
            if ($Database.recovery_model -ne "SIMPLE") {
                $query = "USE ["+$Database.name+"]; ALTER DATABASE ["+$Database.name+"] SET RECOVERY "+$Database.recovery_model
                Invoke-Sqlcmd -ServerInstance $instanceName -Username $Username -Password $Password -Database "master" -Query $query
                Add-Content -Path $logFile -Value ("     "+$query)
                
            }
        } else {
            Add-Content -Path $logFile -Value ("     Log file current size: "+$TransogFile.sizeMB.ToString()+" MB -> Size is ok! Not shrinking")
        }
    }
}
