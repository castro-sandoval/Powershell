Set-AWSCredentials -AccessKey  -SecretKey 

$region = "us-east-1"
$filter = @{Name="vpc-id";Value="vpc-85d2f7e3"}

(Get-EC2Instance -Region $region -Filter $filter -InstanceId i-01e3fd9c5bfc144b3).Instances

(Get-EC2Instance -Filter @{Name="vpc-id";Value="vpc-85d2f7e3"},@{Name="instance-id";Value="i-01e3fd9c5bfc144b3"}).Instances

(Get-EC2Instance -Filter @{Name="instance-id";Value=@("i-01e3fd9c5bfc144b3";"i-049a439291ca4a018")}).Instances


#=========================================
$filter_values = New-Object 'collections.generic.list[string]' 
$filter_values.add("i-01e3fd9c5bfc144b3") 
$filter = New-Object Amazon.EC2.Model.Filter -Property @{Name = "InstanceId"; Values = $filter_values} 
(Get-EC2Instance -Region $region -Filter $filter ).Instances
