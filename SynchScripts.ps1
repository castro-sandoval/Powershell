


$logFile = ($Args[0]+"synch.log")
if (Test-Path -Path $logFile) {
    Remove-Item -Path $logFile -Force
}




$S3Files=(Get-S3Object  -Bucket "lcp2-sql-backups-us-east-1" -KeyPrefix "/Bin/")
foreach($S3File in $S3Files)
{
    $filePath = $Args[0]+$S3File.Key.Remove(0,4)
    if (Test-Path -Path $filePath) {
        $localFile = Get-ChildItem -Path $filePath
        if ($localFile.LastWriteTime -lt $S3File.LastModified)
        {
            Add-Content -Path $logFile -Value ("replacing "+$filePath)
            Remove-Item -Path $filePath
            Read-S3Object -BucketName lcp2-sql-backups-us-east-1 -Key $S3File.Key -File $localFile.FullName
        } else {
            Add-Content -Path $logFile -Value ("No need to update "+$filePath)
        }
    }
    else
    {
        Read-S3Object -BucketName lcp2-sql-backups-us-east-1 -Key $S3File.Key -File $filePath
        Add-Content -Path $logFile -Value ("Adding "+$filePath)
    } 
    

}

