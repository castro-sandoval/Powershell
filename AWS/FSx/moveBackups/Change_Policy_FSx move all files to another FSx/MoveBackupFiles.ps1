param ([Parameter(Position=0,mandatory=$true)]
       [string] $backupType, 
       [Parameter(Position=1,mandatory=$true)]
       [string] $servername, 
       [Parameter(Position=2,mandatory=$true)]
       [string] $day_yyyymmdd, 
       [Parameter(Position=3,mandatory=$true)]
       [string] $fromDevicePath, 
       [Parameter(Position=4,mandatory=$true)]
       [string] $toDevicePath )

Import-Module -Name ("C:\Dataops\bin\DFTlibrary.dll")
$sqllogin = Get-sqllogin
$sqlpwrd  = Get-sqlpwrd

$LogFile = "C:\Dataops\bin\log\MoveBackups_"+$backupType+"_"+$day_yyyymmdd+"_"+(Get-Date).ToString("yyyyMMddHHmmss")+".log"
Add-Content -Path $LogFile -Value ("backupType = "+$backupType)
Add-Content -Path $LogFile -Value ("servername = "+$servername)
Add-Content -Path $LogFile -Value ("day_yyyymmdd = "+$day_yyyymmdd)
Add-Content -Path $LogFile -Value ("fromDevicePath = "+$fromDevicePath)
Add-Content -Path $LogFile -Value ("toDevicePath = "+$toDevicePath)

$destination=$toDevicePath+"Backups\"+$servername+"\"


if(!(Test-Path -Path $destination)) {
    Add-Content -Path $LogFile -Value ("** ERROR **  Destination folder "+$destination+" not found.")
    exit
}
   
$Filter=$backupType+"_"+$day_yyyymmdd+"*.bak"

$location=$fromDevicePath+"Backups\"+$servername+"\"+$Filter

Add-Content -Path $LogFile -Value ("Moving from "+$FullPath+" To "+$destination)
$start = Get-Date



#get-childitem -Path $FullPath  | Move-Item -Destination $destination
Do {
    Do {
        $cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
        Add-Content -Path $LogFile -Value ("cpuUsage =  "+$cpuUsage.ToString)
        Start-Sleep -Seconds 3
    } while ($cpuUsage -gt 75)

    $files = Get-ChildItem -Path $location | Select-Object -Last 50
    Add-Content -Path $LogFile -Value ("Found "+$files.count.ToString()+" files to move")
    foreach($file in $files) {
        $NewFileLocation = $destination+"\"+$file.Name
        Add-Content -Path $LogFile -Value ("Moving "+$file.Fullname+"  to "+ $NewFileLocation)
        Move-Item -Path $file.Fullname -Destination $destination
    }
    

} while ($files.count -gt 0)




Add-Content -Path $LogFile -Value ("Finished processing "+$Filter)
Add-Content -Path $LogFile -Value ("Duration: "+(NEW-TIMESPAN –Start $start –End (Get-Date)).ToString()+" (Hours:Min:Sec.ms)")

Add-Content -Path $LogFile -Value ("======================= finish =======================")