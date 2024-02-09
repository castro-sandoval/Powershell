Import-Module -Name ("C:\Dataops\bin\DFTlibrary.dll")
$AccessKey = Get-awsaccessKey
$SecretKey = Get-awssecretkey


#******************** List files from a S3 Bucket ***************************
cls
if (!(Test-Path -Path "C:\Install")) {
    New-Item -Path "C:\Install" -ItemType Directory
}
Read-S3Object -BucketName lcp2-sql-backups-us-east-1 -Key "Dataops/SolarWindsDPASetup-2022.4.0.72-x64.exe" -File ("C:\Install\SolarWindsDPASetup-2022.4.0.72-x64.exe") -AccessKey $AccessKey -SecretKey $SecretKey