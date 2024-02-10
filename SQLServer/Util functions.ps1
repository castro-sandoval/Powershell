<#*****************************************************************************************************
    This script will backup a catalog 
    and RESTORE it with ROW file to other DRIVE

*****************************************************************************************************#>
$LocalSQLinstance = "IP-0AE87C31\PLATFORM"
$InputFile        = "B:\Restores\InputMoveROWfiles.txt"


#==========================================================
#$ROWdeviceName = "data2" # G:\data
$ROWdeviceName = "data1" # D:\data\PLATFORM\MSSQL13.PLATFORM\MSSQL\DATA
$LOGdeviceName = "log1"  # E:\log
$BAKdeviceName = "LocalBackup"  # B:\...

<#*****************************************************************************************************
                        GLOBAL CONSTANT DEFINITION
*****************************************************************************************************#>

$SQLUsername      = "*********"
$SQLPassword      = "********"

<#*****************************************************************************************************
                        FUNCTION DEFINITION
*****************************************************************************************************#>
function SetMultiUserMode
{ param([string]$dbname,$parentId)
    $query = "ALTER DATABASE ["+$dbname+"] SET MULTI_USER"
    Invoke-Sqlcmd -Query $query -ServerInstance $LocalSQLinstance -Username $SQLUsername -Password $SQLPassword -Database "msdb" -ConnectionTimeout 0 -QueryTimeout 65535
    $query = "select [user_access] from sys.databases where [name]='"+$dbname+"'"
    $dataset = Invoke-Sqlcmd -Query $query -ServerInstance $LocalSQLinstance -Username $SQLUsername -Password $SQLPassword -Database "msdb" -ConnectionTimeout 0 -QueryTimeout 65535
    InsertStatusReport -dbname $dbname -status "SET MULTI_USER" -parentId $parentId
    return ($dataset.user_access -eq 0)
}

function SetSingleUserMode
{ param([string]$dbname,$parentId)
    $query = "ALTER DATABASE ["+$dbname+"] SET SINGLE_USER"
    Invoke-Sqlcmd -Query $query -ServerInstance $LocalSQLinstance -Username $SQLUsername -Password $SQLPassword -Database "msdb" -ConnectionTimeout 0 -QueryTimeout 65535
    $query = "select [user_access] from sys.databases where [name]='"+$dbname+"'"
    $dataset = Invoke-Sqlcmd -Query $query -ServerInstance $LocalSQLinstance -Username $SQLUsername -Password $SQLPassword -Database "msdb" -ConnectionTimeout 0 -QueryTimeout 65535
    InsertStatusReport -dbname $dbname -status "SET SINGLE_USER" -parentId $parentId
    return ($dataset.user_access -eq 1)
}

function GetParentId
{ param([string]$dbname)
    $query = "INSERT INTO [DataOps].[MoveROWcatalogs]([catalog]) VALUES ('"+$dbname+"')"
    Invoke-Sqlcmd -Query $query -ServerInstance $LocalSQLinstance -Username $SQLUsername -Password $SQLPassword -Database "msdb" -ConnectionTimeout 0 -QueryTimeout 65535
    $query = "select [DataOps].[MoveROWcatalogs_GetId] ('"+$dbname+"') as [ParentId]"
    $dataset = Invoke-Sqlcmd -Query $query -ServerInstance $LocalSQLinstance -Username $SQLUsername -Password $SQLPassword -Database "msdb" -ConnectionTimeout 0 -QueryTimeout 65535
    return $dataset.ParentId	
}

function CaptureFileSize
{ param([string]$dbname,$parentId)
    $query = "EXEC [DataOps].[CaptureFileSize] @dbname='"+$dbname+"', @parentId="+$parentId
    Invoke-Sqlcmd -Query $query -ServerInstance $LocalSQLinstance -Username $SQLUsername -Password $SQLPassword -Database "msdb" -ConnectionTimeout 0 -QueryTimeout 65535
    InsertStatusReport -dbname $dbname -status "CaptureFileSize" -parentId $parentId
}

function Is_InUse
{
   param([string]$dbname,$parentId)
    $query = "EXEC  [DataOps].[CatalogSessions] @dbname='"+$dbname+"'"
    $dataset = Invoke-Sqlcmd -Query $query -ServerInstance $LocalSQLinstance -Username $SQLUsername -Password $SQLPassword -Database "msdb" -ConnectionTimeout 0 -QueryTimeout 65535
    if ($dataset)
    {
        foreach($row in $dataset)
        {
            $status="DB in use: "+$row.Connection
            Write-Host ($status) -ForegroundColor Yellow
            Add-Content -Path $LogFile -Value $status
            InsertStatusReport -dbname $dbname -status $status -parentId $parentId
        }
        return $true
    }
    else
    {
        return $false
    }
   
}

function InsertStatusReport
{ param([string]$dbname,$status,$parentId)
    $query = "INSERT INTO [DataOps].[MoveROWfilesStatus] ([catalog], [status],[parent_id]) VALUES ('"+$dbname+"','"+$status+"',"+$parentId+")"
    Invoke-Sqlcmd -Query $query -ServerInstance $LocalSQLinstance -Username $SQLUsername -Password $SQLPassword -Database "msdb" -ConnectionTimeout 0 -QueryTimeout 65535
}

function GetDBstate
{
    param([string]$dbname,
          [string]$parentId  )
  InsertStatusReport -dbname $dbname -status "GetDBstate" -parentId $parentId
  $query = "select [state] from sys.databases where name='"+$dbname+"'"
  $dataset = Invoke-Sqlcmd -Query $query -ServerInstance $LocalSQLinstance -Username $SQLUsername -Password $SQLPassword -Database "master" -ConnectionTimeout 0 -QueryTimeout 65535
  return $dataset.state
}

function GetDeviceFolder
{
  param([string]$devicename)
  $query = "select replace(physical_name, '\mydevicefile.bak', '\') as Folder from sys.backup_devices where name='"+$devicename+"'"
  $dataset = Invoke-Sqlcmd -Query $query -ServerInstance $LocalSQLinstance -Username $SQLUsername -Password $SQLPassword -Database "master" -ConnectionTimeout 0 -QueryTimeout 65535
  return $dataset.Folder
}

function CreateBackupCmd
{ param([string]$dbname,$device,$parentId)

    $fnRet = New-Object System.Collections.ArrayList
    $BAK_filename="FULL_"+(GET-DATE).ToString("yyyyMMddHHmmss")+"_"+$dbname+".BAK"
    $BackupFolder = GetDeviceFolder -devicename $device
    $query = "BACKUP DATABASE ["+$dbname+"] TO  DISK = N'"+$BackupFolder+$BAK_filename+"' WITH INIT,  NAME = N'"+$dbname+"', DESCRIPTION='FULL compressed backup - Move to D', COMPRESSION, STATS = 25"
    Add-Content -Path $LogFile -Value $query

    $fnRet.Add($BackupFolder+$BAK_filename) | Out-Null
    $fnRet.Add($query) | Out-Null
    Add-Content -Path $LogFile -Value ("BAK_file = "+$BackupFolder+$BAK_filename)
    Add-Content -Path $LogFile -Value ("Bkup_cmd = "+$query)
    return $fnRet
    
}

function CheckBackupValid 
{
    param( [string]$BAKfile)
        if (!($BAKfile))
        {
            Add-Content -Path $LogFile -Value ("BAK_path may not be valid.")
            return $false
        }

        #=================== Test is backup is valid ================
        
        $query   ="restore verifyonly FROM DISK='"+$BAKfile+"'" 
        Add-Content -Path $LogFile -Value $query
        $VerboseOutput= $LogsFolder+"verifyonly"+(Get-Date).ToString("yyyyMMddHHmmss")+".out"
        if (Test-Path -Path $VerboseOutput)
        {
            Remove-Item -Path $VerboseOutput -Force
        }

        Invoke-Sqlcmd -ServerInstance $LocalSQLinstance -Username $SQLUsername -Password $SQLPassword -Database "master" -Query $query -ConnectionTimeout 0 -QueryTimeout 65535  -Verbose 4> $VerboseOutput
        $CheckDB_Results = Get-Content -Path $VerboseOutput
        $result=$false
        foreach($line in $CheckDB_results) 
        {
            if ($line -match "is valid.") 
            {
                $result = $line    
                break
            }
        }
        if ($result -eq "") 
        {
            Add-Content -Path $LogFile -Value ($BAKfile+" may not be valid.")
        } 
        else 
        {
            Add-Content -Path $LogFile -Value ($BAKfile+" verifyonly: "+$result)
        }

        Remove-Item -Path $VerboseOutput -Force
        return ($result -match "is valid.")
}

function CreateMovefiles_TSQL 
{
    param( [string]$BAK_path,
           [string]$ROWdeviceName,
           [string]$LOGdeviceName
    )
    $moveFile_TSQL=""
    $query       ="EXEC [DataOps].[Restore_MoveFilesToDevices] @BAK_filepath='"+$BAK_path+"', @ROWdeviceName='"+$ROWdeviceName+"', @LOGdeviceName='"+$LOGdeviceName+"'"
    $resultset   = Invoke-Sqlcmd -ServerInstance $LocalSQLinstance -Username $SQLUsername -Password $SQLPassword -Database "msdb" -Query $query -ConnectionTimeout 0 -QueryTimeout 65535
    for ($i=0;$i -lt $resultset.Count; $i++) 
    {
        $moveFile_TSQL+=$resultset[$i].MoveStatement+" "
    }
    return $moveFile_TSQL
}

function GenerateRestoreSQL {
    param( [string]$physicalFile,
           [string]$database_name,
           [string]$parentId
           )
    InsertStatusReport -dbname $database_name -status "GenerateRestoreSQL" -parentId $parentId
    $RestoreSQL       = New-Object System.Collections.ArrayList
    $NewFileLocations = New-Object System.Collections.ArrayList

    # only 1 FULL restore file -> $BackupTpe="F"
    <# FULL #> 
    $NewFileLocations = CreateMovefiles_TSQL -BAK_path ($physicalFile) -ROWdeviceName $ROWdeviceName -LOGdeviceName $LOGdeviceName
    $RestoreSQL.Add("RESTORE DATABASE ["+$database_name+"] FROM DISK = '"+$physicalFile+"' WITH  FILE = 1, "+$NewFileLocations+" NOUNLOAD, REPLACE") > $null

    return $RestoreSQL
}

function CheckDB_DB {
    param( [string]$dbname,$parentId )
    
    InsertStatusReport -dbname $dbname -status "CheckDB_DB" -parentId $parentId
    $checkdbCmd = "DBCC CHECKDB (["+$dbname+"], NOINDEX) WITH PHYSICAL_ONLY"
    $VerboseOutput = $LogsFolder+(Get-Date).ToString("yyyyMMddhhmmss")+"_"+$dbname+".out"

    $result=  $false
    Add-Content -Path $LogFile -Value $checkdbCmd
    Invoke-Sqlcmd -Query $checkdbCmd -ServerInstance $LocalSQLinstance -Username $SQLUsername -Password $SQLPassword -Database "master" -ConnectionTimeout 0 -QueryTimeout 65535 -Verbose 4> $VerboseOutput
    $CheckDB_Results = Get-Content -Path $VerboseOutput
    
    if (Test-Path -Path $VerboseOutput) 
    {
        Remove-Item -Path $VerboseOutput -Force
    }

    foreach($line in $CheckDB_results) 
    {
        Add-Content -Path $LogFile -Value $line
        if (!($result))
        {
            $result= ($line.IndexOf("CHECKDB found 0 allocation errors and 0 consistency errors in database") -ge 0)
        }
    }
    return $result

}

<#*****************************************************************************************************
                        SCRIPT BODY
*****************************************************************************************************#>
Clear-Host
$Succeeded = New-Object System.Collections.ArrayList
$Failed    = New-Object System.Collections.ArrayList

$ROWfolder = GetDeviceFolder -devicename $ROWdeviceName
$LOGfolder = GetDeviceFolder -devicename $LOGdeviceName
$BAKfolder = GetDeviceFolder -devicename $BAKdeviceName
$LogFile     = $BAKfolder+"MoveROWfiles_"+(Get-date).ToString("yyyyMMddHHmmss")+".log"

Add-Content -Path $LogFile -Value ("MoveROWfiles starting at "+(Get-date).ToString("yyyy-MM-dd HH:mm:ss"))


Add-Content -Path $LogFile -Value ("ROWdeviceName="+$ROWdeviceName+" ROWfolder="+$ROWfolder)
Add-Content -Path $LogFile -Value ("LOGdeviceName="+$LOGdeviceName+" LOGfolder="+$LOGfolder)
Add-Content -Path $LogFile -Value ("BAKdeviceName="+$BAKdeviceName+" BAKfolder="+$BAKfolder)


$catalogsFromFile = (Get-Content -Path $InputFile)

if (!($catalogsFromFile))
{
    Write-Host ("Error reading "+$InputFile) -ForegroundColor Red
    exit
}
else
{
    Write-Host ($catalogsFromFile.Count.ToString()+" catalog from "+$InputFile) -ForegroundColor Cyan
    Add-Content -Path $LogFile -Value ($catalogsFromFile.Count.ToString()+" catalog from "+$InputFile)
}
$CountDown = $catalogsFromFile.Count
foreach($catalogName in $catalogsFromFile)
{
    $ParentId = GetParentId -dbname $catalogName
    if ($ParentId)
    {
        Write-Host ($CountDown.ToString()+" : ParentId="+$ParentId.ToString()+" for catalog "+$catalogName) -ForegroundColor Green
    }
    else
    {
        Write-Host ("Invalid ParentId") -ForegroundColor Red
        break
    }

    Add-Content -Path $LogFile -Value ("---------------------------------------------------------------------------------------------------")
    Add-Content -Path $LogFile -Value ("catalogName="+$catalogName+"      ParentId="+$ParentId.ToString())

    InsertStatusReport -dbname $catalogName -status "Start" -parentId $ParentId
    $dbstate = (GetDBstate -dbname $catalogName -parentId $ParentId)
    if ($dbstate -ne 0)
    {
        $failed.Add($catalogName+" (Error: not ONLINE")
        write-host ("Catalog "+$catalogName+" is not ONLINE") -ForegroundColor Yellow
        InsertStatusReport -dbname $catalogName -status "Error: not ONLINE" -parentId $ParentId
    } # if ($dbstate -ne 0)
    else 
    {
        if (Is_InUse -dbname $catalogName -parentId $ParentId)
        {
            Add-Content -Path $LogFile -Value ("function Is_InUse says catalog is in use.")
            write-host ("function Is_InUse says "+$catalogName+" is in use.") -ForegroundColor Yellow
            InsertStatusReport -dbname $catalogName -status "Error: Is_InUse" -parentId $ParentId
            $failed.Add($catalogName+" (Error: Is_InUse")


        } # if (Is_InUse -dbname $catalogName)
        else
        {
            if (SetSingleUserMode -dbname $catalogName -parentId $ParentId)
            {

                CaptureFileSize -dbname $catalogName -parentId $ParentId
                
                $BAK_file = (CreateBackupCmd -dbname $catalogName -device $BAKdeviceName -parentId $ParentId)
                <# CreateBackupCmd returns
                    $BAK_file[0] = full backup file path
                    $BAK_file[1] = BACKUP DATABASE command
                #>
                
                if (($BAK_file) -and ($BAK_file[1] -ne ""))
                {
                    Add-Content -Path $LogFile -Value ("Creating "+$BAK_file[0]) # this is the full file path generated by the backup command -> Ex: B:\Backups\PLATFORM\FULL_20200611193041_7a54dd6d-6f32-4b99-8dd8-d949734da0be.bak
                    $query=$BAK_file[1] # this is the BACKUP command
                    Add-Content -Path $LogFile -Value ((GET-DATE).ToString("yyyy-MM-dd HH:mm:ss")+" - Executing"+ $query)
                    InsertStatusReport -dbname $catalogName -status "BACKUP start" -parentId $ParentId
                    $dataset = Invoke-Sqlcmd -Query $query -ServerInstance $LocalSQLinstance -Username $SQLUsername -Password $SQLPassword -Database "master" -ConnectionTimeout 0 -QueryTimeout 65535
                    Add-Content -Path $LogFile -Value ((GET-DATE).ToString("yyyy-MM-dd HH:mm:ss")+" - Backup completed.")
                    InsertStatusReport -dbname $catalogName -status "BACKUP end" -parentId $ParentId
                    # backup done

                    if (CheckBackupValid -BAKfile $BAK_file[0])
                    {
                        InsertStatusReport -dbname $catalogName -status "DROP DATABASE" -parentId $ParentId
                        # drop database
                        $query = "DROP DATABASE ["+$catalogName+"]"
                        Add-Content -Path $LogFile -Value $query
                        Invoke-Sqlcmd -Query $query -ServerInstance $LocalSQLinstance -Username $SQLUsername -Password $SQLPassword -Database "master" -ConnectionTimeout 0 -QueryTimeout 65535

                
                        $query = GenerateRestoreSQL -physicalFile $BAK_file[0] -database_name $catalogName -parentId $ParentId
                        Add-Content -Path $LogFile -Value $query
                        InsertStatusReport -dbname $catalogName -status "RESTORE start" -parentId $ParentId
                        Invoke-Sqlcmd -Query $query -ServerInstance $LocalSQLinstance -Username $SQLUsername -Password $SQLPassword -Database "master" -ConnectionTimeout 0 -QueryTimeout 65535
                        InsertStatusReport -dbname $catalogName -status "RESTORE end" -parentId $ParentId
                        # database restored in new drive

                        if (CheckDB_DB -dbname $catalogName -parentId $ParentId)
                        {
                            Add-Content -Path $LogFile -Value ($catalogName+" restored successfuly")
                            $Succeeded.Add($catalogName)
                            InsertStatusReport -dbname $catalogName -status "CheckDB_DB finished OK" -parentId $ParentId
                            CaptureFileSize -dbname $catalogName -parentId $ParentId
                        } # if (CheckDB_DB -dbname $catalogName)
                        else
                        {
                            $failed.Add($catalogName+" (Error: CheckDB_DB")
                            Add-Content -Path $LogFile -Value ("function CheckDB_DB said restore is not good.")
                            InsertStatusReport -dbname $catalogName -status "Error: CheckDB_DB" -parentId $ParentId
                        } # else if (CheckDB_DB -dbname $catalogName)

                    } # if (CheckBackupValid -BAK_path $BAK_file[0])
                    else
                    {
                        $failed.Add($catalogName+" (Error: CheckBackupValid")
                        Add-Content -Path $LogFile -Value ("function CheckBackupValid said backup is not good.")
                        InsertStatusReport -dbname $catalogName -status "Error: CheckBackupValid" -parentId $ParentId

                    } # else if (CheckBackupValid -BAK_path $BAK_file[0])
                } # if ($BAK_file[1])
                else
                {
                    Add-Content -Path $LogFile -Value ("function CreateBackup failed.")
                    $failed.Add($catalogName+" (Error: CreateBackup")
                    InsertStatusReport -dbname $catalogName -status "Error: CreateBackup" -parentId $ParentId
                } # else if ($BAK_file[1])


            } # if (SetSingleUserMode -dbname $catalogName -parentId $ParentId)
            else
            {
                Add-Content -Path $LogFile -Value ("function SetSingleUserMode failed.")
                $failed.Add($catalogName+" (Error: SetSingleUserMode")
                InsertStatusReport -dbname $catalogName -status "Error: SetSingleUserMode" -parentId $ParentId

            } # else (SetSingleUserMode -dbname $catalogName -parentId $ParentId)


            if (SetMultiUserMode -dbname $catalogName -parentId $ParentId)
            {
                Add-Content -Path $LogFile -Value ("SetMultiUserMode OK")
            }
            else
            {
                Add-Content -Path $LogFile -Value ("SetMultiUserMode failed.")
                $failed.Add($catalogName+" (Error: SetMultiUserMode")
            }
        } # else if (Is_InUse -dbname $catalogName)


    } # else if ($dbstate -ne 0)
    InsertStatusReport -dbname $catalogName -status "End" -parentId $ParentId
    $CountDown--
} # foreach($catalogName in $catalogsFromFile)


Add-Content -Path $LogFile -Value ("============================================================================================")
Add-Content -Path $LogFile -Value ("                                    Report")
Add-Content -Path $LogFile -Value ("============================================================================================")
Add-Content -Path $LogFile -Value ("Total catalogs from input file ............... "+$catalogsFromFile.Count.ToString())
Add-Content -Path $LogFile -Value ("Total Succeeded .............................. "+$Succeeded.Count.ToString())
Add-Content -Path $LogFile -Value ("Total Failed ................................. "+$Failed.Count.ToString())
Add-Content -Path $LogFile -Value ("============================================================================================")
Add-Content -Path $LogFile -Value ("MoveROWfiles finished at "+(Get-date).ToString("yyyy-MM-dd HH:mm:ss"))
Add-Content -Path $LogFile -Value ("")