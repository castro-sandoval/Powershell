$binFolder="C:\Dataops\bin"
Clear-Host

Import-Module -Name ($binFolder+"\DFTlibrary.dll")

$awsaccessKey = Get-awsaccessKey
$awssecretkey = Get-awssecretkey
$sqllogin = Get-sqllogin
$sqlpwrd = Get-sqlpwrd


$Device = "\\amznfsxumd0wg1i.scg.guru\share\"
$server_name="IP-0AE87D75"
$catalog = "SessionAsset_b417d12d-c68b-49d2-bf92-b12541bc727c"




$BackupPolicy_FSxFolder=$Device+"Backups\"+$server_name

//$SearchBakcupsLastDays = 60

Function BAKTimestampToDatetime
{
  param
  (
    [string] $BackupFileName # example "FULL_20211220013235_dbname.bak"
  )
  return [datetime]::parseexact($BackupFileName.Split("_")[1], 'yyyyMMddHHmmss', $null)
}


Function GenerateRestoreSQL
{
    param
      (
        [string] $RestoreType,
        [string[]] $logfiles
      )
      switch($RestoreType)
      {
      "100" { # Only FULL
                write-host ("RESTORE DATABASE ["+$catalog+"] FROM DISK = '"+$BackupPolicy_FSxFolder+"\"+$RestoreFiles[0]+"' WITH  FILE = 1, NOUNLOAD, STATS = 1")
            }
      "110" { # FULL+DIF+no log
                write-host ("RESTORE DATABASE ["+$catalog+"] FROM DISK = '"+$BackupPolicy_FSxFolder+"\"+$RestoreFiles[0]+"' WITH  FILE = 1, NORECOVERY, NOUNLOAD, STATS = 1")
                write-host ("RESTORE DATABASE ["+$catalog+"] FROM DISK = '"+$BackupPolicy_FSxFolder+"\"+$RestoreFiles[1]+"' WITH  FILE = 1, RECOVERY, NOUNLOAD, STATS = 1")
            }
      "111" { # FULL+DIF+LOG
                write-host ("RESTORE DATABASE ["+$catalog+"] FROM DISK = '"+$BackupPolicy_FSxFolder+"\"+$RestoreFiles[0]+"' WITH  FILE = 1, NORECOVERY, NOUNLOAD, STATS = 1")
                write-host ("RESTORE DATABASE ["+$catalog+"] FROM DISK = '"+$BackupPolicy_FSxFolder+"\"+$RestoreFiles[1]+"' WITH  FILE = 1, NORECOVERY, NOUNLOAD, STATS = 1")
                $lastLog = $logfiles.Count-1
                $logcount = 0
                foreach($logfile in $logfiles) {
                    if ($logcount -eq $lastlog) {
                        write-host ("RESTORE LOG ["+$catalog+"] FROM DISK = '"+$BackupPolicy_FSxFolder+"\"+$logfile+"' WITH FILE=1, RECOVERY, NOUNLOAD") -ForegroundColor yellow
                    } else {
                        write-host ("RESTORE LOG ["+$catalog+"] FROM DISK = '"+$BackupPolicy_FSxFolder+"\"+$logfile+"' WITH FILE=1, NORECOVERY, NOUNLOAD") -ForegroundColor Green
                    }
                    
                    $logcount++
                }
                
            }
      }
}


$map_path = $BackupPolicy_FSxFolder
$NewDrive=((68..90 | %{$L=[char]$_; if ((gdr).Name -notContains $L) {$L}})[0])
$drive=New-PSDrive -Name $NewDrive -PSProvider FileSystem -Root $map_path -Persist
    
$BackupTypes = @('FULL','DIFF','LOG')
$BackupFound = @(0,0,0)
$BackupTime = @($null,$null,$null)
$FSxFiles=@()
$LogFiles=@()

$RestoreFiles=@($null,$null,$null)

#================================== FULL ================================
$BT=0
$FSxFileFilter=$drive.Name+":\"+$BackupTypes[$BT]+"_*"+$dbname+".bak"
$FULL_backupFile =(Get-ChildItem -Path $FSxFileFilter | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | select Name).Name
$FULL_backupTimestamp = [datetime]::parseexact($FULL_backupFile.Split("_")[1], 'yyyyMMddHHmmss', $null)

$BackupFound[$BT]=1
$BackupTime[$BT] =$FULL_backupTimestamp
$FSxFiles[$BT]   =$FULL_backupFile

write-host($FULL_backupFile) -ForegroundColor Green
write-host($FULL_backupTimestamp) -ForegroundColor Green


#================================== DIFF ================================
$BT=1
$FSxFileFilter=$drive.Name+":\"+$BackupTypes[$BT]+"_*"+$dbname+".bak"
$DIFF_backupFile =(Get-ChildItem -Path $FSxFileFilter | Where-Object {($_.LastWriteTime -gt $FULL_backupTimestamp)} | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | select Name).Name
$DIFF_backupTimestamp = [datetime]::parseexact($DIFF_backupFile.Split("_")[1], 'yyyyMMddHHmmss', $null)

$BackupFound[$BT]=1
$BackupTime[$BT] =$DIFF_backupTimestamp
$FSxFiles[$BT]   =$DIFF_backupFile

write-host($DIFF_backupFile) -ForegroundColor cyan
write-host($DIFF_backupTimestamp) -ForegroundColor cyan

#================================== TRN ================================
$BT=2
$FSxFileFilter=$drive.Name+":\"+$BackupTypes[$BT]+"_*"+$dbname+".bak"
$TRN_backupfiles = (Get-ChildItem -Path $FSxFileFilter | Where-Object {($_.LastWriteTime -gt $DIFF_backupTimestamp)} | Sort-Object LastWriteTime).Name
foreach($TRN_backupfile in $TRN_backupfiles) {
    write-host($TRN_backupfile) -ForegroundColor yellow
    $TRN_backupTimestamp = [datetime]::parseexact($TRN_backupfile.Split("_")[1], 'yyyyMMddHHmmss', $null)
    write-host($TRN_backupTimestamp) -ForegroundColor yellow

}


     
    


Remove-PSDrive -Name $NewDrive

for ($BT=0;$BT -le 2;$BT++)
{
    if ($BackupFound[$BT] -eq 1)
    {
        write-host("================== "+$BackupTypes[$BT]+"================== ")
        
        if (($BT -eq 2) -and ($BackupFound[2] -eq 1)) # LOG
        {
            
            foreach($LogFile in $LogFiles)
            {
                $LogTime = (BAKTimestampToDatetime -BackupFileName $LogFile)
                if ($LogTime -gt $BackupTime[1])
                {
                    write-host($LogFile+" ("+$LogTime.ToString()+")") -ForegroundColor Cyan
                    write-host($BackupPolicy_FSxFolder+"\"+$LogFile)
                    
                }
            }
        }
        else
        {
            write-host($RestoreFiles[$BT]+" ("+$BackupTime[$BT].ToString()+")") -ForegroundColor Yellow
            write-host($BackupPolicy_FSxFolder+"\"+$RestoreFiles[$BT])
        }
    }
}
write-host("============================================================================== ")
write-host($BackupFound[0].ToString()+$BackupFound[1].ToString()+$BackupFound[2].ToString()) -ForegroundColor Red -BackgroundColor White

GenerateRestoreSQL -RestoreType ($BackupFound[0].ToString()+$BackupFound[1].ToString()+$BackupFound[2].ToString()) -logfiles $logfiles
write-host("")
