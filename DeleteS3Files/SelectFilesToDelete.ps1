$binFolder = "C:\Dataops\bin"
Import-Module -Name ($binFolder+"\DFTlibrary.dll")
$AccessKey = Get-awsaccessKey
$SecretKey = Get-awssecretkey
$sqllogin = Get-sqllogin
$sqlpwrd  = Get-sqlpwrd

$KeyFile = "c:\temp\cleanS3.txt"
$Bucket  = "lcp2-sql-backups-us-east-1"

#============================================================
if (Test-Path -Path $KeyFile)
{
    Remove-Item -Path $KeyFile -Force
}


$Prefix = "IP-0AE87D14"

Write-Host ("Searching "+$Prefix)

$files = Get-S3Object -BucketName $Bucket -MaxKey 30000 -KeyPrefix $Prefix -AccessKey $AccessKey -SecretKey $SecretKey #| Where-Object {(($_.Key).Substring(1,5) -eq "DIFF_")}
foreach($file in $files) {
    Add-Content -Path $KeyFile -Value ($file.key)
}
Write-Host ("Finished adding objects to files.")
Write-Host ($files.Count.ToString()+" files.")