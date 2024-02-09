cls

$ip = "10.232.25.19"
(Get-EC2Instance -Region $region -AccessKey AKIAIK6ODY2F7MFNUVBQ -SecretKey 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).Instances | Where-Object {($_.NetworkInterfaces.PrivateIpAddress -eq $ip)} | select -ExpandProperty tag | ?{$_.Key -eq "Name"}
