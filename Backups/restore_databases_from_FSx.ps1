<# run on master server #>
$binFolder="C:\Dataops\bin"
Clear-Host

Import-Module -Name ($binFolder+"\DFTlibrary.dll")

$awsaccessKey = Get-awsaccessKey
$awssecretkey = Get-awssecretkey
$sqllogin = Get-sqllogin
$sqlpwrd = Get-sqlpwrd


$Device = "\\amznfsxmd8zsrjo.scg.guru\share\" 
$server_name="IP-0AE87D14\PLATFORM"

$catalogs=@("f4ef1243-edcf-475f-88bb-bdca04c6df30")


<#
$catalogs = @("0fbade85-08f2-43ad-9c23-fb055895bf3b",
"160a6b6d-0584-42fd-b4af-11473cf39667",
"170433dc-b6bf-460f-8595-65ac635c1fc1",
"3560c49f-e479-4219-92ac-9385ec1618ab",
"463d31dd-ed2f-4d1e-aec6-67154644b3a5",
"596d1bc7-d0cd-44e6-a2e0-929cbb5a528b",
"5a38ac12-d265-432a-9f90-6325fbc9ff60",
"75d6ba64-0ff8-4853-bcb9-bcb5c8836e13",
"8f98f21f-753d-485b-85c5-9514870c117e",
"98b514cf-e32f-4651-bdb2-c2d25cb9fd58",
"a37c8931-f699-4971-bc66-5e3fad6c378f",
"b8c5dfa1-a947-46c3-ac44-863c6090cd5a",
"dccb734b-79f9-4993-98a8-a706aebb2c9c",
"f4ef1243-edcf-475f-88bb-bdca04c6df30")
#>



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
                Add-Content -Path $output_file -value ("RESTORE DATABASE ["+$catalog+"] FROM DISK = '"+$BackupPolicy_FSxFolder+"\"+$RestoreFiles[0]+"' WITH  FILE = 1, NOUNLOAD, STATS = 1")
            }
      "110" { # Only FULL
                Add-Content -Path $output_file -value ("RESTORE DATABASE ["+$catalog+"] FROM DISK = '"+$BackupPolicy_FSxFolder+"\"+$RestoreFiles[0]+"' WITH  FILE = 1, NORECOVERY, NOUNLOAD, STATS = 1")
                Add-Content -Path $output_file -value ("RESTORE DATABASE ["+$catalog+"] FROM DISK = '"+$BackupPolicy_FSxFolder+"\"+$RestoreFiles[1]+"' WITH  FILE = 1,  RECOVERY, NOUNLOAD, STATS = 1")
            }
      "111" {
                Add-Content -Path $output_file -value ("RESTORE DATABASE ["+$catalog+"] FROM DISK = '"+$BackupPolicy_FSxFolder+"\"+$RestoreFiles[0]+"' WITH  FILE = 1, NORECOVERY, NOUNLOAD, STATS = 1")
                Add-Content -Path $output_file -value ("RESTORE DATABASE ["+$catalog+"] FROM DISK = '"+$BackupPolicy_FSxFolder+"\"+$RestoreFiles[1]+"' WITH  FILE = 1,  NORECOVERY, NOUNLOAD, STATS = 1")
                For ($i=0; $i -lt $LogFiles.Count; $i++) {
                    if ($i -lt ($LogFiles.Count-1)) {
                        Add-Content -Path $output_file -value ("RESTORE LOG["+$catalog+"] FROM DISK = '"+$BackupPolicy_FSxFolder+"\"+$LogFiles[$i]+"' WITH  FILE = 1,  NORECOVERY, NOUNLOAD, STATS = 1")
                    } else {
                        Add-Content -Path $output_file -value ("RESTORE LOG["+$catalog+"] FROM DISK = '"+$BackupPolicy_FSxFolder+"\"+$LogFiles[$i]+"' WITH  FILE = 1,  RECOVERY, NOUNLOAD, STATS = 1")
                    }
                }
             }

      }
}


$map_path = $BackupPolicy_FSxFolder
$NewDrive=((68..90 | %{$L=[char]$_; if ((gdr).Name -notContains $L) {$L}})[0])
$drive=New-PSDrive -Name $NewDrive -PSProvider FileSystem -Root $map_path -Persist
    
$BackupTypes = @('FULL','DIFF','LOG')


foreach($catalog in $catalogs) {
    Write-Host ("Checking "+$catalog)
    $output_file = "C:\temp\restore_"+$catalog+".sql"
    if (Test-Path -Path $output_file) {
        Remove-Item -Path $output_file -Force
    }
    Add-Content -Path $output_file -value ("DROP DATABASE if exists ["+$catalog+"];")

    $BackupFound = @(0,0,0)
    $BackupTime = @($null,$null,$null)
    $FSxFiles=@()
    $LogFiles=@()

    $RestoreFiles=@($null,$null,$null)
    for ($BT=0;$BT -le 2;$BT++)
    {
        if (($BT -eq 1) -and ($BackupFound[0] -eq 0))
        {
            Add-Content -Path $output_file -value ("FULL backup not found between "+(GET-DATE).ToString()+" and "+(Get-date).AddDays(- $SearchBakcupsLastDays).ToString())
            Break;
        }

        $Date = (Get-Date)
        $OldestBackup = (Get-date).AddDays(- $SearchBakcupsLastDays)
        while (($FSxFiles.Count -eq 0) -and ($Date -ge $OldestBackup))
                                                                                                                                                                                                                            {
            $FSxFileFilter=$drive.Name+":\"+$BackupTypes[$BT]+"_"+$Date.ToString("yyyyMMdd")+"*"+$catalog+".bak"
            $FSxFiles = (Get-ChildItem -Name $FSxFileFilter)

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
                                #Add-Content -Path $output_file -value ($FSxFiles[$i]+" / "+(BAKTimestampToDatetime -BackupFileName $FSxFiles[$i].ToString()))
                                $LogFiles+=$FSxFiles[$i]
                                $BackupFound[$BT]=1
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

    
    for ($BT=0;$BT -le 2;$BT++)
                                                                                            {
    if ($BackupFound[$BT] -eq 1)
    {
        Add-Content -Path $output_file -value ("================== "+$BackupTypes[$BT]+"================== ")
        
        if ($BT -eq 2) # LOG
        {
            foreach($LogFile in $LogFiles)
            {
                $LogTime = (BAKTimestampToDatetime -BackupFileName $LogFile)
                if ($LogTime -gt $BackupTime[1])
                {
                    Add-Content -Path $output_file -value ($LogFile+" ("+$LogTime.ToString()+")")
                    Add-Content -Path $output_file -value ($BackupPolicy_FSxFolder+"\"+$LogFile)
                }
            }
        }
        else
        {
            Add-Content -Path $output_file -value ($RestoreFiles[$BT]+" ("+$BackupTime[$BT].ToString()+")") 
            Add-Content -Path $output_file -value ($BackupPolicy_FSxFolder+"\"+$RestoreFiles[$BT])
        }
    }
    }
    Add-Content -Path $output_file -value ("============================================================================== ")
    $RestoreType=$BackupFound[0].ToString()+$BackupFound[1].ToString()+$BackupFound[2].ToString()
    Add-Content -Path $output_file -value ("GenerateRestoreSQL -RestoreType "+$RestoreType)
    Add-Content -Path $output_file -value ($LogFiles.Count.ToString()+" log files")

    GenerateRestoreSQL -RestoreType $RestoreType
    Add-Content -Path $output_file -value ("")
}

Remove-PSDrive -Name $NewDrive


Write-Host $output_file 