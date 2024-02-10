cls
<#_________________________________________________________________________________________________________________________________________________________
|          Global parameters
___________________________________________________________________________________________________________________________________________________________#>

$BaseFolder     = "C:\Users\sandoval.castroneto\Desktop\"
$GrowthLimit_MB = 256 # Max file growth in MB
$ServerInstance = "SCASTRO-T460S\MSSQLSERVER2014" # Instance to check

#___________________________________________________________________________________________________________________________________________________________
$InstanceName = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database master -Query "select @@servername"
$logFile      = ($BaseFolder+$InstanceName[0].Replace("\","_")+".log")
$HistoryFile  = ($BaseFolder+$InstanceName[0].Replace("\","_"))


if (Test-Path -Path $logFile) {
    Remove-Item -Path $logFile -Force
}

<#_________________________________________________________________________________________________________________________________________________________
|          Retrieve information from History file if it exists
___________________________________________________________________________________________________________________________________________________________#>
$DBHistory = New-Object System.Collections.ArrayList
if (Test-Path -Path ($HistoryFile+".zip")) {
    Expand-Archive ($HistoryFile+".zip") -DestinationPath $BaseFolder
    Remove-Item -Path ($HistoryFile+".zip") -Force
    $OldDBHistory = New-Object System.Collections.ArrayList
    $OldDBHistory = Import-Csv -Path ($HistoryFile+".csv")
    if (Test-Path -Path ($HistoryFile+".zip")) {
        Remove-Item -Path ($HistoryFile+".zip") -Force
    }
    if (Test-Path -Path ($HistoryFile+".csv")) {
        Remove-Item -Path ($HistoryFile+".csv") -Force
    }

    <#_________________________________________________________________________________________________________________________________________________________
    |          Delete old information from History
    ___________________________________________________________________________________________________________________________________________________________#>
    $dateLimit = ((Get-Date).AddMinutes(-10)).ToString("yyyy-MM-dd HH:mm:ss")

    foreach ($Item in $OldDBHistory) {
        if ($Item.Datetime -ge $dateLimit) {
            #write-Host ($Item.Datetime+" > "+$dateLimit+" - "+$Item.DatabaseName)
            $DBHistory.Add($Item)  | Out-Null
        }
    }
}
else{
    Write-Host ($HistoryFile+".zip not found.")
}

#___________________________________________________________________________________________________________________________________________________________
Add-Content -Path $logFile -Value "-- ************************************************************************"
Add-Content -Path $logFile -Value ("-- "+(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))
Add-Content -Path $logFile -Value "-- ********** Suggested filegrowth adjustments and maintenance ************"
Add-Content -Path $logFile -Value "-- ************************************************************************"
$DrivesToCheck   = @()
$SytemDBs        = @("master","tempdb","model","msdb")
$TransLogDetails = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database master -Query "DBCC SQLPERF(LOGSPACE)"
foreach($TransLogDetail in $TransLogDetails) {
    <#_________________________________________________________________________________________________________________________________________________________
    |          DO NOT check system databases
    ___________________________________________________________________________________________________________________________________________________________#>
    if ($TransLogDetail.'Database Name' -notin $SytemDBs) {

        <#_________________________________________________________________________________________________________________________________________________________
        |          Check data and log files growth unit and value
        ___________________________________________________________________________________________________________________________________________________________#>
        $sqlCmd = "select case status & cast(0x100000 as int) when cast(0x100000  as int) then 'P' else 'S' end as GrwType, case status & cast(0x40 as int) when cast(0x40  as int) then 'L' else 'D' end as FType, case status & cast(0x100000 as int) when cast(0x100000  as int) then growth else growth*8/1024 end as growth, name, filename, (size*8)/1024 as SizeMB from ["+$TransLogDetail.'Database Name'+"].sys.sysfiles"
        $DBfiles = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database master -Query $sqlCmd
        foreach ($dbFile in $DBfiles) {
            if (!($DrivesToCheck -match ($dbFile.'filename').Substring(0,2))) {
                $DrivesToCheck+=($dbFile.'filename').Substring(0,2)
            }
        

            <#_________________________________________________________________________________________________________________________________________________________
            |          Store each file information
            ___________________________________________________________________________________________________________________________________________________________#>
        
            $NewItem = New-Object System.Object
            $NewItem | Add-Member -MemberType NoteProperty -Name "Datetime" -Value (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            $NewItem | Add-Member -MemberType NoteProperty -Name "DatabaseName" -Value $TransLogDetail.'Database Name'
            $NewItem | Add-Member -MemberType NoteProperty -Name "LogicalFilename" -Value $dbFile.name
            $NewItem | Add-Member -MemberType NoteProperty -Name "FileType" -Value $dbFile.FType
            $NewItem | Add-Member -MemberType NoteProperty -Name "SizeMB" -Value ([math]::Truncate($TransLogDetail.'Log Size (MB)'))
            $DBHistory.Add($NewItem)  | Out-Null

            <#_________________________________________________________________________________________________________________________________________________________
            |          Actions for each file type
            ___________________________________________________________________________________________________________________________________________________________#>
            if ($dbFile.FType -eq "L") { 
            ## Check LOG files

                if ($TransLogDetail.'Log Size (MB)' -gt 100) {


                    $CalculatedGrowthFactor =  ([math]::Truncate($TransLogDetail.'Log Size (MB)' / 100)) * 16    # for each 100MB growth 16MB
                    if ($CalculatedGrowthFactor -gt $GrowthLimit_MB) {
                        $CalculatedGrowthFactor =  $GrowthLimit_MB
                    }

                    if ( (($dbFile.growth*8)/1024) -ne $CalculatedGrowthFactor) {
                        $sqlCmd = "ALTER DATABASE ["+$TransLogDetail.'Database Name'+"]  MODIFY FILE  ( NAME = "+$dbFile.name+", FILEGROWTH = "+$CalculatedGrowthFactor.ToString()+"MB );"
                        Add-Content -Path $logFile -Value $sqlCmd
                    }

                    <#_____________________________________________________________________________________________________________________________________
                    |        SHRINK TRANS LOG files to appropriate sizes if at least 40% of pages are free 
                    _______________________________________________________________________________________________________________________________________#>
                    if ($TransLogDetail.'Log Space Used (%)' -lt 60)  {
                        
                        # -> check last file size
                        $Items = ($DBHistory | Where-Object {($_.DatabaseName -eq $TransLogDetail.'Database Name') -and  ($_.FileType -eq 'L')})
                        $dateLimit = (Get-date).AddMonths(-1)
                        foreach($item in  $Items) {
                            if ($item.Datetime -gt $dateLimit) {
                                $LastItem = $item
                                $dateLimit = $item.Datetime
                            }
                        }

                        # -> if file size didn't grow than SHRINK again to LogFileSize - 10%
                        if ([math]::Truncate($TransLogDetail.'Log Size (MB)') -le $LastItem.SizeMB) {
                            $sqlCmd = "USE "+$TransLogDetail.'Database Name'+"; DBCC SHRINKFILE ('"+$LastItem.LogicalFilename+"', "+(([math]::Truncate($TransLogDetail.'Log Size (MB)'))*0.9).ToString()+");"
                            Add-Content -Path $logFile -Value ("-- Checking log file "+$dbFile.'filename'+" from database "+$LastItem.DatabaseName)
                            Add-Content -Path $logFile -Value ("-- Previous "+$LastItem.LogicalFilename+" size: "+$TransLogDetail.'Log Size (MB)'.ToString()+" MB on "+$LastItem.Datetime)
                            Add-Content -Path $logFile -Value $sqlCmd        
                        } #if ($TransLogDetail.'Log Size (MB)' -le $LastItem.SizeMB) {

                    } # if (($TransLogDetail.'Log Space Used (%)' -lt 50) -and ($TransLogDetail.'Log Size (MB)' -gt 50)) {
                    #_____________________________________________________________________________________________________________________________________

            
                } else {
                    # Log files smaller than  100MB will grow by 
                    if (($dbFile.GrwType -ne "P") -or ( ($dbFile.GrwType -ne "P") -and ($dbFile.growth -ne 10)) ) {
                        $sqlCmd = "ALTER DATABASE ["+$TransLogDetail.'Database Name'+"]  MODIFY FILE  ( NAME = "+$dbFile.name+", FILEGROWTH = 10%);"
                        Add-Content -Path $logFile -Value $sqlCmd
                    }            
                } # if ($TransLogDetail.'Log Size (MB)' -gt 100)


            } else {    
            ## Check DATA files
                if ($dbFile.SizeMB -gt 100) {
                    $CalculatedGrowthFactor =  ([math]::Truncate($dbFile.SizeMB / 100)) * 32    # for each 100MB growth 32MB
                    if ($CalculatedGrowthFactor -gt $GrowthLimit_MB) {
                        $CalculatedGrowthFactor =  $GrowthLimit_MB
                    }

                    if (($dbFile.GrwType -ne 'S') -or ( ($dbFile.GrwType -eq 'S') -and ((($dbFile.growth*8)/1024) -ne $CalculatedGrowthFactor) )) {
                        $sqlCmd = "ALTER DATABASE ["+$TransLogDetail.'Database Name'+"]  MODIFY FILE  ( NAME = "+$dbFile.name+", FILEGROWTH = "+$CalculatedGrowthFactor.ToString()+"MB );"
                        Add-Content -Path $logFile -Value $sqlCmd
                    }


                } # if ($dbFile.SizeMB -gt 100)


            } # if ($dbFile.FType -eq "L")
        } # foreach ($dbFile in $DBfiles) 
    } # if ($TransLogDetail.'Database Name' -notin $SytemDBs) {
} # foreach($TransLogDetail in $TransLogDetails)

<#_____________________________________________________________________________________________________________________________________
|                                         Update information to History file
_______________________________________________________________________________________________________________________________________#>
if (Test-Path -Path ($HistoryFile+".csv")) {
    Remove-Item -Path ($HistoryFile+".csv") -Force
}
$DBHistory | Export-Csv -Path ($HistoryFile+".csv")
Compress-Archive -Path ($HistoryFile+".csv") -DestinationPath ($HistoryFile+".zip") -CompressionLevel Optimal
if (Test-Path -Path ($HistoryFile+".csv")) {
    Remove-Item -Path ($HistoryFile+".csv") -Force
}

<#_____________________________________________________________________________________________________________________________________
|                                         Check drive free space
_______________________________________________________________________________________________________________________________________#>
$SendDiskSpaceAlert = $FALSE
$msg = "<P> Disk space alert"
$DrivesAnalyses = get-WmiObject win32_logicaldisk | Select DeviceID, Size, FreeSpace | Where-Object {$_.DeviceID -in $DrivesToCheck}
foreach ($drive in $DrivesAnalyses) {
    $PercentFree = [math]::Truncate($drive.FreeSpace*100/$drive.Size)
    if ($PercentFree -le 10) {
        $msg += "<p>Drive "+$drive.'DeviceID'+" has only "+$PercentFree.ToString()+" % ("+$drive.FreeSpace.ToString+" bytes) free space out of "+([math]::Truncate(($drive.Size/(1024*1024*1024)))).ToString()
        $SendDiskSpaceAlert = $TRUE
    }
}
if ($SendDiskSpaceAlert -eq $TRUE) {
    "Send email alert..."
}

