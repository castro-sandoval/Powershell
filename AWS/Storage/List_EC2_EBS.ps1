Set-AWSCredentials -AccessKey AKIAIK6ODY2F7MFNUVBQ -SecretKey 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


"InstanceId;name;IP;InstanceType;VolumeId;CreateTime;SizeGB;State;VolumeType;Iops" | Out-File -FilePath "c:\temp\AWS_volumes.csv"

#$Instances = (Get-EC2Instance -InstanceId "i-01e3fd9c5bfc144b3").instances 
$Instances = (Get-EC2Instance).instances

foreach ($instance in $Instances)
{
    $name = ($instance.tag | Where-Object {$_.key -eq "Name"}).Value
    $volumes = @(get-ec2volume) | ? { $_.Attachments.InstanceId -eq $instance.InstanceId}
    
    $ip = $instance.NetworkInterfaces[0].PrivateIpAddress

    
    foreach($volume in $volumes) {
        $instance.InstanceId+";"+$name+";"+$IP+";"+$instance.InstanceType.Value+";"+$volume.VolumeId+";"+$volume.CreateTime.ToString("yyyy-MM-dd hh:mm")+";"+$volume.Size.ToString()+";"+$volume.State+";"+$volume.VolumeType+";"+$volume.Iops.ToString() | Out-File -FilePath "c:\temp\AWS_volumes.csv" -Append
  
    
    }

}