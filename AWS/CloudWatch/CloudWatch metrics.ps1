cls
Set-AWSCredential -AccessKey  -SecretKey 

$region = "us-east-1"
$namespace = "AWS/EC2"

$filterValues =  New-Object 'collections.generic.list[string]'
$filterValues.Add("i-01e3fd9c5bfc144b3")
$filterValues.Add("i-049a439291ca4a018")

$filter = New-Object Amazon.CloudWatch.Model.DimensionFilter -Property @{Name="InstanceId"; Value=$filterValues}

Get-CWMetricList -Region $region -Namespace $namespace -MetricName "StatusCheckFailed_Instance" -Dimension $filter