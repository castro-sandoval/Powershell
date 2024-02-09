param ( [Parameter(Position=0,mandatory=$true)] [int] $server_id, 
        [Parameter(Position=1,mandatory=$true)] [string] $new_policy_id, 
        [Parameter(Position=2,mandatory=$true)] [string] $servername, 
        [Parameter(Position=3,mandatory=$true)] [int] $retentionDays, 
        [Parameter(Position=4,mandatory=$true)] [string] $fromDevicePath, 
        [Parameter(Position=5,mandatory=$true)][string] $toDevicePath )

        <#
Import-Module -Name ("C:\Dataops\bin\DFTlibrary.dll")
$sqllogin = Get-sqllogin
$sqlpwrd  = Get-sqlpwrd

INSERT INTO [Backups].[Devices_Moving_History]
([server_id],[server_name],[FromDeviceName],[FromDevicePath],[FromDeviceType],[ToDeviceName],[ToDevicePath],[ToDeviceType],[is_running])
VALUES ()

update [Backups].[Server_Policy] set parent_id=-9223372036854775804  where server_id=37
  

  #>

$LogFile="C:\Dataops\bin\log\MoveBakManager_"+(Get-date).ToString("yyyyMMddHHmmss")+".log"
$runtime_start = (Get-Date)

$destination=$toDevicePath+"Backups\"+$server_name
$MPP=15 # Max Process Parallellism
$MaxCPU=85

$i=1
$BackupTypes=@("FULL","DIFF","LOG")
$PS_File="C:\Dataops\bin\MoveBackupFiles.ps1"

$dateToCheck = (Get-Date).AddDays(-$retentionDays).AddDays(-1)

Add-Content -Path $LogFile -Value ("Move backup files - Log file initiated at "+(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))
Add-Content -Path $LogFile -Value ("server_id = "+$server_id.ToString())
Add-Content -Path $LogFile -Value ("new_policy_id = "+$new_policy_id.ToString())
Add-Content -Path $LogFile -Value ("servername = "+$servername)
Add-Content -Path $LogFile -Value ("retentionDays = "+$retentionDays.ToString())
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
    
        $ps_cmd = $PS_File+" -backupType '"+$BackupType+"' -servername '"+$servername+"' -day_yyyymmdd '"+$day_yyyymmdd+"' -fromDevicePath '"+$fromDevicePath+"' -toDevicePath '"+$toDevicePath+"'"

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

