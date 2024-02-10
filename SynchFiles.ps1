Import-Module -Name ("C:\Dataops\bin\DFTlibrary.dll")
$AccessKey = Get-awsaccessKey
$SecretKey = Get-awssecretkey

$RootFolder   = "C:\Dataops\bin\"
$logFile      = ($RootFolder+"synch.log")
$Bucket       = "lcp2-sql-backups-us-east-1"
$BucketFolder = "/Bin/"

#=======================================================================

if (Test-Path -Path $logFile) {
    $OldLog = $logFile.Replace(".log",".old")
    if (Test-Path -Path $OldLog) {
        Remove-Item -Path $OldLog -Force
    }
    Rename-Item -Path $logFile -NewName $OldLog
}

$S3Files=(Get-S3Object  -Bucket $Bucket -KeyPrefix $BucketFolder -AccessKey $AccessKey -SecretKey $SecretKey)
foreach($S3File in $S3Files)
{
    $filePath = $RootFolder+$S3File.Key.Remove(0,4)
    if (Test-Path -Path $filePath) {
        $localFile = Get-ChildItem -Path $filePath
        if ($localFile.LastWriteTime -lt $S3File.LastModified)
        {
            Add-Content -Path $logFile -Value ( (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") +" - replacing "+$filePath)
            Remove-Item -Path $filePath
            Read-S3Object -AccessKey $AccessKey -SecretKey $SecretKey -BucketName $Bucket -Key $S3File.Key -File $localFile.FullName
        } else {
            Add-Content -Path $logFile -Value ("No need to update "+$filePath)
        }
    }
    else
    {
        Read-S3Object -AccessKey $AccessKey -SecretKey $SecretKey -BucketName $Bucket -Key $S3File.Key -File $filePath
        Add-Content -Path $logFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" - Adding "+$filePath)
    } 
}


