Param ([Parameter(Mandatory)]$JSONinputFile)

$localSQLInstance = "IP-0AE87C31\PLATFORM"
<#===================================================================================================================================== 
                    PARAMETER DEFINITIONS
=====================================================================================================================================#>
$DownloadFolder     = "B:\Restores\Download\"
$LogsFolder         = "B:\Restores\Logs\"
$BulkResponseFolder = "B:\Restores\BulkResponse\"

<#===================================================================================================================================== 
                    INITIALIZATIONS
=====================================================================================================================================#>
$inputFileName        = ([io.fileinfo]$JSONinputFile).basename
$JSONresponsefilePath = $BulkResponseFolder+(Get-Date).ToString("yyyyMMddhhmmss")+"response_"+$inputFileName+".JSON"
$LogFileName          = (Get-Date).ToString("yyyyMMddhhmmss")+"_"+$inputFileName+".log"
$LogFile              = $LogsFolder+$LogFileName


if (!(Test-Path -Path $JSONinputFile)) {
    Add-Content -Path $LogFile -Value ("File not found: "+$JSONinputFile)
    exit
} else {
    Add-Content -Path $LogFile -Value ("Found: "+$JSONinputFile)
}

$bucketName  = "lcp2-sql-backups-us-east-1"
$S3region    = "us-east-1"
$SQLUsername = '******'
$SQLPassword = '****'

<#===================================================================================================================================== 
                    FOLDER STRUCTURE CHECK
=====================================================================================================================================#>
$folders = @($DownloadFolder, $LogsFolder , $BulkResponseFolder)
foreach($Folder in $Folders) {
    if (!(Test-Path($Folder))) {
        New-Item -Path $Folder -ItemType Directory
    }
}


<#===================================================================================================================================== 
                    READ JSON
=====================================================================================================================================#>
Add-Content -Path $LogFile -Value ("Reading file "+$JSONinputFile)
$JSONfile = Get-Content -Raw -Path $JSONinputFile
$JSON_content = ($JSONfile | ConvertFrom-Json)
$DBlist = $JSON_content.catalogs

$AttachFiles = @($JSONinputFile, $LogFile)

<#===================================================================================================================================== 
                    SECURITY/CREDENTIALS
=====================================================================================================================================#>
Set-AWSCredentials -AccessKey ****** -SecretKey ******

<#===================================================================================================================================== 
                    FUNCTION DEFINITIONS
=====================================================================================================================================#>
function LastMondayyyyyMMdd {
    if ((Get-date).DayOfWeek.value__ -gt 0)
    {
        $ThisWeekMonday = (Get-date).AddDays(1- (Get-date).DayOfWeek.value__)
    } else {
        $ThisWeekMonday = (Get-date).AddDays(-6)
    }
    return $ThisWeekMonday.ToString("yyyyMMdd")   
}

function GetFULLbackupkey {
    param(  [string]$p_bucketName,
            [string]$p_Prefix,
            [string]$p_S3region,
            [string]$p_dbname )
    
    #======== Find FULL backup file ============
    $FULL_File = ""
    $files = Get-S3Object -BucketName $p_bucketName -Keyprefix $p_Prefix -Region $p_S3region | Where-Object {($_.key -like "*"+$p_dbname+".bak") -and ($_.key -like "*/FULL_*")} 
    if ($files)
    {
        $FULL_File = $files[0]
        foreach ($file in $files)
        {
            if ($file.LastModified -gt $FULL_File.LastModified)
            {
                $FULL_File = $file
            }
        }
    }
    return $FULL_File
}

function GetDIFFbackupkey {
    param(  [string]$p_bucketName,
            [string]$p_Prefix,
            [string]$p_S3region,
            [string]$p_dbname,
            [Amazon.S3.Model.S3Object]$p_FULL_File)

    #======== Find DIFF backup file ============
    $p_DIFF_File = $p_FULL_File
    $files = Get-S3Object -BucketName $p_bucketName -Keyprefix $p_Prefix -Region $p_S3region | Where-Object {($_.key -like "*"+$p_dbname+".bak") -and ($_.key -like "*DIFF_*.bak")} 
    if ($files)
    {
        foreach ($file in $files)
        {
            if ($file.LastModified -gt $p_DIFF_File.LastModified)
            {
                $p_DIFF_File = $file
            }
        }
        if ($p_DIFF_File -eq $p_FULL_File)
        {
            $p_DIFF_File = "" # not found
        } 
    } else {
        $p_DIFF_File = "" # not found
    }

    return $p_DIFF_File
}

function GetLOGbackupkey {
    param(  [string]$p_bucketName,
            [string]$p_LogsPrefix,
            [string]$p_S3region,
            [string]$p_dbname,
            [Amazon.S3.Model.S3Object]$p_FULL_File,
            [Amazon.S3.Model.S3Object]$p_DIFF_File)

    #======== Find LOG backup file ============
    if ($p_DIFF_File) {
        $p_LOG_File = $p_DIFF_File
    } else {
        $p_LOG_File = $p_FULL_File
    }
    $p_Reference = $p_LOG_File
    $files = Get-S3Object -BucketName $p_bucketName -Keyprefix $p_LogsPrefix -Region $p_S3region | Where-Object {($_.key -like "*"+$p_dbname+".bak") -and ($_.key -like "*LOG_*.bak")} 
    if ($files)
    {
        foreach ($file in $files)
        {
            if ($file.LastModified -gt $p_LOG_File.LastModified)
            {
                $p_LOG_File = $file
            }
        }
        if ($p_LOG_File -eq $p_Reference)
        {
            $p_LOG_File=""
        }
    } else
    {
        $p_LOG_File=""
    }
    return $p_LOG_File
}

function CheckBackupValid {
    param( [string] $BAK_path,
           [string] $SQLUsername,
           [string] $SQLPassword
    )
        #=================== Test is backup is valid ================
        $query   ="restore verifyonly FROM DISK='"+$BAK_path+"'" 
        Add-Content -Path $LogFile -Value $query
        $VerboseOutput=$BAK_path.Replace(".bak",(Get-Date).ToString("yyyyMMddhhmmss")+".out")
        Invoke-Sqlcmd -ServerInstance $localSQLInstance -Username $SQLUsername -Password $SQLPassword -Database "msdb" -Query $query -ConnectionTimeout 65534 -Verbose 4> $VerboseOutput
        if (Test-Path  -Path $VerboseOutput) {
            $CheckDB_Results = Get-Content -Path $VerboseOutput
            $result=""
            foreach($line in $CheckDB_results) {
                if ($line -match "is valid.") {
                    $result = $line    
                }
            }
            if ($result -eq "") {
                Add-Content -Path $LogFile -Value ($BAK_path+" may not be valid.")
            } else {
                Add-Content -Path $LogFile -Value ($BAK_path+" verifyonly: "+$result)
            }

            Remove-Item -Path $VerboseOutput -Force
            return ($CheckDB_Results -match "is valid.")
        } else 
        {
            Add-Content -Path $LogFile -Value ("Not able to run restore verifyonly FROM DISK="+$BAK_path)
            return ($false)
        }
}

function CreateMovefiles_TSQL {
    param( [string]$BAK_path)
    $moveFile_TSQL=""
    $query       ="exec [DataOps].[Restore_MoveFilesTo] @BAK_filepath='"+$BAK_path+"'"
    $resultset   = Invoke-Sqlcmd -ServerInstance $SQLInstanceName -Username $SQLUsername -Password $SQLPassword -Database "msdb" -Query $query
    for ($i=0;$i -lt $resultset.Count; $i++) {
            $moveFile_TSQL+=$resultset[$i].MoveStatement+" "
        }
    return $moveFile_TSQL
}

function GenerateRestoreSQL {
    param( [System.Collections.ArrayList]$DBfiles,
           [string]$database_name,
           [string]$BackupTpe)

    $RestoreSQL = New-Object System.Collections.ArrayList
    $moveFiles = ""
    $NewFileLocations = New-Object System.Collections.ArrayList
    switch ($DBfiles.Count)
    {
    1 {
        # only 1 FULL restore file -> $BackupTpe="F"
        <# FULL #> 
        $NewFileLocations = CreateMovefiles_TSQL -BAK_path ($DBfiles[0])
        $RestoreSQL.Add("RESTORE DATABASE ["+$database_name+"] FROM DISK = '"+$DBfiles[0]+"' WITH  FILE = 1, "+$NewFileLocations+" NOUNLOAD, REPLACE") > $null

      }
    2 {
        <# FULL #> 
        $NewFileLocations = CreateMovefiles_TSQL -BAK_path ($DBfiles[0])
        $RestoreSQL.Add("RESTORE DATABASE ["+$database_name+"] FROM DISK = '"+$DBfiles[0]+"' WITH  FILE = 1, "+$NewFileLocations+" NORECOVERY, NOUNLOAD, REPLACE") > $null

        # can be FULL+DIFF  -> $BackupTpe="FD" or FULL+LOG   -> $BackupTpe="FL"
        $NewFileLocations = CreateMovefiles_TSQL -BAK_path ($DBfiles[1])
        if ($BackupTpe -eq "FD") 
        {
            <# DIFF #> $RestoreSQL.Add("RESTORE DATABASE ["+$database_name+"] FROM DISK = '"+$DBfiles[1]+"' WITH  FILE = 1, "+$NewFileLocations+" RECOVERY, NOUNLOAD, REPLACE") > $null
        }
        else 
        {
            <# LOG #> $RestoreSQL.Add("RESTORE LOG ["+$database_name+"] FROM DISK = '"+$DBfiles[1]+"' WITH  FILE = 1, "+$NewFileLocations+" RECOVERY, NOUNLOAD, REPLACE") > $null
        }
      }

    3 {
        # FULL+DIFF+LOG -> $BackupTpe="FDL"
        
        <# FULL #>
        $NewFileLocations = CreateMovefiles_TSQL -BAK_path ($DBfiles[0])
        $RestoreSQL.Add("RESTORE DATABASE ["+$database_name+"] FROM DISK = '"+$DBfiles[0]+"' WITH  FILE = 1, "+$NewFileLocations+" NORECOVERY, NOUNLOAD, REPLACE") > $null
        
        <# DIFF #> 
        $NewFileLocations = CreateMovefiles_TSQL -BAK_path ($DBfiles[1])
        $RestoreSQL.Add("RESTORE DATABASE ["+$database_name+"] FROM DISK = '"+$DBfiles[1]+"' WITH  FILE = 1, "+$NewFileLocations+" NORECOVERY, NOUNLOAD, REPLACE") > $null
        
        <# LOG  #> 
        $NewFileLocations = CreateMovefiles_TSQL -BAK_path ($DBfiles[2])
        $RestoreSQL.Add("RESTORE LOG ["+$database_name+"] FROM DISK = '"+$DBfiles[2]+"' WITH  FILE = 1, "+$NewFileLocations+" RECOVERY, NOUNLOAD, REPLACE") > $null
      }
    } # close SWITCH

    return $RestoreSQL
}

function CheckDB_DB {
    param( [string]$dbname )

    $checkdbCmd = "DBCC CHECKDB (["+$dbname+"], NOINDEX) WITH PHYSICAL_ONLY"
    $VerboseOutput = $LogsFolder+(Get-Date).ToString("yyyyMMddhhmmss")+"_"+$inputFileName+".out"
    $result=$dbname+" successfully restored."
    Add-Content -Path $LogFile -Value $checkdbCmd
    Invoke-Sqlcmd -Query $checkdbCmd -ServerInstance $localSQLInstance -Username $SQLUsername -Password $SQLPassword -Database "master" -ConnectionTimeout 0 -Verbose 4> $VerboseOutput
    $CheckDB_Results = Get-Content -Path $VerboseOutput
    if (Test-Path -Path $VerboseOutput) {
        Remove-Item -Path $VerboseOutput -Force
    }

    foreach($line in $CheckDB_results) {
        Add-Content -Path $LogFile -Value $line
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
        $result=$CheckDB_Msg
        # Validade CheckDB_Results
        if ($CheckDB_Msg.IndexOf("CHECKDB found 0 allocation errors and 0 consistency errors in database") -lt 0) {
            $result="CHECKDB found errors after restore"

        } 
        else
        {
            $result=  ($CheckDB_Results[2]+" "+$CheckDB_Results[3].Substring(0, $CheckDB_Results[3].IndexOf(". If DBCC printed error messages")))
        }

    } # if ($CheckDB_Results.Length -ge 4)
    else
    {
        $result=  "CHECKDB did not return expected message related to database "+$dbname+" on "+$ServerInstance

    }

    return $result
}

<#===================================================================================================================================== 
                    SCRIPT BODY
=====================================================================================================================================#>
$JSONresponse=@()
$catalogs=@()
$Restoration_TSQL =  New-Object System.Collections.ArrayList
$Restoration_TSQL.Add("")
$BackupFiles=@()
for($i=0;$i -lt $DBlist.Count;$I++) {
    $Prefix = "/"+$DBlist[$i].from_instance.Replace("\","/")+"/Backups/Week_"+(LastMondayyyyyMMdd)+"/"
    $LogsPrefix = $Prefix.Replace("/Backups/Week_", "/TransacLogs/Week_")
    $response_message=""
    $Restoration_TSQL = $null

    Add-Content -Path $LogFile -Value ""
    Add-Content -Path $LogFile -Value ("Catalog: "+$DBlist[$i].catalog)
    <###################################################################################################################################
    #        Find and Download lastest backup files from S3 for each catalog in the JSON file
    ###################################################################################################################################>
    $FULLbackupObj = GetFULLbackupkey -p_bucketName $bucketName -p_Prefix $Prefix -p_S3region $S3region -p_dbname $DBlist[$i].catalog
    if ($FULLbackupObj) {
        #--- download FULL
        $File= ($FULLbackupObj.key).SubString(($FULLbackupObj.key).IndexOf("/FULL_")+1,  ($FULLbackupObj.key).Length-($FULLbackupObj.key).IndexOf("/FULL_")-1)
        
        if (Test-Path -Path ($DownloadFolder+$File)) {
            Add-Content -Path $LogFile -Value ("Using previous download "+($DownloadFolder+$File))
        } else {
            Add-Content -Path $LogFile -Value ("Downloading "+$File+" from "+$FULLbackupObj.Key)
            Read-S3Object -BucketName $bucketName -Key $FULLbackupObj.Key -File ($DownloadFolder+$File)
        }

        #if (CheckBackupValid -BAK_path ($DownloadFolder+$File) -SQLUsername $SQLUsername -SQLPassword $SQLPassword) {
        if ($true) {
            Add-Content -Path $LogFile -Value (($DownloadFolder+$File)+" is valid.")
            $BackupFiles=@($DownloadFolder+$File)
            $BackupTpe="F"
            $DIFFbackupObj = GetDIFFbackupkey -p_bucketName $bucketName -p_Prefix $Prefix -p_S3region $S3region -p_dbname $DBlist[$i].catalog -p_FULL_File $FULLbackupObj
            if ($DIFFbackupObj) {            
                #--- download DIFF
                $File= ($DIFFbackupObj.key).SubString(($DIFFbackupObj.key).IndexOf("/DIFF_")+1,  ($DIFFbackupObj.key).Length-($DIFFbackupObj.key).IndexOf("/DIFF_")-1)
                $BackupFiles+=($DownloadFolder+$File)
                $BackupTpe="FD"
                if (Test-Path -Path ($DownloadFolder+$File)) {
                    Add-Content -Path $LogFile -Value ("Using previous download "+($DownloadFolder+$File))
                } else {
                    Add-Content -Path $LogFile -Value ("Downloading "+$File+" from "+$DIFFbackupObj.Key)
                    Read-S3Object -BucketName $bucketName -Key $DIFFbackupObj.Key -File ($DownloadFolder+$File)
                }
    
                $LOGbackupObj = GetLOGbackupkey -p_DIFF_File $DIFFbackupObj -p_FULL_File $FULLbackupObj -p_bucketName $bucketName -p_LogsPrefix $LogsPrefix -p_S3region $S3region -p_dbname $DBlist[$i].catalog
                if ($LOGbackupObj) {
                    #--- download LOG
                    $File= ($LOGbackupObj.key).SubString(($LOGbackupObj.key).IndexOf("/LOG_")+1,  ($LOGbackupObj.key).Length-($LOGbackupObj.key).IndexOf("/LOG_")-1)
                    $BackupFiles+=($DownloadFolder+$File)
                    $BackupTpe="FDL"
                    if (Test-Path -Path ($DownloadFolder+$File)) {
                        Add-Content -Path $LogFile -Value ("Using previous download "+($DownloadFolder+$File))
                    } else {
                        Add-Content -Path $LogFile -Value ("Downloading "+$File+" from "+$LOGbackupObj.Key)
                        Read-S3Object -BucketName $bucketName -Key $LOGbackupObj.Key -File ($DownloadFolder+$File)
                    }
                }
                else {
                    Add-Content -Path $LogFile -Value ("LOG not found for catalog ["+$DBlist[$i].catalog+"] on "+$LogsPrefix)
                }
            }
            else {
                Add-Content -Path $LogFile -Value ("DIFF not found for catalog ["+$DBlist[$i].catalog+"] on "+$Prefix)
                $LOGbackupObj = GetLOGbackupkey -p_bucketName $bucketName -p_LogsPrefix $LogsPrefix -p_S3region $S3region -p_dbname $DBlist[$i].catalog -p_FULL_File $FULLbackupObj
                if ($LOGbackupObj) {
                    #--- download LOG
                    $File= ($LOGbackupObj.key).SubString(($LOGbackupObj.key).IndexOf("/LOG_")+1,  ($LOGbackupObj.key).Length-($LOGbackupObj.key).IndexOf("/LOG_")-1)
                    $BackupFiles+=($DownloadFolder+$File)
                    $BackupTpe="FL"
                    if (Test-Path -Path ($DownloadFolder+$File)) {
                        Add-Content -Path $LogFile -Value ("Using previous download "+($DownloadFolder+$File))
                    } else {
                        Add-Content -Path $LogFile -Value ("Downloading "+$File+" from "+$LOGbackupObj.Key)
                        Read-S3Object -BucketName $bucketName -Key $LOGbackupObj.Key -File ($DownloadFolder+$File)
                    }
                }
                else {
                    Add-Content -Path $LogFile -Value ("LOG not found for catalog ["+$DBlist[$i].catalog+"] on "+$LogsPrefix)
                }
            }

        } else {
            $response_message=(($DownloadFolder+$File)+" is invalid.")
            Add-Content -Path $LogFile -Value $response_message

        }
    }
    else {
        $response_message=("FULL backup not found for catalog ["+$DBlist[$i].catalog+"] on "+$Prefix)
        Add-Content -Path $LogFile -Value $response_message
    }



    <###################################################################################################################################
    #        Restore the catalog
    ###################################################################################################################################>
    $Restoration_TSQL = GenerateRestoreSQL -DBfiles $BackupFiles -database_name $DBlist[$i].catalog -BackupTpe $BackupTpe
    
    foreach($cmd in $Restoration_TSQL) {
        Invoke-Sqlcmd -ServerInstance $SQLInstanceName -Username $SQLUsername -Password $SQLPassword -Database "master" -Query $cmd -ConnectionTimeout 0
        Add-Content -Path $LogFile -Value $cmd
    }
    # After restore
    $response_message=CheckDB_DB -dbname $DBlist[$i].catalog


    $JSONitem = @{ catalog= $DBlist[$i].catalog
                   from_instance = $DBlist[$i].from_instance
                   replace    = "yes"
                   request_message = ""
                   response_message = $response_message
                 }
    $catalogs+=$JSONitem

} # for loop


$JSONresponse=@{maillist=@($JSON_content.maillist); catalogs=@($catalogs)}
$JSONresponse | ConvertTo-Json | Out-File -FilePath $JSONresponsefilePath
$AttachFiles=@()
$AttachFiles+=$JSONresponsefilePath
$AttachFiles+=$JSONinputFile
$AttachFiles+=$LogFile

$ofs = ','
$Message = "Bulk restore database from file "+$JSONinputFile

$maillist=@()
foreach($mail in $JSON_content.maillist) {
    $maillist += $mail.email
}
if ($maillist.IndexOf("sandoval.castroneto@llamasoft.com") -lt 0) {
    $maillist +="sandoval.castroneto@llamasoft.com"
}
if ($maillist.IndexOf("ranjay.kumar@llamasoft.com") -lt 0) {
    $maillist +="ranjay.kumar@llamasoft.com"
}


Send-MailMessage -From "TargetSQL@llamasoft.com" -To $maillist -Subject "Bulk restore request" -Body $Message -Attachments $AttachFiles -SmtpServer "sasmt.llamasoft.com" -Port 587 -BodyAsHtml

# END