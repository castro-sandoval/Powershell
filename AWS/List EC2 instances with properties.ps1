Clear-Host

$AWS_Account="066"
$TagnameEnvFilter="staging"
$TagFilter="pool1*"

#$filter =  @{Name="vpc-id";Value="vpc-85d2f7e3"},@{Name="instance-id";Value="i-05b90c1bbc0970c7b"}

#$filter = @{Name="instance-id";Value=@("i-05b90c1bbc0970c7b";"i-0fb51aa0b4438af45")}

$filter = @{Name="tag:Name";Value=@($TagFilter)},@{Name="tag:Name";Value=@("*-"+$TagnameEnvFilter+"*")}

<#***********************************************************************************************************************************************
        Set credentials for AWS account
***********************************************************************************************************************************************#>
if ($AWS_Account -eq "066")
{
    $AccessKey=""
    $SecretKey="+"
}
else
{
    $AccessKey=""
    $SecretKey=""
}



#((Get-EC2Instance -AccessKey $AccessKey -SecretKey $SecretKey -Region "us-east-1" -InstanceId "i-05b90c1bbc0970c7b").Instances).Placement.AvailabilityZone


$Instances=(Get-EC2Instance -AccessKey $AccessKey -SecretKey $SecretKey -Region "us-east-1" -Filter $filter).Instances
foreach($Instance in $Instances) 
{
    
    
    # simple
    ($instance.tag | Where-Object {$_.key -eq "Name"} | select -Property Value).Value +";"+$Instance.PrivateIpAddress

    # detailed
    #($instance.tag | Where-Object {$_.key -eq "Name"} | select -Property Value).Value +";"+$Instance.InstanceId+";"+$Instance.InstanceType+";"+$Instance.Platform+";"+$Instance.PrivateIpAddress+";"+$Instance.SubnetId+";"+$Instance.Placement.AvailabilityZone+";"+$Instance.EbsOptimized+";"+$Instance.ImageId+";"+$Instance.LaunchTime

}


