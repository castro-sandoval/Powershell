Clear-Host

Import-Module -Name "C:\dataops\bin\DFTLibrary.dll"

Pop-domain
Pop-Location
Pop-username

Get-awsaccessKey
Get-awssecretkey
Get-sqllogin
Get-sqlpwrd

Pop-domain
Pop-Location
Pop-username

<# 
Given [Id]

will update

 DATAOPS.dbo.creds.[sqllogin]
 DATAOPS.dbo.creds.[sqlpwrd]
 DATAOPS.dbo.creds.[awsaccessKey]
 DATAOPS.dbo.creds.[awsSecretKey]

#>
Set-Encrypt -Id -9223372036854775808

Set-Decrypt -Id 000000000


