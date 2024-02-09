
Write-Host "==================================================================================================="

$csvFile="c:\temp\LLamaDevVMs.csv"
Write-Host ("•	LLamaDev VMs -> VPC=vpc-85d2f7e3")
Write-Host ("Checking AWS and generating "+$csvFile+" ...")

Set-AWSCredentials -AccessKey AKIAIK6ODY2F7MFNUVBQ -SecretKey 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

$region = "us-east-1"
$filter =  @{Name="vpc-id";Value="vpc-85d2f7e3"}
if (Test-Path -Path $csvFile) {
    Remove-Item -Path $csvFile -Force
    Add-Content -Path $csvFile -Value ("Name;InstanceId;InstanceType;Platform;PrivateIpAddress;PublicIpAddress;SubnetId;Status;Reachable")
}

$LLamadevVMs = (Get-EC2Instance -Region $region -Filter $filter ).Instances
foreach($LLamadevVM in $LLamadevVMs) {
    
    
    $VMDetails = ($LLamadevVM | select tag, InstanceId, InstanceType, Platform, PrivateIpAddress, PublicIpAddress, SubnetId)
    
    $InstanceInfo = $VMDetails.InstanceId+";"+$VMDetails.InstanceType+";"+$VMDetails.Platform+";"+$VMDetails.PrivateIpAddress+";"+$VMDetails.PublicIpAddress+";"+$VMDetails.SubnetId

    $status = (Get-EC2InstanceStatus -InstanceId $VMDetails.InstanceId | Select -Property Status)
    if ($status.Status) {
         $name = ($LLamadevVM.tag | Where-Object {$_.key -eq "Name"} | select -Property Value).Value
         Add-Content -Path $csvFile -Value ($name+";"+$InstanceInfo+";Running;"+$status.Status.Details.name+":"+$status.Status.Details.Status)
    } else {
        Add-Content -Path $csvFile -Value ("N/A;"+$InstanceInfo+";Stopped; *** Not reachable ***")
    }
}
Write-Host ("All VMs found were exported to "+$csvFile)
