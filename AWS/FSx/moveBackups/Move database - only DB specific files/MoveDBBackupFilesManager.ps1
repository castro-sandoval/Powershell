param ( [Parameter(Position=0,mandatory=$true)] [int] $from_server_id, 
        [Parameter(Position=1,mandatory=$true)] [int] $to_server_id, 
        [Parameter(Position=2,mandatory=$true)] [string] $dbname)

        
Import-Module -Name ("C:\Dataops\bin\DFTlibrary.dll")
$sqllogin = Get-sqllogin
$sqlpwrd  = Get-sqlpwrd

$masterserver="10.232.123.122,50000"

$LogFile="C:\Dataops\bin\log\MoveDBBakManager_"+(Get-date).ToString("yyyyMMddHHmmss")+".log"
$runtime_start = (Get-Date)


$MPP=15 # Max Process Parallellism
$MaxCPU=85

$i=1
$BackupTypes=@("FULL","DIFF","LOG")
$PS_File="C:\Dataops\bin\MoveDBBackupFiles.ps1"

$dateToCheck = (Get-Date).AddDays(-$retentionDays).AddDays(-1)

Add-Content -Path $LogFile -Value ("Move DB backup files - Log file initiated at "+(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))
Add-Content -Path $LogFile -Value ("Master server = "+$masterserver)
Add-Content -Path $LogFile -Value ("from_server_id = "+$from_server_id.ToString())
Add-Content -Path $LogFile -Value ("to_server_id = "+$to_server_id.ToString())
Add-Content -Path $LogFile -Value ("dbname = "+$dbname)
#=========================================================================================================================================

$query="SELECT [Server_name], [FULL_backup_device_path] FROM targets.BackupPolicy where server_id="+$from_server_id.ToString()
$queryResults = Invoke-Sqlcmd -ServerInstance $masterserver -Username $sqllogin -Password $sqlpwrd -Database "DATAOPS" -Query $query

$server_name = $queryResults.Server_name
$fromDevicePath = $queryResults.FULL_backup_device_path

$query="SELECT [FULL_backup_device_path] FROM targets.BackupPolicy where server_id="+$to_server_id.ToString()
$queryResults = Invoke-Sqlcmd -ServerInstance $masterserver -Username $sqllogin -Password $sqlpwrd -Database "DATAOPS" -Query $query

$toDevicePath = $queryResults.FULL_backup_device_path
#=========================================================================================================================================
$destination=$toDevicePath+"Backups\"+$server_name

Add-Content -Path $LogFile -Value ("fromDevicePath = "+$fromDevicePath)
Add-Content -Path $LogFile -Value ("toDevicePath = "+$toDevicePath)

Add-Content -Path $LogFile -Value ("")
Add-Content -Path $LogFile -Value ("destination = "+$destination)
Add-Content -Path $LogFile -Value ("MPP = "+$MPP.ToString())
Add-Content -Path $LogFile -Value ("PS_File = "+$PS_File)

if (!(Test-Path -Path $destination)) {
    Add-Content -Path $LogFile -Value ("Creating directory "+$destination)
    New-Item -Path $destination -ItemType Directory
} else {
    Add-Content -Path $LogFile -Value ("Directory "+$destination+" found. Not creating.")
}
Add-Content -Path $LogFile -Value ("")
  

$cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
Add-Content -Path $LogFile -Value ("cpuUsage = "+$cpuUsage.ToString())

Do {
    $day_yyyymmdd=$dateToCheck.ToString("yyyyMMdd")

    foreach($BackupType in $BackupTypes) {

        Do {
            ################ Control multithreading throutle #################
            $running=@(Get-Process | Where-Object({$_.name -like "powershell*"})).count-1
            $cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
            Add-Content -Path $LogFile -Value ("cpuUsage = "+$cpuUsage.ToString()+"     running = "+$running.ToString())

            Write-Host ("$BackupType   $day_yyyymmdd       CPU=$cpuUsage    running=$running    MPP=$MPP") -ForegroundColor Yellow
            Start-Sleep -Seconds 2
        

        } while (($cpuUsage -gt $MaxCPU) -or ($running -ge $MPP))


        Write-Host ("$BackupType   $day_yyyymmdd       CPU=$cpuUsage    running=$running    MPP=$MPP") -ForegroundColor Green
        ###### ready to request new process
    
        $ps_cmd = $PS_File+" -backupType '"+$BackupType+"' -servername '"+$servername+"' -dbname '"+$dbname+"' -day_yyyymmdd '"+$day_yyyymmdd+"' -fromDevicePath '"+$fromDevicePath+"' -toDevicePath '"+$toDevicePath+"'"

        Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" - "+$ps_cmd)
        Write-Host ($ps_cmd) -ForegroundColor White

        Start-Process powershell.exe -ArgumentList $ps_cmd -WindowStyle Hidden

  
        $i++
    }

    $dateToCheck=$dateToCheck.AddDays(1)

} while ($dateToCheck -le (Get-date))

#   update [Backups].[Server_Policy] set [is_moving_devices]=0 where [server_id]=37

Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" - End of restoration")
Add-Content -Path $LogFile -Value ("")
Add-Content -Path $LogFile -Value ("Start time   : "+$runtime_start.ToString("yyyy-MM-dd HH:mm:ss"))
$runtime_finish = (Get-Date)
Add-Content -Path $LogFile -Value ("Finish time  : "+$runtime_finish.ToString("yyyy-MM-dd HH:mm:ss"))
Add-Content -Path $LogFile -Value ("Total runtime: "+(NEW-TIMESPAN –Start $runtime_start –End $runtime_finish).ToString()+" (Hours:Min:Sec.ms)")
Add-Content -Path $LogFile -Value ("Total calls: "+$i.ToString()+" processes")
Add-Content -Path $LogFile -Value ("")

