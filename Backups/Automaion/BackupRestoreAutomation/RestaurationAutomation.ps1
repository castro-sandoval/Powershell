<######################################################################################################
 - Parameters definition
######################################################################################################>

$logfolder = "C:\Dataops\DRAutomation\log\"
$logfolderdetails = $logfolder+"\details\"
$masterserver_linkedserver="10.232.123.122,50000"
$ServerInstance="I-078BC7BDB4E42"  # local server
$dbcount_per_server = 5
$MPP=6 # Max multithreading (processes)
$MaxCPU=50


<######################################################################################################
 - Function definitions
######################################################################################################>
function get_nextserver{
    param ([string] $last_serverid)
    $server_id=0

    $query ="SELECT top 1 [server_id] FROM ["+$masterserver_linkedserver+"].[DATAOPS].[Targets].[Instances]"
    $query+=" WHERE [location]='PROD' and is_quarantine=0 and [server_id]>"+$last_serverid
    $query+=" ORDER BY [server_id]"

    $ResultSet=Invoke-Sqlcmd -Query $query -ServerInstance "I-078BC7BDB4E42" -Username $sqllogin -Password $sqlpwrd -Database "master"
    if ($ResultSet) {
        $server_id = $ResultSet.server_id
    } else {
        $query ="SELECT top 1 [server_id] FROM ["+$masterserver_linkedserver+"].[DATAOPS].[Targets].[Instances]"
        $query =" WHERE [location]='PROD' and is_quarantine=0 "
        $query =" ORDER BY [server_id]"

        $ResultSet=Invoke-Sqlcmd -Query $query -ServerInstance "I-078BC7BDB4E42" -Username $sqllogin -Password $sqlpwrd -Database "master"
        $server_id = $ResultSet.server_id
    }
    return $server_id
}

<######################################################################################################
 - Initialization
######################################################################################################>
if (!(Test-Path -Path $logfolder)) {
    New-Item -Path $logfolder -ItemType Directory
}
if (!(Test-Path -Path $logfolderdetails)) {
    New-Item -Path $logfolderdetails -ItemType Directory
}

Get-ChildItem -Path ($logfolderdetails+"*.log") | Remove-Item -Force


Import-Module -Name ("C:\Dataops\bin\DFTlibrary.dll")
$AccessKey = Get-awsaccessKey
$SecretKey = Get-awssecretkey
$sqllogin = Get-sqllogin
$sqlpwrd  = Get-sqlpwrd
$server_id = get_nextserver -last_serverid "0"


<######################################################################################################
 - Script body
######################################################################################################>
$LogFile=$logfolder+"BackupRestore-automation_"+(GET-DATE).ToString("yyyyMMdd")+".log"
Add-Content -Path $LogFile -Value ("")
Add-Content -Path $LogFile -Value ("**********************************************************************************************************")
Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | Starting a new run....")
Add-Content -Path $LogFile -Value ("**********************************************************************************************************")

while ($server_id -ne "") {
    #======================= refresh daily log filename =============================
    $LogFile=$logfolder+"BackupRestore-automation_"+(GET-DATE).ToString("yyyyMMdd")+".log"

    #======================= get details of current server ===========================
    $query = "select B.FULL_backup_device_path, I.[Server_name], I.[tag_name], I.[tag_ip], I.[linked_server] "
    $query+= " from ["+$masterserver_linkedserver+"].[DATAOPS].[Targets].[Instances] I "
    $query+= " inner join ["+$masterserver_linkedserver+"].[DATAOPS].[Targets].[BackupPolicy] B on I.server_id=B.server_id "
    $query+= " where I.[server_id]="+$server_id

    $serverdata=Invoke-Sqlcmd -Query $query -ServerInstance $ServerInstance -Username $sqllogin -Password $sqlpwrd -Database "master" # -Verbose 4> $VerboseOutput
    Add-Content -Path $LogFile -Value ("")
    Add-Content -Path $LogFile -Value ("**********************************************************************************************************")
    Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | Checking server id: "+$server_id+"   "+$serverdata.tag_name+"   "+$serverdata.tag_ip+"   "+$serverdata.Server_name)
    Add-Content -Path $LogFile -Value ("**********************************************************************************************************")

    $query="exec CheckLinkedServer @linkedserver='"+$serverdata.linked_server+"', @rmtuser='"+$sqllogin+"', @rmtpwrd='"+$sqlpwrd+"'"
    $resultset=Invoke-Sqlcmd -Query $query -ServerInstance $ServerInstance -Username $sqllogin -Password $sqlpwrd -Database "DATAOPS"


    #================== randomly select databases from current server ========================
    Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | Randomly selecting "+$dbcount_per_server.ToString()+" databases from "+$serverdata.tag_name+"   ("+$serverdata.tag_ip+")   "+$serverdata.Server_name)

    $query ="select [name] from ["+$serverdata.linked_server+"].[master].[sys].[Databases] "
    $query+="where ([name] not in ('master','tempdb','msdb','model')) and ([name] not like 'MasterQueue%') and ([name] not like 'SessionAsset%') and [user_access]=0 and [state]=0"

    $databases=(Invoke-Sqlcmd -Query $query -ServerInstance $ServerInstance -Username $sqllogin -Password $sqlpwrd -Database "master" | Get-Random -Count $dbcount_per_server).name

    foreach($database in $databases) {
        #write-host ("Processing server_id="+$server_id.ToString()+" / "+$serverdata.tag_name+" catalog: "+$database)
        
        Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | Random database selected: ["+$database+"]")
        ################ Control multithreading throutle #################
        Do {
            
            $running=@(Get-Process | Where-Object({$_.name -like "powershell*"})).count-1
            $cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
            #Write-Host ("CPU=$cpuUsage    running=$running    MPP=$MPP") -ForegroundColor White
            Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | [Checking] CPU Usage = "+$cpuUsage.ToString()+"     running = "+$running.ToString())

            #Write-Host ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+"  $BackupType   $day_yyyymmdd       CPU=$cpuUsage    running=$running    MPP=$MPP") -ForegroundColor Yellow
            if ($cpuUsage -gt $MaxCPU) {
                #Write-Host ("                 Waiting on CPU=$cpuUsage to be bellow $MaxCPU") -ForegroundColor gray
                Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | Waiting on CPU=$cpuUsage to be bellow $MaxCPU")
            }
            if ($running -ge $MPP) {
                #Write-Host ("                 Waiting on PS processes running=$running to reduce under MPP=$MPP") -ForegroundColor gray
                Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | Waiting on PS processes running=$running to reduce under MPP=$MPP")
            }

            if (($running -gt ($MPP-1)) -or ($cpuUsage -ge $MaxCPU)) {
                Start-Sleep -Seconds 30
            } else {
                Start-Sleep -Seconds 2
            }


        } while (($cpuUsage -gt $MaxCPU) -or ($running -ge $MPP))


        #Write-Host ("CPU=$cpuUsage    running=$running    MPP=$MPP") -ForegroundColor Green
        Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | [Start process] CPU=$cpuUsage    running=$running    MPP=$MPP")
        ###### ready to request new process


        $PS_File          = "C:\Dataops\DRAutomation\RestoreCheckDB.ps1"
        $p_server_name    = $serverdata.Server_name
        $p_tagname        = $serverdata.tag_name
        $p_dbname         = $database
        $p_fromDevicePath = $serverdata.FULL_backup_device_path

        $p_logFilename      = $logfolderdetails+$p_tagname+"_"+$p_dbname+"_"+(GET-DATE).ToString("yyyyMMdd")+".log"

        $ps_cmd = $PS_File
        $ps_cmd+= " -server_name '"+$p_server_name+"'"
        $ps_cmd+= " -tagname '"+$p_tagname+"'"
        $ps_cmd+= " -dbname '"+$p_dbname+"'"
        $ps_cmd+= " -fromDevicePath '"+$p_fromDevicePath+"'"
        $ps_cmd+= " -logFilename '"+$p_logFilename+"'"
        $ps_cmd+= " -linked_server '"+$serverdata.linked_server+"'"
     
        Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | Starting a new process to restore catalog ["+$database+"] - "+$serverdata.tag_name)
        Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | "+$ps_cmd)
        Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | Detailed logs at "+$p_logFilename)

        Start-Process powershell.exe -ArgumentList $ps_cmd -WindowStyle Hidden

        Start-Sleep -Seconds (2)

    }



    #=== get next server ==============
    $server_id = get_nextserver -last_serverid $server_id
    if ($server_id -eq ""){
        Add-Content -Path $LogFile -Value ("")
        Add-Content -Path $LogFile -Value ("*******************************************************************************************************************")
        Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | INVALID get_nextserver")
        Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | get_nextserver -last_serverid "+$server_id)
        Add-Content -Path $LogFile -Value ("*******************************************************************************************************************")
        Add-Content -Path $LogFile -Value ("")
        break;
    }

}
