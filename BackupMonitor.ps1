Param ([Parameter(Mandatory)]$InstanceName)

#Set-AWSCredential -AccessKey AKIAIK6ODY2F7MFNUVBQ -SecretKey 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
Set-AWSCredential -AccessKey AKIAQ7FRZQP3ZO7BLDLL -SecretKey 2aNk6wr0jMZOnzOCDWO698HNZPe9kJKThBMj9FJe

$SQLUsername    = "*****" 
$SQLPassword    = "********"
$query = "select replace(physical_name, '\mydevicefile.bak', '\') as BackupFolder from sys.backup_devices where name='LocalBackup'"
$BackupDevice= (Invoke-Sqlcmd -ServerInstance $instanceName -Username $SQLUsername -Password $SQLPassword -Database "master" -Query $query).BackupFolder

if ((!($BackupDevice)) -or (!($InstanceName)))
{
    Add-Content -Path B:\Backups\BackupMonitor.txt -Value ("BackupDevice:"+$BackupDevice+" / InstanceName="+$InstanceName)
    exit

}


#*********************************************************
function LastMondayyyyyMMdd {
    if ((Get-date).DayOfWeek.value__ -gt 0)
    {
        $ThisWeekMonday = (Get-date).AddDays(1- (Get-date).DayOfWeek.value__)
    } else {
        $ThisWeekMonday = (Get-date).AddDays(-6)
    }
    return $ThisWeekMonday.ToString("yyyyMMdd")   
}

#*********************************************************

$LogFile        = $BackupDevice+"BackupMonitor_"+(Get-Date).ToString("yyyyMMdd")+".log"
$S3NotFound     = $BackupDevice+"BackupMonitorS3NF_"+(Get-Date).ToString("yyyyMMdd")+".log"
$LocalNotFound  = $BackupDevice+"BackupMonitorLocalNF_"+(Get-Date).ToString("yyyyMMdd")+".log"
$BucketName     ="lcp2-sql-backups-us-east-1"
$keyPrefix      = "/"+$InstanceName.Replace("\","/")+"/Backups/Week_"+(LastMondayyyyyMMdd)

Add-Content -Path $LogFile -Value ("Starting backup monitor at "+(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))
Add-Content -Path $LogFile -Value ("BackupDevice= "+$BackupDevice)
Add-Content -Path $LogFile -Value ("InstanceName= "+$InstanceName)
Add-Content -Path $LogFile -Value ("-------------------------------------------------------------------------------------------------------------------")
$Last24H = (Get-Date).AddDays(-1)
Add-Content -Path $LogFile -Value ("Searching for local full or diff backups after "+($Last24H).ToString("yyyy-MM-dd HH:mm:ss"))


Add-Content -Path $LocalNotFound -Value ("Starting backup monitor at "+(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))
Add-Content -Path $LocalNotFound -Value ("BackupDevice :"+$BackupDevice)

Add-Content -Path $S3NotFound -Value ("Starting backup monitor at "+(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))
Add-Content -Path $S3NotFound -Value ("BucketName :"+$BucketName + "      KeyPrefix:"+ $keyPrefix)


$query = "SELECT [name] FROM SYS.DATABASES WHERE [STATE]=0 AND [user_access]=0 AND database_id<>2"
$AllDatabases= (Invoke-Sqlcmd -ServerInstance $instanceName -Username $SQLUsername -Password $SQLPassword -Database "master" -Query $query)
Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" :  " +$AllDatabases.Count.ToString()+" databases found in "+$instanceName)
$FoundIssue = $false
foreach ($dbname in $AllDatabases.name)
{
    
    #=============== search local file in the Backup device folder ==================
    $LocalBAKfiles = (Get-ChildItem -Path ($BackupDevice+"*"+$dbname+".bak") -Include DIFF*.bak, FULL*.bak -Exclude LOG_*.bak | Where-Object {($_.CreationTime -gt $Last24H)} |Sort-Object CreationTime -Descending)
    $LocalFound = $LocalBAKfiles.Count -gt 0
    if ($LocalFound)
    {
        Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" : Found " +$LocalBAKfiles[0].FullName+" for ["+$dbname+"]")
    }
    else
    {
        Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" : BAK not found for ["+$dbname+"]")
        Add-Content -Path $LocalNotFound -Value $dbname
        $FoundIssue = $true
    }


    
   #=============== search S3 for Backup ==================
    $S3File = (Get-S3Object -BucketName $BucketName -KeyPrefix $keyPrefix | Where-Object {(($_.key -like "*/FULL*"+$dbname+".bak") -or ($_.key -like "*/DIFF*"+$dbname+".bak")) -and ($_.LastModified -gt $Last24H)})    
    #Check if file is already there before copying
    if ($S3File) 
    {
        Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" : S3 found "+$S3File.Key)
            
    } 
    else 
    {
        Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" : S3 not found for ["+$dbname+"]")
        Add-Content -Path $S3NotFound -Value $dbname
        $FoundIssue = $true
    }
    


} # foreach AllDatabases


Add-Content -Path $LogFile -Value ("-------------------------------------------------------------------------------------------------------------------")
Add-Content -Path $LogFile -Value ("Finish backup monitor at "+(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))
Add-Content -Path $LogFile -Value ("-------------------------------------------------------------------------------------------------------------------")


Add-Content -Path $LocalNotFound -Value ("Finish backup monitor at "+(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))
Add-Content -Path $S3NotFound -Value ("Finish backup monitor at "+(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))


<#=============================================================================================================================================================
                    Sending emails notification
=============================================================================================================================================================#>

$maillist=@()
$maillist +="sandoval.castroneto@llamasoft.com"
$maillist +="ranjay.kumar@llamasoft.com"

$subject = "Backup monitor - "+$InstanceName
$Message='<p>Backup monitor - check databases backups in the last 24 hour.'

if ($FoundIssue)
{
    Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" : Sending alert")
    $Alert | Export-Csv -Path $csvFile

    $Message+='<p>Some databases do not have backups in the last 24 hours for instance '+$InstanceName
    $Message+='<p>Check attached file with the list of databases to check, and the log file with details'
    $Message+='<p>LocalNotFound = List of databases where local backup in the last 24h was not found.'
    $Message+='<p>S3NotFound = List of databases where S3 backup file in the last 24h was not found.'
    Send-MailMessage -From "SQLtarget@llamasoft.com" -To $maillist -Subject $subject -Body $Message -Attachments @($S3NotFound, $LocalNotFound, $LogFile) -SmtpServer "sasmt.llamasoft.com" -Port 25 -BodyAsHtml

}
else
{
    Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" : ZERO alerts.")
    $Message+='<p>All backups OK for instance '+$InstanceName
    Send-MailMessage -From "SQLtarget@llamasoft.com" -To $maillist -Subject $subject -Body $Message -Attachments @($LogFile) -SmtpServer "sasmt.llamasoft.com" -Port 25 -BodyAsHtml
}
