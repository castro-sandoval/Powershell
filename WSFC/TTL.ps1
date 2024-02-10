Import-Module FailoverClusters  

$nameResource = "SQL Network Name (SQL35)"  
Get-ClusterResource $nameResource | Set-ClusterParameter ClusterParameter HostRecordTTL 300