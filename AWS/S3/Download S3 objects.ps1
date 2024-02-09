cls
Set-AWSCredential -AccessKey AKIAIK6ODY2F7MFNUVBQ -SecretKey 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

$BucketName="lcp2-sql-backups-us-east-1"
#$key="IP-0AE87D75\Backups\Week_20190422\D:Backups\FULL_20190422060012_DIPS_App_2950739d-3c95-4cc6-bb64-e2a0445f4cd2.bak"
$key="IP-0AE87D75\Backups\Week_20190422\D:Backups\FULL_20190422060012_DIPS_App_a85cd829-88b5-4277-b660-e541b5d5ca4a.bak"
$file = "C:\Databases\Download\FULL_20190422060012_DIPS_App_a85cd829-88b5-4277-b660-e541b5d5ca4a.bak"

Read-S3Object -BucketName $BucketName -Key $key -File $file

#=========================================================================================================================================

<#

cls
Set-AWSCredential -AccessKey AKIAIK6ODY2F7MFNUVBQ -SecretKey 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

$BucketName="lcp2-sql-backups-us-east-1"
$DestinationFolder = "C:\Databases\scgX_Models"

$keys = (Get-S3Object -BucketName $BucketName -KeyPrefix "/IP-0AE87D75/Backups/Week_20180924/" | Where-Object {$_.Key -eq "FULL_20180928060006_SCG_MDL_882_55481c78-39d8-406d-ab45-c6c2062514ef.bak" } ).Key | Sort-Object -Property Key


foreach($key in $keys) {
    $file = ($DestinationFolder+(Split-Path $key -leaf))
    Write-Host ("Downloading "+$key+" ...")
    Read-S3Object -BucketName $BucketName -Key $key -File $file
    Write-Host ($File+" downloaded.")
    
}

#>