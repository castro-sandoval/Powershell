$AWS_Account = "927"
$region      = "us-east-1"

<#***********************************************************************************************************************************************
        Set credentials for AWS account
***********************************************************************************************************************************************#>
if ($AWS_Account -eq "066")
{
    $AccessKey=""
    $SecretKey=""
}
else
{
    $AccessKey=""
    $SecretKey=""
}
    
<#***********************************************************************************************************************************************

***********************************************************************************************************************************************#>
Clear-Host

Get-R53HostedZones -AccessKey $AccessKey -SecretKey $SecretKey -Region $region

Get-R53ResourceRecordSet -HostedZoneId /hostedzone/Z1WAMU98HQX9ZC -StartRecordType A -AccessKey $AccessKey -SecretKey $SecretKey -MaxItem 10 # -Select '^ParameterName'