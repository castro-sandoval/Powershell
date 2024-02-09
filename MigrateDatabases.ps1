<#******************************************************************************************************************************************
      This script will backup all databases expect system databases from a source server and restore them into a destination server
      This script DOES NOT DROP any database NOR DELETE any data but replace existing DBs with the same name.

                                                 Script constants configuration
******************************************************************************************************************************************#>
$LogFile        = "C:\temp\Backup.log"                                 # Location where the log file will be created
#=============================================== Source server ============================================================================
$sourceServerConn         = "server=.;database=master;Integrated Security=sspi;Connection Timeout=3600"  # Connection to the source instance
$BackupDestinationFolder  = "C:\Databases\Backup\"                                                       # Location where the backup files will be created on source server

#=============================================== Destination server ============================================================================
$DestServerConn        = "server=.;database=master;Integrated Security=sspi"  # Connection to the destination instance
$DestServerBakLocation = "C:\Databases\Backup\New\"                           # Location where the backup files will be restored from  ** assumes the backup files are there -> this script can move files across **

$DestServerDataFileFilder = "C:\Databases\New\"                               # Location where the data files will be restored to
$DestServerLogFileFilder  = "C:\Databases\New\Log"                            # Location where the log  files will be restored to


<#****************************************************************************************************************************************#>
function FormatDatetime {
    param( [String]$dt )
    return ($dt.SubString(6,2)+"/"+$dt.SubString(4,2)+"/"+$dt.SubString(0,4)+" "+$dt.SubString(8,2)+":"+$dt.SubString(10,2)+":"+$dt.SubString(12,2)+"   (dd/mm/yyyy hh:nn:ss)")
}


<#****************************************************************************************************************************************#>
cls
if (Test-Path $LogFile) {
    Remove-Item -Path $LogFile
}
Add-Content -Path $LogFile -Value ("Backup databases log file - Created: "+(FormatDatetime (Get-Date -Format yyyMMddHmmss) ))
$LogMessage = '-'*100
Add-Content -Path $LogFile -Value $LogMessage


$ScriptStartDate=(GET-DATE)
<#******************************************************************************************************************************************
                                                            BACKUP THE DATABASES
******************************************************************************************************************************************#>
$BackupStartDate=(GET-DATE)
$cn = new-object System.Data.SqlClient.SqlConnection $sourceServerConn

$cn.Open()
$sql = $cn.CreateCommand()


#------- retrive databases from source server--------------
$FileExtention = ("_"+(Get-Date -Format yyyMMddHmmss)+".BAK")
$sql.CommandText = "select name as dbname, "
$sql.CommandText = $sql.CommandText + ("'BACKUP DATABASE '+QUOTENAME(name)+' TO DISK = N''"+$BackupDestinationFolder+"'+name+'"+$FileExtention+"'' WITH NOFORMAT, NOINIT,  NAME = N'''+name+'-Full Database Backup'', COMPRESSION, SKIP, NOREWIND, NOUNLOAD;' as SQLCOMMAND ")
$sql.CommandText = $sql.CommandText + "from sys.databases where database_id>4"
$sql.CommandTimeout = 0

$rdr = $sql.ExecuteReader()
$FileCount = 0
$ErrorCount = 0
if ($rdr.HasRows) {
    
    $dbNames       = @()
    $BkupFilenames = @()
    $SQLCommands   = @()
    $Msgs          = @()

    foreach($dbname in $rdr) {
        $dbNames       = $dbNames       + $dbname.GetValue(0).ToString()
        $BkupFilenames = $BkupFilenames + ($dbname.GetValue(0).ToString() + $FileExtention)
        $SQLCommands  = $SQLCommands  + $dbname.GetValue(1).ToString()
    }
    
    $rdr.Close()

    #------ Backup databases ----------------
    foreach($dbname in $dbNames) 
    {
        Add-Content -Path $LogFile -Value ""
        $LogMessage = ("Backing up databse "+$dbname+" to "+$BackupDestinationFolder+$BkupFilenames[$FileCount]+" ...")
        Write-Host $LogMessage 
        Add-Content -Path $LogFile -Value $LogMessage
        $Msgs = $Msgs + ""

        $sql.CommandText = $SQLCommands[$FileCount]
        
        try 
        {
            $StartDate=(GET-DATE)
            $rdr = $sql.ExecuteNonQuery(); 
        } 
        Catch
        {
            $err = $_.Exception
            $Msgs[$FileCount] = ($Msgs[$FileCount] + " - Error: "+$err.Message)
            $ErrorCount = $ErrorCount + 1
        }
        $EndDate=(GET-DATE)
        $Duration = NEW-TIMESPAN –Start $StartDate –End $EndDate


        $LogMessage = ("Duration: "+$Duration.ToString())
        Write-Host $LogMessage
        Write-Host ""
        Add-Content -Path $LogFile -Value $LogMessage

        $FileCount = $FileCount + 1
    }

} else {
    Write-Host ("No database found on "+$cn.ConnectionString)
}
$cn.Close()



Add-Content -Path $LogFile -Value ""
$LogMessage = ("Total of "+$FileCount.ToString()+" databases found.")
Write-Host $LogMessage 
Add-Content -Path $LogFile -Value $LogMessage
$LogMessage = ("Total of "+$ErrorCount.ToString()+" erros.")
Write-Host $LogMessage 
Add-Content -Path $LogFile -Value $LogMessage



Add-Content -Path $LogFile -Value ""
Add-Content -Path $LogFile -Value ("Finish "+(FormatDatetime (Get-Date -Format yyyMMddHmmss)))
Add-Content -Path $LogFile -Value ('-'*100)


#------ Add commands and messages to log file ----------------
$FileCount = 0
foreach($LogMessage in $Msgs) {
    Add-Content -Path $LogFile -Value ($SQLCommands[$FileCount])
    
    if ($LogMessage -ne "") {
        Add-Content -Path $LogFile -Value $LogMessage
    } 
    
    Add-Content -Path $LogFile -Value ""

    $FileCount = $FileCount + 1
}

Add-Content -Path $LogFile -Value ('-'*100)
Add-Content -Path $LogFile -Value ""

$BackupEndDate=(GET-DATE)


<#******************************************************************************************************************************************
                                               MOVE/COPY FILES FROM Source server -> Destination server
This script needs modification to move files across servers (depends where you run the script) - As it is it moves files locally.

******************************************************************************************************************************************#>
$FileMoveStartDate=(GET-DATE)

#*** DOES NOT CHECK FILE EXISTANCE BEFORE COPING...
For ($FileCount=0; $FileCount -lt $BkupFilenames.Count; $FileCount++) {
    Move-Item -Path ($BackupDestinationFolder+$BkupFilenames[$FileCount]) -Destination ($DestServerBakLocation+$BkupFilenames[$FileCount])
    Write-Host ("move "+$BackupDestinationFolder+$BkupFilenames[$FileCount]+" to "+$DestServerBakLocation+$BkupFilenames[$FileCount])
}


$FileMoveEndDate=(GET-DATE)

<#******************************************************************************************************************************************
                                                            RESTORE THE DATABASES
******************************************************************************************************************************************#>
$RestoreStartDate=(GET-DATE)

#------ Collect information from backup files ----------------
$cn = new-object System.Data.SqlClient.SqlConnection $sourceServerConn
$cn.Open()
$sql = $cn.CreateCommand()
$sql.CommandTimeout = 0

$FileCount = 0
foreach($File in $BkupFilenames) {

    $RestoreCommand = "restore database ["+$dbNames[$FileCount]+"] FROM DISK='"+$DestServerBakLocation+$File+"' WITH FILE = 1, "
    Add-Content -Path $LogFile -Value  ("Database: "+$dbNames[$FileCount])
    Add-Content -Path $LogFile -Value  ("restore filelistonly FROM DISK='"+$DestServerBakLocation+$File+"'")
    $sql.CommandText = "restore filelistonly FROM DISK='"+$DestServerBakLocation+$File+"'"
    $rdr = $sql.ExecuteReader()
    if ($rdr.HasRows) {
        foreach($dbname in $rdr) {
            Add-Content -Path $LogFile -Value  ("File type: "+$dbname.GetValue(2).ToString()+" - Logical name: "+$dbname.GetValue(0).ToString()+" - Physical name:"+$Filename)
            Add-Content -Path $LogFile -Value ("Original path: "+$dbname.GetValue(1).ToString())
            $Filename = Split-Path ($dbname.GetValue(1).ToString()) -Leaf
            Add-Content -Path $LogFile -Value ""

            if ($dbname.GetValue(2).ToString() -eq "L") {
                $RestoreCommand = $RestoreCommand + "move '"+$dbname.GetValue(0).ToString()+"' to '"+$DestServerLogFileFilder+$File+"', "
            } else {
                $RestoreCommand = $RestoreCommand + "move '"+$dbname.GetValue(0).ToString()+"' to '"+$DestServerDataFileFilder+$File+"', "
            }
        }
        $RestoreCommand = $RestoreCommand + "NOUNLOAD, REPLACE"
        $SQLCommands[$FileCount] = $RestoreCommand
        Add-Content -Path $LogFile -Value $RestoreCommand
        Add-Content -Path $LogFile -Value ""
    }
    $rdr.Close()
    $FileCount = $FileCount + 1
}

#------ Executing the restore ----------------
Write-Host ""
Write-host ('-'*100)
Write-Host ""

$FileCount=0
$ErrorCount = 0

foreach($File in $BkupFilenames) {
    
    Write-Host ("Restoring "+$File+" ...")
    $Msgs[$FileCount] = ""

    $sql.CommandText = $SQLCommands[$FileCount]
    try 
    {
      $StartDate=(GET-DATE)
      $rdr = $sql.ExecuteNonQuery();
    } 
    Catch
    {
      $err = $_.Exception
      $Msgs[$FileCount] = ($Msgs[$FileCount] + " - Error: "+$err.Message)
      $ErrorCount = $ErrorCount + 1
    }
    $EndDate=(GET-DATE)
    $Duration = NEW-TIMESPAN –Start $StartDate –End $EndDate

    $LogMessage = ("Duration: "+$Duration.ToString())
    Write-Host $LogMessage
    Write-Host ""
    Add-Content -Path $LogFile -Value $LogMessage



    $FileCount = $FileCount + 1
}

#------ Add commands and messages to log file ----------------
$FileCount = 0
foreach($LogMessage in $Msgs) {
    Add-Content -Path $LogFile -Value ($SQLCommands[$FileCount])
    
    if ($LogMessage -ne "") {
        Add-Content -Path $LogFile -Value $LogMessage
    } 
    
    Add-Content -Path $LogFile -Value ""

    $FileCount = $FileCount + 1
}
Add-Content -Path $LogFile -Value ('-'*100)
Add-Content -Path $LogFile -Value ""




$RestoreEndDate=(GET-DATE)

<#******************************************************************************************************************************************
                                            Finish
******************************************************************************************************************************************#>
$Duration = NEW-TIMESPAN –Start $BackupStartDate –End $BackupEndDate
$LogMessage = ("Total backup duration: "+$Duration.ToString())
Write-Host $LogMessage
Add-Content -Path $LogFile -Value $LogMessage
#...........................................................................................................................................
$Duration = NEW-TIMESPAN –Start $FileMoveStartDate –End $FileMoveEndDate
$LogMessage = ("Total file move duration: "+$Duration.ToString())
Write-Host $LogMessage
Add-Content -Path $LogFile -Value $LogMessage
#...........................................................................................................................................
$Duration = NEW-TIMESPAN –Start $RestoreStartDate –End $RestoreEndDate
$LogMessage = ("Total restore duration: "+$Duration.ToString())
Write-Host $LogMessage
Add-Content -Path $LogFile -Value $LogMessage
#...........................................................................................................................................



$ScriptEndDate=(GET-DATE)
$Duration = NEW-TIMESPAN –Start $ScriptStartDate –End $ScriptEndDate

$LogMessage = ("Total script duration: "+$Duration.ToString())
Write-Host $LogMessage
Write-Host ""
Add-Content -Path $LogFile -Value ('-'*100)
Add-Content -Path $LogFile -Value ""
Add-Content -Path $LogFile -Value $LogMessage
Add-Content -Path $LogFile -Value ""
Add-Content -Path $LogFile -Value (('-'*45)+" THE END "+('-'*45))
