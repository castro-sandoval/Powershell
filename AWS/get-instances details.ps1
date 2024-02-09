
Set-AWSCredential -AccessKey  -SecretKey 

#*****************************************************************************************
Get-EC2InstanceAttribute -InstanceId i-01e3fd9c5bfc144b3 -Attribute instanceType


#*****************************************************************************************
#            One instance
#*****************************************************************************************
$Region="us-east-1"
$filter =  @{Name="instance-id";Value="i-02c615023df396685"}
$instance = (Get-EC2Instance -Region $Region -Filter $filter).Instances
$Ref_instance_info = ($instance[0] | select tag, InstanceId, InstanceType, Platform, PrivateIpAddress, PublicIpAddress, SubnetId)
write-host(".......... Instance details ............")
write-host($Ref_instance_info.InstanceType)
write-host($Ref_instance_info.Platform)
write-host($Ref_instance_info.PrivateIpAddress)
write-host($Ref_instance_info.SubnetId)
write-host($Ref_instance_info.se)

$status = (Get-EC2InstanceStatus -InstanceId $Ref_instance_info.InstanceId -Region $Region| Select -Property Status)
if ($status.Status) {
    "Running ("+$status.Status.Details.name+" / "+$status.Status.Details.Status+")"
    write-host(".......... Tags ............")
    $tags = ($instance | select -ExpandProperty tag)
    foreach($tag in $tags) {
        $tag.key+" = "+$tag.value
    }
} else {
    "N/A;"+$InstanceInfo+";Stopped; *** Not reachable ***"
}


#*****************************************************************************************
#            Many instances
#*****************************************************************************************

#==============================================================================
$region="eu-central-1"
$filter =  @{Name="instance-id";Value="i-05ce655bfa137443a"}
$LLamadevVMs = (Get-EC2Instance -Region $region -Filter $filter).Instances
foreach($LLamadevVM in $LLamadevVMs) {
    
    
    $VMDetails = ($LLamadevVM | select tag, InstanceId, InstanceType, Platform, PrivateIpAddress, PublicIpAddress, SubnetId)
    
    $InstanceInfo = $VMDetails.InstanceId+";"+$VMDetails.InstanceType+";"+$VMDetails.Platform+";"+$VMDetails.PrivateIpAddress+";"+$VMDetails.PublicIpAddress+";"+$VMDetails.SubnetId

    $status = (Get-EC2InstanceStatus -InstanceId $VMDetails.InstanceId | Select -Property Status)
    if ($status.Status) {
         $name = ($LLamadevVM.tag | Where-Object {$_.key -eq "Name"} | select -Property Value).Value
         $name
         $InstanceInfo
         "Running"
         $status.Status.Details.name
         $status.Status.Details.Status
    } else {
        "N/A;"+$InstanceInfo+";Stopped; *** Not reachable ***"
    }
}




