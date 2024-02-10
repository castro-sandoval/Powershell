Clear-Host
Import-Module -Name ("C:\Dataops\bin\DFTlibrary.dll")
$AccessKey = Get-awsaccessKey
$SecretKey = Get-awssecretkey
$sqllogin = Get-sqllogin
$sqlpwrd  = Get-sqlpwrd

$Device = "\\amznfsxmd8zsrjo.scg.guru\share\" # PROD
$server_name="I-0CC0CFB3D575D"
$catalog = "00cc8180-79f1-4f71-b334-19c320a1aabf"
$BackupPolicy_FSxFolder=$Device+"Backups\"+$server_name

$SearchBakcupsLastDays = 10

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
        [string] $RestoreType
      )
      switch($RestoreType)
      {
      "100" { # Only FULL
                write-host ("RESTORE DATABASE ["+$catalog+"] FROM DISK = '"+$BackupPolicy_FSxFolder+"\"+$RestoreFiles[0]+"' WITH  FILE = 1, move files,  NOUNLOAD, STATS = 1")
            }
      "110" { # Only FULL
                write-host ("RESTORE DATABASE ["+$catalog+"] FROM DISK = '"+$BackupPolicy_FSxFolder+"\"+$RestoreFiles[0]+"' WITH  FILE = 1, move files,  NORECOVERY, NOUNLOAD, STATS = 1")
                write-host ("RESTORE DATABASE ["+$catalog+"] FROM DISK = '"+$BackupPolicy_FSxFolder+"\"+$RestoreFiles[1]+"' WITH  FILE = 1,  RECOVERY, NOUNLOAD, STATS = 1")
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
for ($BT=0;$BT -le 2;$BT++)
{
    if (($BT -eq 1) -and ($BackupFound[0] -eq 0))
    {
        Write-Host("FULL backup not found between "+(GET-DATE).ToString()+" and "+(Get-date).AddDays(- $SearchBakcupsLastDays).ToString())
        Break;
    }

    $Date = (Get-Date)
    $OldestBackup = (Get-date).AddDays(- $SearchBakcupsLastDays)
    while (($FSxFiles.Count -eq 0) -and ($Date -ge $OldestBackup))
    {
            $FSxFileFilter=$drive.Name+":\"+$BackupTypes[$BT]+"_"+$Date.ToString("yyyyMMdd")+"*"+$catalog+".bak"
            #write-host ($FSxFileFilter)

            $FSxFiles = (Get-ChildItem -Name $FSxFileFilter)
            #write-host ($FSxFileFilter+" = "+$FSxFiles.Count.ToString()+" found") -ForegroundColor Green

            if ($FSxFiles.Count -gt 0)
            {
                Switch($BT)
                {
                    0 # FULL
                    {
                        $RestoreFileName=$FSxFiles
                    }

                    1 # DIFF
                    {
                        if ($FSxFiles.Count -gt 1)
                        {
                            $LatestBackupTime=(BAKTimestampToDatetime -BackupFileName $FSxFiles[0].ToString())
                            $RestoreFileName = $FSxFiles[0].ToString()

                            For ($i=1; $i -lt $FSxFiles.Count; $i++) 
                            {
                            
                                if ($LatestBackupTime -lt (BAKTimestampToDatetime -BackupFileName $FSxFiles[$i].ToString()))
                                {
                                    $RestoreFileName = $FSxFiles[$i].ToString()
                                    $LatestBackupTime=(BAKTimestampToDatetime -BackupFileName $FSxFiles[$i].ToString())
                                }
                            }
                        }
                        else
                        {
                            $RestoreFileName = $FSxFiles.ToString()
                        }
                        $BackupTime[$BT]=$LatestBackupTime
                        $BackupFound[$BT]=1
                    }

                    2 # LOG
                    {
                        For ($i=0; $i -lt $FSxFiles.Count; $i++) 
                        {
                            if ((BAKTimestampToDatetime -BackupFileName $FSxFiles[$i]) -gt $BackupTime[1])
                            {
                                Write-Host($FSxFiles[$i]+" / "+(BAKTimestampToDatetime -BackupFileName $FSxFiles[$i].ToString())) -BackgroundColor Cyan -ForegroundColor DarkRed
                                $LogFiles+=$FSxFiles[$i]
                            }
                        }
                    }


                } # Switch


                $BackupFound[$BT]=1
                $RestoreFiles[$BT]=$RestoreFileName
                $BackupTime[$BT]=(BAKTimestampToDatetime -BackupFileName $RestoreFileName)

            } # if ($FSxFiles.Count -gt 0)





            $Date = $Date.AddDays(-1)
    }
    $FSxFiles=@()
}

Remove-PSDrive -Name $NewDrive

for ($BT=0;$BT -le 2;$BT++)
{
    if ($BackupFound[$BT] -eq 1)
    {
        write-host("================== "+$BackupTypes[$BT]+"================== ")
        
        if ($BT -eq 2) # LOG
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
write-host("")
#GenerateRestoreSQL -RestoreType ($BackupFound[0].ToString()+$BackupFound[1].ToString()+$BackupFound[2].ToString())
#write-host("")
