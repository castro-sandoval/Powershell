$AccessKey=""
$SecretKey=""
cls
$region = "us-east-1" 
#$region = "eu-central-1"
$ip = "10.232.125.73"
$instance=(Get-EC2Instance -AccessKey $AccessKey -SecretKey $SecretKey -Region $region -Filter @{Name="network-interface.addresses.private-ip-address";Value=$ip}).Instances
$instance[0].InstanceType.Value

$name = $instance.tag | Where-Object {$_.key -eq "Name"} | select -Property Value
$InstanceID = $instance[0].InstanceId
Write-Host ("machine name for IP "+$ip+" is "+($name).Value+"   Instance ID: "+$InstanceID)


<#

$name = (((Get-EC2Instance -Region "us-east-1" -Filter @{Name="network-interface.addresses.private-ip-address";Value=(Get-WmiObject Win32_NetworkAdapterConfiguration|Where {$_.Ipaddress.length -gt 1}).ipaddress[0]}).Instances).tag | Where-Object {$_.key -eq "Name"} | select -Property Value).value

Write-Host ("machine name: "+$name)
#>