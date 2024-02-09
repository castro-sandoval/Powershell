Set-AWSCredential -AccessKey  -SecretKey 

$region = "us-east-1"

$dimension = New-Object Amazon.CloudWatch.Model.Dimension
$dimension.Name = "Server_name"
$dimension.Value = (((Get-EC2Instance -Region $region -Filter @{Name="network-interface.addresses.private-ip-address";Value=(Get-WmiObject Win32_NetworkAdapterConfiguration|Where {$_.Ipaddress.length -gt 1}).ipaddress[0]}).Instances).tag | Where-Object {$_.key -eq "Name"} | select -Property Value).value

$metricDatum = New-Object Amazon.CloudWatch.Model.MetricDatum
$metricDatum.Dimensions = New-Object System.Collections.Generic.List[$dimension]
$metricDatum.Dimensions.Add($dimension)
$metricDatum.MetricName = "Number of FULL backup files backed up"
$metricDatum.StatisticValues = New-Object Amazon.CloudWatch.Model.StatisticSet
$metricDatum.Timestamp = Get-Date
$metricDatum.Unit = "Count"
$metricDatum.Value = (Get-ChildItem -Path "D:\Backups\FULL*.bak" | Where-Object {($_.LastWriteTime -ge (Get-Date).AddHours(-12))}).Length

$metricDatum = New-Object Amazon.CloudWatch.Model.MetricDatum
$metricDatum.Dimensions = New-Object System.Collections.Generic.List[$dimension]
$metricDatum.Dimensions.Add($dimension)
$metricDatum.MetricName = "Number of DIFFERENTIAL backup files backed up"
$metricDatum.StatisticValues = New-Object Amazon.CloudWatch.Model.StatisticSet
$metricDatum.Timestamp = Get-Date
$metricDatum.Unit = "Count"
$metricDatum.Value = (Get-ChildItem -Path "D:\Backups\DIFF*.bak" | Where-Object {($_.LastWriteTime -ge (Get-Date).AddHours(-12))}).Length


$metricDatum = New-Object Amazon.CloudWatch.Model.MetricDatum
$metricDatum.Dimensions = New-Object System.Collections.Generic.List[$dimension]
$metricDatum.Dimensions.Add($dimension)
$metricDatum.MetricName = "Number of LOG backup files backed up"
$metricDatum.StatisticValues = New-Object Amazon.CloudWatch.Model.StatisticSet
$metricDatum.Timestamp = Get-Date
$metricDatum.Unit = "Count"
$metricDatum.Value = (Get-ChildItem -Path "D:\Backups\LOG*.bak" | Where-Object {($_.LastWriteTime -ge (Get-Date).AddHours(-12))}).Length


Write-CWMetricData -Region $region -Namespace "Backup-metric" -MetricData $metricDatum -Force