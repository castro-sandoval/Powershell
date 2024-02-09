Clear-Host

$servername='I-0450E7DFFA37A'
$fromDevicePath="\\amznfsxumd0wg1i.scg.guru\share\"
$toDevicePath="\\amznfsxmzz6t0eu.scg.guru\share\"

$startDate = "20230215"
$endDate   = "20230228"

<##################################################################################################################################################>



$LogFileFolder="C:\Dataops\bin\logs\"
$LogFile=$LogFileFolder+"MoveBakManager_"+(Get-date).ToString("yyyyMMddHHmmss")+".log"
$runtime_start = (Get-Date)

$destination=$toDevicePath+"Backups\"+$server_name
$MPP=6 # Max Process Parallellism
$MaxCPU=50

$i=1
$BackupTypes=@("FULL","DIFF","LOG")
$PS_File="C:\Dataops\bin\MoveBackupFiles.ps1"

$d_range_start = [datetime]::parseexact($startDate, 'yyyyMMdd', $null)
$d_range_end = [datetime]::parseexact($endDate, 'yyyyMMdd', $null)

if (!(Test-Path -Path $PS_File)) {
    write-host ($PS_File+" not found.")
    Exit
}
if (!(Test-Path -Path $LogFileFolder -PathType Container)) {
    New-Item -Path $LogFileFolder -ItemType Directory
}

Add-Content -Path $LogFile -Value ("Move backup files - Log file initiated at "+(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))
Add-Content -Path $LogFile -Value ("servername = "+$servername)
Add-Content -Path $LogFile -Value ("Date range = "+$startDate+" to "+$endDate)
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

$dateToCheck=$d_range_end

Do {
    $day_yyyymmdd=$dateToCheck.ToString("yyyyMMdd")

    foreach($BackupType in $BackupTypes) {

        Do {
            ################ Control multithreading throutle #################
            $running=@(Get-Process | Where-Object({$_.name -like "powershell*"})).count-1
            $cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
            Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" CPU Usage = "+$cpuUsage.ToString()+"     running = "+$running.ToString())

            Write-Host ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+"  $BackupType   $day_yyyymmdd       CPU=$cpuUsage    running=$running    MPP=$MPP") -ForegroundColor Yellow
            if ($cpuUsage -gt $MaxCPU) {
                Write-Host ("                 Waiting on CPU=$cpuUsage to be bellow $MaxCPU") -ForegroundColor gray
            }
            if ($running -ge $MPP) {
                Write-Host ("                 Waiting on PS processes running=$running to reduce under MPP=$MPP") -ForegroundColor gray
            }

            if ($running -gt 0) {
                Start-Sleep -Seconds 15
            }

        } while (($cpuUsage -gt $MaxCPU) -or ($running -ge $MPP))


        Write-Host ("$BackupType   $day_yyyymmdd       CPU=$cpuUsage    running=$running    MPP=$MPP") -ForegroundColor Green
        ###### ready to request new process
    
        $ps_cmd = $PS_File+" -backupType '"+$BackupType+"' -servername '"+$servername+"' -day_yyyymmdd '"+$day_yyyymmdd+"' -fromDevicePath '"+$fromDevicePath+"' -toDevicePath '"+$toDevicePath+"'"

        Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" - "+$ps_cmd)
        Write-Host ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+"   "+$ps_cmd) -ForegroundColor White

        Start-Process powershell.exe -ArgumentList $ps_cmd -WindowStyle Hidden

  
        $i++
    }

    $dateToCheck=$dateToCheck.AddDays(-1)

} while ($dateToCheck -ge $d_range_start)


Do {
    $running=@(Get-Process | Where-Object({$_.name -like "powershell*"})).count-1
    Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" - "+$running.ToString()+" processes still running...")
    Write-Host ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+"   "+$running.ToString()+" processes still running...") -ForegroundColor Green
    if ($running -gt 0) {
        Start-Sleep -Seconds 60
    }
} while ($running -gt 0)


Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" - End of restoration")
Add-Content -Path $LogFile -Value ("")
Add-Content -Path $LogFile -Value ("Start time   : "+$runtime_start.ToString("yyyy-MM-dd HH:mm:ss"))
$runtime_finish = (Get-Date)
Add-Content -Path $LogFile -Value ("Finish time  : "+$runtime_finish.ToString("yyyy-MM-dd HH:mm:ss"))
Add-Content -Path $LogFile -Value ("Total runtime: "+(NEW-TIMESPAN –Start $runtime_start –End $runtime_finish).ToString()+" (Hours:Min:Sec.ms)")
Add-Content -Path $LogFile -Value ("Total calls: "+$i.ToString()+" processes")
Add-Content -Path $LogFile -Value ("")

