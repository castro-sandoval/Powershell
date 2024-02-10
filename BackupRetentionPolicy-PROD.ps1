Import-Module -Name ("C:\Dataops\bin\DFTlibrary.dll")
$AccessKey = Get-awsaccessKey
$SecretKey = Get-awssecretkey
$sqllogin = Get-sqllogin
$sqlpwrd  = Get-sqlpwrd

#==================================================================================================================================================

$LogFile = "C:\Dataops\bin\log\RetentionPolicyPROD_"+(Get-Date).ToString("yyyyMMddHHmmss")+".log"
Add-Content -Path $LogFile -Value ("Starting at "+(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))
Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" - "+$Server_devices.Count.ToString()+" servers found")
Add-Content -Path $LogFile -Value ("-----------------------------------------------------------------------------------------------------------------------------------")

#==================================================================================================================================================



$BackupTypes = @('LOG','DIFF','FULL')

for($BT=0;$BT -le 2;$BT++)
{
    $Server_devices_sql = "SELECT [server_name], [tag_name], RetentionDays_Device"
    if ($BT -eq 0)
    {
        $Server_devices_sql += ", TRN_backup_device_path+'Backups\'+server_name as device_path"
    }
    else
    {
        $Server_devices_sql += ", "+$BackupTypes[$BT]+"_backup_device_path+'Backups\'+server_name as device_path"
    }
    $Server_devices_sql+= "  FROM [Targets].BackupPolicy WHERE [Location]='PROD' AND [Policy_active]=1"
    $Server_devices_sql+= "  ORDER BY 1,2"

    $Server_devices = (Invoke-Sqlcmd -ServerInstance "." -Username $sqllogin -Password $sqlpwrd -Database "DATAOPS" -Query $Server_devices_sql)

    foreach($server in $Server_devices)
    {
        
        $map_path= $server.device_path
        Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" - Adding map "+$map_path)
        $NewDrive=((68..90 | %{$L=[char]$_; if ((gdr).Name -notContains $L) {$L}})[0])
        $Drive = New-PSDrive -Name $NewDrive -PSProvider FileSystem -Root $map_path -Persist

        $cutoff = (GET-DATE).AddDays(-$server.RetentionDays_Device-15)
        $Filterdate = ($cutoff).AddMonths(-6)
        
        Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" - Cleaning "+$server.tag_name+" with cutoff = "+$cutoff.ToString())

        while($Filterdate -le $cutoff)
        {
            $FileFilter = $Drive.Name+":\"+$BackupTypes[$BT]+"_"+$Filterdate.tostring("yyyyMMdd")+"*.BAK"
            Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" - Cleaning with filter "+$FileFilter+" for date "+$Filterdate.ToString("yyyy-MM-dd")+" respecting cutoff "+$cutoff.ToString())
            Get-ChildItem -Path $FileFilter | Where-Object{($_.LastWriteTime -lt $cutoff)} | Remove-Item -Force
            $Filterdate=$Filterdate.AddDays(1)
        }
        
        Remove-PSDrive -Name $NewDrive
        Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" - remove map "+$map_path)
        Add-Content -Path $LogFile -Value ("--------------------------------------------------------------------------------------------------")
    }
}
