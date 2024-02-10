param ([Parameter(Mandatory)] $instanceName, [Parameter(Mandatory)] $masterserver, [Parameter(Mandatory)] $SQLUsername, [Parameter(Mandatory)] $SQLPassword)

#===== get target server_id ============
$query="SELECT @@SERVERNAME AS server_name"
$dataset=(Invoke-Sqlcmd -ServerInstance $instanceName -Database "master" -Username $SQLUsername -Password $SQLPassword -Query $query)
$query=("SELECT [server_id] FROM ["+$masterserver+"].[DATAOPS].[Targets].[Instances] WHERE [Server_name]='"+$dataset.server_name+"'")
$dataset=(Invoke-Sqlcmd -ServerInstance $instanceName -Database "master" -Username $SQLUsername -Password $SQLPassword -Query $query)
$serverid=$dataset.server_id

#===== report disk space information to master from this target server_id ============
$diskInfo = get-WmiObject win32_logicaldisk | Select DeviceID, Size, FreeSpace
foreach($disk in $diskInfo)
{
    $query="INSERT INTO ["+$masterserver+"].[DATAOPS].[Targets].[DiskSpace]([server_id], [Drive], [TotalSizeMB], [FreeSpaceMB]) VALUES ("+$serverid.ToString()+",'"+$disk.DeviceId.Substring(0,1)+"',"+($disk.size/1000000).ToString()+","+($disk.FreeSpace/1000000).ToString()+")"
    Invoke-Sqlcmd -ServerInstance $instanceName -Database "master" -Username $SQLUsername -Password $SQLPassword -Query $query
}