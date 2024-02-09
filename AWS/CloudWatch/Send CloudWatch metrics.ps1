Set-AWSCredential -AccessKey  -SecretKey 

$hours = -2
$region = "us-east-1"
$dimension = New-Object Amazon.CloudWatch.Model.Dimension
$dimension.Name = "Server_name"
$dimension.Value = (((Get-EC2Instance -Region $region -Filter @{Name="network-interface.addresses.private-ip-address";Value=(Get-WmiObject Win32_NetworkAdapterConfiguration|Where {$_.Ipaddress.length -gt 1}).ipaddress[0]}).Instances).tag | Where-Object {$_.key -eq "Name"} | select -Property Value).value

$metricDatum = New-Object Amazon.CloudWatch.Model.MetricDatum
$metricDatum.Dimensions = New-Object System.Collections.Generic.List[$dimension]
$metricDatum.Dimensions.Add($dimension)
$metricDatum.StorageResolution = 60
$metricDatum.Timestamp = Get-Date
$metricDatum.StatisticValues = New-Object Amazon.CloudWatch.Model.StatisticSet
$metricDatum.Unit = "Count"


$metricDatum.MetricName = "Number of new FULL backup"
$metricDatum.Value = (Get-ChildItem -Path "D:\Backups\FULL*.bak" | Where-Object {($_.LastWriteTime -ge (Get-Date).AddHours($hours))}).Length
Write-CWMetricData -Region $region -Namespace "Backup-metric" -MetricData $metricDatum -Force

$metricDatum.MetricName = "Number of new DIFFERENTIAL backup files"
$metricDatum.Value = (Get-ChildItem -Path "D:\Backups\DIFF*.bak" | Where-Object {($_.LastWriteTime -ge (Get-Date).AddHours($hours))}).Length
Write-CWMetricData -Region $region -Namespace "Backup-metric" -MetricData $metricDatum -Force

$metricDatum.MetricName = "Number of new LOG backup files"
$metricDatum.Value = (Get-ChildItem -Path "D:\Backups\LOG*.bak" | Where-Object {($_.LastWriteTime -ge (Get-Date).AddHours($hours))}).Length
Write-CWMetricData -Region $region -Namespace "Backup-metric" -MetricData $metricDatum -Force