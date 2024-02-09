cls

$keys      = @("/EC2AMAZ-RO6HNPA/Backups/Week_20181105/FULL_20181105060021_2b028ee1-16e4-477d-920d-042c60b500bd.bak",
                "/IP-0AE81B47/Backups/Week_20181105/FULL_20181105060008_3PL_Assignment_Subset_f9894e0b-8682-45df-9436-2b77728a1b28.bak")

$DestFolder = "F:\BackupTest"
$region = "us-east-1"

if (!(Test-Path $DestFolder)) {
    New-Item -ItemType Directory $DestFolder
}


foreach($key in $keys) {
            
    $fileName = $key.Split("/")[4]
    $dbname = $fileName.Substring(20, $fileName.IndexOf(".")-20)

    <#
    Write-Host $dbname
    Write-Host $fileName
    Write-Host $key
    #>

    
    if (Test-Path ($DestFolder+"\"+$fileName)) {
        Remove-Item -Path ($DestFolder+"\"+$fileName) -Force
    }
    Read-S3Object -BucketName lcp2-sql-backups-us-east-1 -Region $region -AccessKey AKIAIK6ODY2F7MFNUVBQ -SecretKey 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 -Key $key -File ($DestFolder+"\"+$fileName)
    

    "RESTORE DATABASE ["+$dbname+"] FROM  DISK = N'F:\BackupTest\"+$fileName+"' WITH  FILE = 1,  NOUNLOAD,  STATS = 5"
    "DBCC CHECKDB (["+$dbname+"], NOINDEX) WITH PHYSICAL_ONLY"
    "DROP DTABASE ["+$dbname+"]"
    "--"
} # foreach key

