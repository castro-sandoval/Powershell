
Set-AWSCredentials -AccessKey  -SecretKey 
Clear-Host

$NewInstanceID="i-01c0efc5118b4348d"

$status = Get-EC2InstanceStatus -InstanceId $NewInstanceID -Region us-east-1

$status.SystemStatus.Details.Status
$status.SystemStatus.Status.Value
$status.InstanceState.Name
