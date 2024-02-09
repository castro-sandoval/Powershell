param ([Parameter(Position=0,mandatory=$true)]
       [string] $server_name, 
       [Parameter(Position=1,mandatory=$true)]
       [string] $tagname, 
       [Parameter(Position=2,mandatory=$true)]
       [string] $dbname, 
       [Parameter(Position=3,mandatory=$true)]
       [string] $fromDevicePath,
       [Parameter(Position=4,mandatory=$true)]
       [string] $logFilename,
       [Parameter(Position=5,mandatory=$true)]
       [string] $linked_server
       )

<##########################################################################################
    Parameters definition
##########################################################################################>
$ServerInstance="I-078BC7BDB4E42"  # local server
$RESTORE_CHECKS_db = "RESTORE_CHECKS";
$BackupPolicy_FSxFolder=$fromDevicePath+"Backups\"+$server_name
$SearchBakcupsLastDays = 20

<######################################################################################################
 - Function definitions
######################################################################################################>
Function BAKTimestampToDatetime
{
  param
  (
    [string] $BackupFileName
  )
  return [datetime]::parseexact($BackupFileName.Split("_")[1], 'yyyyMMddHHmmss', $null)
}

Function GenerateRestoreSQL
{
    param
      (
        [string] $RestoreType,
        [string[]] $backupFileSet,
        [string] $movefiles,
        [string] $catalog,
        [string] $fileLocation
      )
      Add-Content -Path $logFilename -Value ($log_line)
      Add-Content -Path $logFilename -Value ("    RESTORE T-SQL  - Type: "+(restoreTypesDesc -restoreType $RestoreType))
      Add-Content -Path $logFilename -Value ("backupFileSet = "+$backupFileSet.count.ToString())
      #Add-Content -Path $logFilename -Value ("movefiles = "+$movefiles)
      #Add-Content -Path $logFilename -Value ("catalog = "+$catalog)
      #Add-Content -Path $logFilename -Value ("fileLocation = "+$fileLocation)
      Add-Content -Path $logFilename -Value ($log_line)
      $GenerateRestoreSQL_return=@()
      

      switch($RestoreType)
      {
      "100" { # Only FULL
                $cmd = gem_RESTORE_cmd -type "DATABASE" -dbName $catalog -disk ($fileLocation+"\"+$backupFileSet[0]) -moveFiles $movefiles -recoveryType "" -stats "1"
                Add-Content -Path $logFilename -Value ($cmd)
                $GenerateRestoreSQL_return+=$cmd
            }
      "110" { # FULL+DIF+no log
                $cmd = gem_RESTORE_cmd -type "DATABASE" -dbName $catalog -disk ($fileLocation+"\"+$backupFileSet[0]) -moveFiles $movefiles -recoveryType "NORECOVERY" -stats "1"
                Add-Content -Path $logFilename -Value ($cmd)
                $GenerateRestoreSQL_return+=$cmd

                $cmd = gem_RESTORE_cmd -type "DATABASE" -dbName $catalog -disk ($fileLocation+"\"+$backupFileSet[1]) -moveFiles $movefiles -recoveryType "RECOVERY" -stats "1"
                Add-Content -Path $logFilename -Value ($cmd)
                $GenerateRestoreSQL_return+=$cmd
            }
      "111" { # FULL+DIF+LOG
                $cmd = gem_RESTORE_cmd -type "DATABASE" -dbName $catalog -disk ($fileLocation+"\"+$backupFileSet[0]) -moveFiles $movefiles -recoveryType "NORECOVERY" -stats "1"
                Add-Content -Path $logFilename -Value ($cmd)
                $GenerateRestoreSQL_return+=$cmd

                $cmd = gem_RESTORE_cmd -type "DATABASE" -dbName $catalog -disk ($fileLocation+"\"+$backupFileSet[1]) -moveFiles $movefiles -recoveryType "NORECOVERY" -stats "1"
                Add-Content -Path $logFilename -Value ($cmd)
                $GenerateRestoreSQL_return+=$cmd

                
                $lastFile = $backupFileSet.Count-1
                for($i=2; $i -le $lastFile; $i++) {
                    if ($i -eq $lastFile) {
                        $cmd = gem_RESTORE_cmd -type "LOG" -dbName $catalog -disk ($fileLocation+"\"+$backupFileSet[$i]) -moveFiles $movefiles -recoveryType "RECOVERY" -stats "1"
                    } else {
                        $cmd = gem_RESTORE_cmd -type "LOG" -dbName $catalog -disk ($fileLocation+"\"+$backupFileSet[$i]) -moveFiles $movefiles -recoveryType "NORECOVERY" -stats "1"
                    }
                    Add-Content -Path $logFilename -Value ($cmd)
                    $GenerateRestoreSQL_return+=$cmd
                }
                
            }
      }
      return $GenerateRestoreSQL_return
}

function gen_movefiles {
  param
  (
    [string] $DBname,
    [string] $FilePath
  )
  $query = "EXEC gen_restoremovefiles_cmd '"+$DBName+"', '"+$FilePath+"'"
  $resultset=Invoke-Sqlcmd -Query $query -ServerInstance $ServerInstance -Username $sqllogin -Password $sqlpwrd -Database "DATAOPS"
  return $resultset[0]
}

function gem_RESTORE_cmd {
param
  (
    [string] $type,
    [string] $dbName,
    [string] $disk,
    [string] $moveFiles,
    [string] $recoveryType,
    [string] $stats
  )
  return "RESTORE "+$type+" ["+$dbName+"] FROM DISK = '"+$disk+"' WITH  FILE = 1, "+$moveFiles+" "+$recoveryType+", NOUNLOAD, STATS = "+$stats
}

function restoreTypesDesc {
param
  (
    [string] $restoreType
  )
  switch($RestoreType)
      {
      "100" { $return_value="Only FULL"
            }
      "110" { $return_value="FULL+DIF+no log"
            }
      "111" { $return_value="FULL+DIF+LOG"
            }
    default {$return_value="invalid"}
      }

   return $return_value
}


function saveToDatabase {
param
  (
    [string] $server_name,
    [string] $tag_name,
    [string] $dbname,
    [String] $report_filepath,
    [int] $check_result
    )
    
    $query = "INSERT INTO [dbo].[restoreChecks] ([YMD] ,[server_name], [tag_name], [dbname], [checkReport], [check_result]) "
    $query+= "VALUES ("
    $query+= (GET-DATE).ToString("yyyyMMdd")+", "
    $query+= "'"+$server_name+"', "
    $query+= "'"+$tag_name+"', "
    $query+= "'"+$dbname+"', "
    $report = Get-Content -Path $report_filepath
    #$report = "Report from "+$report_filepath
    $query+= "'"+$report.Replace("'","")+"', "
    $query+= $check_result.ToString()+")"
    #Add-Content -Path $logFilename -Value $query
    Invoke-Sqlcmd -Query $query -ServerInstance $ServerInstance -Username $sqllogin -Password $sqlpwrd -Database $RESTORE_CHECKS_db



}


function getBackupFilesSet {
param
  (
    [string] $dbName,
    [string] $fromDevicePath,
    [int] $recovery_model
  )
    $backupFiles=@()

    Add-Content -Path $logFilename -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | getBackupFilesSet: recovery_model="+$recovery_model.ToString()+" (SIMPLE=3 FULL=1)")


    try {

        $map_path = $fromDevicePath
        $NewDrive=((68..90 | %{$L=[char]$_; if ((gdr).Name -notContains $L) {$L}})[0])
        $drive=New-PSDrive -Name $NewDrive -PSProvider FileSystem -Root $map_path -Persist -ErrorAction Stop

        if ($drive -ne "") {
            $BackupTypes = @('FULL','DIFF','LOG')
            $BT=0
            $FSxFileFilter=$drive.Name+":\"+$BackupTypes[$BT]+"_*"+$dbname+".bak"
            Add-Content -Path $logFilename -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | FSxFileFilter = "+$FSxFileFilter)

            $FULL_backupFile =(Get-ChildItem -Path $FSxFileFilter | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | select Name).Name

            if ($FULL_backupFile) {
                $backupFiles+=$FULL_backupFile
                $BackupFound[$BT]=1
                $FULL_backupTimestamp = [datetime]::parseexact($FULL_backupFile.Split("_")[1], 'yyyyMMddHHmmss', $null)


                Add-Content -Path $logFilename -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | "+$FULL_backupFile)
                #write-host($FULL_backupTimestamp) -ForegroundColor Green

                $BT=1
                $FSxFileFilter=$drive.Name+":\"+$BackupTypes[$BT]+"_*"+$dbname+".bak"
                $DIFF_backupFile =(Get-ChildItem -Path $FSxFileFilter | Where-Object {($_.LastWriteTime -gt $FULL_backupTimestamp)} | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | select Name).Name
                if ($DIFF_backupFile) {
                    $backupFiles+=$DIFF_backupFile
                    $BackupFound[$BT]=1
                    $DIFF_backupTimestamp = [datetime]::parseexact($DIFF_backupFile.Split("_")[1], 'yyyyMMddHHmmss', $null)

                    Add-Content -Path $logFilename -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | "+$DIFF_backupFile)
                    #write-host($DIFF_backupTimestamp) -ForegroundColor cyan


                    $BT=2
                    $FSxFileFilter=$drive.Name+":\"+$BackupTypes[$BT]+"_*"+$dbname+".bak"
                    $TRN_backupfiles = (Get-ChildItem -Path $FSxFileFilter | Where-Object {($_.LastWriteTime -gt $DIFF_backupTimestamp)} | Sort-Object LastWriteTime).Name
                    if ($TRN_backupfiles) {
                        $BackupFound[$BT]=1
                        foreach($TRN_backupfile in $TRN_backupfiles) {
                            Add-Content -Path $logFilename -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | "+$TRN_backupfile)
                            $TRN_backupTimestamp = [datetime]::parseexact($TRN_backupfile.Split("_")[1], 'yyyyMMddHHmmss', $null)
                            #write-host($TRN_backupTimestamp) -ForegroundColor yellow
                            $backupFiles+=$TRN_backupfile
                        }
                    } else {

                        Add-Content -Path $logFilename -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | No TRN_backupfile found")
                    }
                }
              }
        } else {
            Add-Content -Path $logFilename -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | ****** ERROR : Not able to map drive to FSx *********")
        }
        
    } #// try
    
    catch {
      Add-Content -Path $logFilename -Value ("==========================================================================================")
      
      Add-Content -Path $logFilename -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | An error occurred:")
      Add-Content -Path $logFilename -Value ($_.ScriptStackTrace)
      Add-Content -Path $logFilename -Value ("==========================================================================================")
      Add-Content -Path $logFilename -Value ($_.Exception)
      Add-Content -Path $logFilename -Value ("==========================================================================================")
      Add-Content -Path $logFilename -Value ($_.ErrorDetails)
      Add-Content -Path $logFilename -Value ("==========================================================================================")
      
    }
    finally {
        Remove-PSDrive -Name $NewDrive
    }

    Add-Content -Path $logFilename -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | Enf of getBackupFilesSet. "+$backupFiles.count.ToString()+" files found.")
    return $backupFiles
    
}


function restorationResult {
param
  (
    [string] $catalog
  )
    $query ="select [state]+[user_access] as [restore_result] from sys.databases where [name]='"+$catalog+"'"
    return (Invoke-Sqlcmd -Query $query -ServerInstance $ServerInstance -Username $sqllogin -Password $sqlpwrd -Database "master").restore_result

}



<######################################################################################################
 - Database checks
######################################################################################################>
function CheckTableCount {
param
  (
    [string] $catalog
  )
  Add-Content -Path $logFilename -Value ("CheckTableCount on "+$catalog)
  $query = "SELECT COUNT(*) as [tablecount] FROM ["+$catalog+"].sys.tables"
  Add-Content -Path $logFilename -Value ($query)
  try {
      $result=((Invoke-Sqlcmd -Query $query -ServerInstance $ServerInstance -Username $sqllogin -Password $sqlpwrd -Database "master")[0]).ToString()
  
      Add-Content -Path $logFilename -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | CheckTableCount="+$result.ToString())

      
  } catch {
    Add-Content -Path $logFilename -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | Error during CheckTableCount function: "+$Error[0].Exception.GetType().FullName)
    Add-Content -Path $logFilename -Value (".........................................................................................................................")
    Add-Content -Path $logFilename -Value ($Error[0].Exception)
    $result="error"
  }
  return $result
}

Function runCHECKDB {
param
  (
    [string] $catalog
  )

    $VerboseOutput=$logFilename.DirectoryName+"\"+$catalog+".out"
    $ErrorsFound = $FALSE

    $checkdbCmd = "DBCC CHECKDB (["+$dbname+"], NOINDEX) WITH PHYSICAL_ONLY"
    Add-Content -Path $logFilename -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | Running "+$checkdbCmd)

    if (Test-Path -Path $VerboseOutput) {
        Remove-Item -Path $VerboseOutput -Force
    }
    #Add-Content -Path $VerboseOutput -Value $checkdbCmd
    Invoke-Sqlcmd -Query $checkdbCmd -ServerInstance $ServerInstance -Username $sqllogin -Password $sqlpwrd -Database "master" -Verbose 4> $VerboseOutput
    $CheckDB_Results = Get-Content -Path $VerboseOutput
    Add-Content -Path $logFilename -Value "............................................................................................................."
    Add-Content -Path $logFilename -Value $CheckDB_Results
    Add-Content -Path $logFilename -Value "............................................................................................................."

    if (Test-Path -Path $VerboseOutput) {
        Remove-Item -Path $VerboseOutput -Force
    }

    # Verify CHECKDB output
    if ($CheckDB_Results.Length -ge 4) {
        # Format CheckDB_Results
        if ($CheckDB_Results[3].IndexOf(". If DBCC printed error messages") -gt 0) {
            $CheckDB_Msg = ($CheckDB_Results[2]+" "+$CheckDB_Results[3].Substring(0, $CheckDB_Results[3].IndexOf(". If DBCC printed error messages")))
        }
        else 
        {
            $CheckDB_Msg = ($CheckDB_Results[2]+" "+$CheckDB_Results[3])
        }
                        
        # Validade CheckDB_Results
        if ($CheckDB_Msg.IndexOf("CHECKDB found 0 allocation errors and 0 consistency errors in database") -lt 0) {
            $ErrorsFound = $TRUE
            for($a=0;$a -lt $CheckDB_Results.Count;$a++) {
                Add-Content -Path $logFilename -Value ($CheckDB_Results[$a].Replace("'",""))
            }
        } # if ($CheckDB_Msg.IndexOf("CHECKDB found 0 allocation errors and 0 consistency errors in database") -lt 0)
        else
        {
            Add-Content -Path $logFilename -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | "+$CheckDB_Msg.Replace("'",""))
        }

    } # if ($CheckDB_Results.Length -ge 4)
    else
    {
        Add-Content -Path $logFilename -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | CHECKDB did not return expected message related to database "+$dbname)
        foreach($line in $CheckDB_Results) {
            Add-Content -Path $logFilename -Value $line
        }
        $ErrorsFound = $TRUE
    }


}

<######################################################################################################
 - Initialization
######################################################################################################>

$log_line="=============================================================================================================================="
$Restore_cmd=@()

<######################################################################################################
 - Script body
######################################################################################################>
Import-Module -Name ("C:\Dataops\bin\DFTlibrary.dll")
$AccessKey = Get-awsaccessKey
$SecretKey = Get-awssecretkey
$sqllogin = Get-sqllogin
$sqlpwrd  = Get-sqlpwrd

$start = Get-Date


Add-Content -Path $logFilename -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | Start processing "+$dbname)
Add-Content -Path $logFilename -Value ($log_line)
Add-Content -Path $logFilename -Value ("")
Add-Content -Path $logFilename -Value ("servername = "+$server_name)
Add-Content -Path $logFilename -Value ("tagname = "+$tagname)
Add-Content -Path $logFilename -Value ("dbname = "+$dbname)
Add-Content -Path $logFilename -Value ("fromDevicePath = "+$fromDevicePath)
Add-Content -Path $logFilename -Value ("linked_server = "+$linked_server)
Add-Content -Path $logFilename -Value ("FSxFolder = "+$BackupPolicy_FSxFolder)
Add-Content -Path $logFilename -Value ("BackupPolicy_FSxFolder = "+$BackupPolicy_FSxFolder)

Add-Content -Path $logFilename -Value ("SearchBakcupsLastDays = "+$SearchBakcupsLastDays.ToString())


<######################################################################################################
 - Check database status
 recovery_model => SIMPLE=3 FULL=1
######################################################################################################>

$query = "select [database_id], [user_access_desc], [state_desc], [is_read_only], [recovery_model_desc], [recovery_model], [create_date] "
$query+= "from ["+$linked_server+"].[master].[sys].[databases] "
$query+= "where [name]='"+$dbname+"'"
$catalog=Invoke-Sqlcmd -Query $query -ServerInstance $ServerInstance -Username $sqllogin -Password $sqlpwrd -Database "DATAOPS"
Add-Content -Path $logFilename -Value ($log_line)
Add-Content -Path $logFilename -Value ("Catalog ["+$dbname+"] has database_id="+$catalog.database_id.ToString())
Add-Content -Path $logFilename -Value ("    user_access .......... "+$catalog.user_access_desc)
Add-Content -Path $logFilename -Value ("    state ................ "+$catalog.state_desc)
Add-Content -Path $logFilename -Value ("    is_read_only ......... "+$catalog.is_read_only.ToString())
Add-Content -Path $logFilename -Value ("    recovery_model ....... "+$catalog.recovery_model_desc)
Add-Content -Path $logFilename -Value ("    creata date .. ....... "+$catalog.create_date.ToString("yyyy-MM-dd HH:mm:ss:fffff"))
<######################################################################################################
 - Find FSx backup files
######################################################################################################>
Add-Content -Path $logFilename -Value ($log_line)
Add-Content -Path $logFilename -Value ("    Searching FSx "+$FSxFolder)




write-host("Recovery model = "+$catalog.recovery_model.ToString()) -ForegroundColor yellow
$BackupFound   = @(0,0,0)
$BackupFileSet = getBackupFilesSet -dbName $dbname -fromDevicePath $BackupPolicy_FSxFolder -recovery_model ($catalog.recovery_model)

if ($BackupFileSet.count -gt 0) {
 

    <######################################################################################################
        - Generate restore commands
    ######################################################################################################>

    Add-Content -Path $logFilename -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | "+$BackupFound[0].ToString()+$BackupFound[1].ToString()+$BackupFound[2].ToString())
    $RestoreType = ($BackupFound[0].ToString()+$BackupFound[1].ToString()+$BackupFound[2].ToString())
    $moveFiles = gen_movefiles -DBname $dbname -FilePath ($BackupPolicy_FSxFolder+"\"+$BackupFileSet[0])
    $Restore_cmd = GenerateRestoreSQL -RestoreType $RestoreType -backupFileSet $BackupFileSet -movefiles $moveFiles -catalog $dbname -fileLocation $BackupPolicy_FSxFolder

    <######################################################################################################
        - RESTORING catalog
    ######################################################################################################>
    Add-Content -Path $logFilename -Value ($log_line)
    Add-Content -Path $logFilename -Value ("Restore_cmd="+$Restore_cmd.count.ToString())
    Add-Content -Path $logFilename -Value ("")
    foreach($cmd in $Restore_cmd) {
        Add-Content -Path $logFilename -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | Executing "+$cmd)
        Invoke-Sqlcmd -Query $cmd -ServerInstance $ServerInstance -Username $sqllogin -Password $sqlpwrd -Database "master"
    }


    if ((restorationResult -catalog $dbname) -eq 0) {
        <######################################################################################################
            - CHECKING catalog
        ######################################################################################################>

        Add-Content -Path $logFilename -Value ($log_line)
        Add-Content -Path $logFilename -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | Starting database checks on "+$dbname)
        Add-Content -Path $logFilename -Value ($log_line)
        Try
        {
            $check_result = (CheckTableCount -catalog $dbname)
            Add-Content -Path $logFilename -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | Table count check = "+$check_result.ToString()+" tables found.")
            runCHECKDB -catalog $dbname
        }
        Catch
        {
            # Catch any error
            Add-Content -Path $logFilename -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | An error occurred")
            Add-Content -Path $logFilename -Value ($error[0].Exception.GetType().FullName)
            Add-Content -Path $logFilename -Value ($error[0].Exception.Message)
            Add-Content -Path $logFilename -Value ($error[0].ErrorDetails)
        }
        Finally
        {
            Add-Content -Path $logFilename -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | End of checks")
        }

    } else {
        Add-Content -Path $logFilename -Value (".........................................................................................................................")
        Add-Content -Path $logFilename -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | ********** ERROR:  Restore failed **********")
        Add-Content -Path $logFilename -Value (".........................................................................................................................")

    }

    <######################################################################################################
        - DROPPING catalog
    ######################################################################################################>
    Add-Content -Path $logFilename -Value ($log_line)
    Add-Content -Path $logFilename -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | Dropping database ["+$dbname+"]")
    $cmd="DROP DATABASE ["+$dbname+"]"
    Invoke-Sqlcmd -Query $cmd -ServerInstance $ServerInstance -Username $sqllogin -Password $sqlpwrd -Database "master"

} else {
    Add-Content -Path $logFilename -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | "+"FULL Backup not found for catalog "+$dbname)
}







<######################################################################################################
 - End of script body
######################################################################################################>
Add-Content -Path $logFilename -Value ($log_line)
Add-Content -Path $logFilename -Value ("")
Add-Content -Path $logFilename -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | Finished processing "+$dbname)
Add-Content -Path $logFilename -Value ("Duration: "+(NEW-TIMESPAN –Start $start –End (Get-Date)).ToString()+" (Hours:Min:Sec.ms)")

Add-Content -Path $logFilename -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | ======================= finish =======================")
Add-Content -Path $logFilename -Value ("")

saveToDatabase -server_name $server_name -tag_name $tagname -dbname $dbname -report_filepath $logFilename -check_result 0