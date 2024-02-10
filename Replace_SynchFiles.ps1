Import-Module -Name ("C:\Dataops\bin\DFTlibrary.dll")
$AccessKey = Get-awsaccessKey
$SecretKey = Get-awssecretkey

$Folder   = "C:\Dataops\bin\"
$FileName = "SynchFiles.ps1"
$File     = $Folder+$FileName
$Bucket   = "lcp2-sql-backups-us-east-1"
$BucketFolder = "/bin/"
if (Test-Path -Path $File) {
    Remove-Item -Path $File -Force
}
else
{
    if (!(Test-Path -Path $Folder -PathType Container)) {
        New-Item -Path $Folder -PathType Container
    }
}
Read-S3Object -AccessKey $AccessKey -SecretKey $SecretKey -BucketName $Bucket -Key ($BucketFolder+$FileName) -File $File
