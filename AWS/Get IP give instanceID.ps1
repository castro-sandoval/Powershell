cls

Set-AWSCredentials -AccessKey  -SecretKey 
$Instances = (Get-EC2Instance -InstanceId "i-01e3fd9c5bfc144b3").instances 

foreach ($instance in $Instances)
{
    $ip=$instance.NetworkInterfaces[0].PrivateIpAddress
    $name = ($instance.tag | Where-Object {$_.key -eq "Name"}).Value
    $name+" : "+$ip
}