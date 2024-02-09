Set-AWSCredential -AccessKey AKIAIK6ODY2F7MFNUVBQ -SecretKey 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


Clear-Host

$bucketname="lcp2-sql-backups-us-east-1"
$folders=@("PermissionEntities") # "ModelingEntities","PrivilegeEntities","QueueingEntities","SessionEntities","AppBuilderEntities","AssetEntities","AuthenticationEntities","ConnectionEntities","DatabaseServices")


foreach($folder in $folders) {
    $folderskeys = (Get-S3Object -BucketName $bucketname -Keyprefix $folder ).key
    foreach($key in $folderskeys) {

        $DestKey = "RDS_DEV"+ $key.Substring($key.IndexOf("/"), $key.Length-$key.IndexOf("/"))

        Write-Host ("Copying "+$key) -ForegroundColor Green
        Copy-S3Object -BucketName $bucketname -Key $key -DestinationKey $DestKey

        Write-Host ("Deleting "+$key) -ForegroundColor Yellow
        Remove-S3Object -BucketName $bucketname -Key $key -Force


    }

}
<#


#>