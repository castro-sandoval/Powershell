
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


$metrics = Get-PSDrive -PSProvider FileSystem | Select -Property Name, Free
foreach ($metric in $metrics) {
    $metricDatum.MetricName = ("FreeDiskSpaceGB_"+$metric.Name)
    $metricDatum.Value = $metric.Free/1024/1024/1024
    Write-CWMetricData -Region $region -Namespace "Server-Monitoring" -MetricData $metricDatum -Force
}
