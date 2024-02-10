
Import-Module -Name ("C:\Dataops\bin\DFTlibrary.dll")
$AccessKey = Get-awsaccessKey
$SecretKey = Get-awssecretkey
$sqllogin = Get-sqllogin
$sqlpwrd  = Get-sqlpwrd
#================================================================================================================================

$LogFile = "C:\Dataops\bin\log\UploadBackupsFSxToS3_"+(Get-Date).ToString("yyyyMMddHHmmss")+".log"
Add-Content -Path $LogFile -Value ("Starting at "+(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))

#================================================================================================================================


$Server_devices_sql = "SELECT [tag_name], FULL_backup_device_path+'Backups\'+server_name as Folder, S3_Bucket, Server_name FROM [Targets].BackupPolicy WHERE [Location]='PROD' AND [Policy_active]=1 "
$Server_devices = (Invoke-Sqlcmd -ServerInstance "." -Username $sqllogin -Password $sqlpwrd -Database "DATAOPS" -Query $Server_devices_sql)

Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" - "+$Server_devices.Count.ToString()+" servers found")
Add-Content -Path $LogFile -Value ("-----------------------------------------------------------------------------------------------------------------------------------")

$BackupTypes = @('LOG','DIFF','FULL')
foreach($server in $Server_devices)
{


    $Start = Get-Date
    $BucketName = $server.S3_Bucket
    $Folder     = $server.Folder
    $Prefix     = "/"+ $server.Server_name +"/"

    Add-Content -Path $LogFile -Value ($Start.ToString()+"      Server: "+$server.tag_name)
    Add-Content -Path $LogFile -Value ($BucketName +" - Prefix: "+ $Prefix +" - Folder: "+ $Folder)
    

    Write-S3Object -BucketName $BucketName -KeyPrefix $Prefix -Folder $Folder -AccessKey $AccessKey -SecretKey $SecretKey

    Add-Content -Path $LogFile -Value (Get-Date)
    Add-Content -Path $LogFile -Value ((New-TimeSpan -Start $Start -End (Get-Date)).ToString())
    Add-Content -Path $LogFile -Value ("=================================================================================================================")
}



