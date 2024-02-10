Import-Module -Name ("C:\Dataops\bin\DFTlibrary.dll")
$AccessKey = Get-awsaccessKey
$SecretKey = Get-awssecretkey
Set-AWSCredential -AccessKey $AccessKey -SecretKey $SecretKey

$sqllogin = Get-sqllogin
$sqlpwrd  = Get-sqlpwrd

$user = Pop-username
$domain = Pop-domain
