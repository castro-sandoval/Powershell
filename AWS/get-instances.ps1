Set-AWSCredential -AccessKey  -SecretKey 
$region = "eu-central-1"

Clear-Host

$nodes = (Get-EC2Instance -Region $region -InstanceId "i-0b9ad7e2deb97a10f").Instances

foreach($node in $nodes)
{
    $nodedetails = ($node | select InstanceId, InstanceType, PrivateIpAddress)
    
    $nodedetails.InstanceId
    $nodedetails.InstanceType.Value
    $nodedetails.PrivateIpAddress
    
    $tag_name = $node | select -ExpandProperty tag | ?{$_.Key -eq "Name"}
    write-host $tag_name.Value -ForegroundColor Yellow




}