
Clear-Host

Set-AWSCredentials -AccessKey  -SecretKey 

$filter = New-Object Amazon.Pricing.Model.filter
$filter.Field = "instanceType"
$filter.Value = "m5.xlarge"
$filter.Type = "TERM_MATCH"

$filters = @()
$filters+=$filter

$filter = New-Object Amazon.Pricing.Model.filter
$filter.Field = "operatingSystem"
$filter.Value = "Windows"
$filter.Type = "TERM_MATCH"
$filters+=$filter


$filter = New-Object Amazon.Pricing.Model.filter
$filter.Field = "location"
$filter.Value = "US East (Ohio)"
$filter.Type = "TERM_MATCH"
$filters+=$filter

$filter = New-Object Amazon.Pricing.Model.filter
$filter.Field = "ImageId"
$filter.Value = "ami-0877183549a95ceba"
$filter.Type = "TERM_MATCH"
$filters+=$filter


#Remove-Item -Path C:\Temp\PLSProduct.json -Force

(Get-PLSProduct -ServiceCode AmazonEC2 -Region us-east-1 -MaxResult 10 -Filter $filters) | Where-Object {($.des)}

# | ConvertTo-Json | Out-File C:\Temp\PLSProduct.json

#Get-PLSAttributeValue -ServiceCode AmazonEC2 -AttributeName "volumeType" -region us-east-1