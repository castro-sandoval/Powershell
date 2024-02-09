#Set-AWSCredential -AccessKey AKIAIK6ODY2F7MFNUVBQ -SecretKey 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
Set-AWSCredential -AccessKey AKIAQ7FRZQP3ZO7BLDLL -SecretKey 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


$key_to_download = "IP-0AE87B7A/Backups/Week_20210823/DATAOPS_backup_2021_08_19_063206_2223924.bak"


Function ExtractFilenameFromS3Key {
    param (
        [string] $S3key
    )
    $a = $S3key.ToCharArray()
    [array]::Reverse($a)
    $Filename = -join($a)
    $Filename=$Filename.Split("/")[0]
    $a = $Filename.ToCharArray()
    [array]::Reverse($a)
    $Filename = -join($a)

    return $Filename
}


$file="C:\Databases\Backup\"+(ExtractFilenameFromS3Key($key_to_download))

Clear-Host
Write-Host("Searching "+ $key_to_download)
Write-Host("Downloading to "+$file)



Read-S3Object -BucketName "lcp2-sql-backups-us-east-1" -Key $key_to_download -File $file


=========================================================================================================

# Your account access key - must have read access to your S3 Bucket
$accessKey = "xxxxxxxxxxx"
# Your account secret access key
$secretKey = "xxxxxxxx"
# The region associated with your bucket e.g. eu-west-1, us-east-1 etc. (see http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-regions)
$region = "us-east-1"
# The name of your S3 Bucket
$bucket = "ctm-backup-na10001.coupahost.com"
# The folder in your bucket to copy, including trailing slash. Leave blank to copy the entire bucket
$keyPrefix = "CTM-NA1-ScrubbedDev/"
# The local file path where files should be copied
$localPath = "E:\MSSQL\Backup\"    

$objects = Get-S3Object -BucketName $bucket -KeyPrefix $keyPrefix -AccessKey $accessKey -SecretKey $secretKey -Region $region

# $objects = Read-S3Object -BucketName $bucket -KeyPrefix $keyPrefix -AccessKey $accessKey -SecretKey $secretKey -Region $region
# $objects = Read-S3Object -BucketName "my-s3-bucket" -KeyPrefix "path/to/directory" -Folder

foreach($object in $objects) {
    $localFileName = $object.Key -replace $keyPrefix, ''
    if ($localFileName -ne '') {
        $localFilePath = Join-Path $localPath $localFileName
        Copy-S3Object -BucketName $bucket -Key $object.Key -LocalFile $localFilePath -AccessKey $accessKey -SecretKey $secretKey -Region $region
    }
}
