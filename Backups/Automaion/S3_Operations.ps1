

#******************** List files from a S3 Bucket ***************************
cls
$files = Get-S3Object -BucketName lcp2-sql-backups-us-east-1 -KeyPrefix /IP-0AE81B47/Backups/20180606_1000
$MinfileAge = (Get-Date).AddMinutes(-1)

foreach($file in $files) {
    
    if ($file.LastModified -le $MinfileAge) {
        Write-Host ($file.LastModified.ToString()+" "+ $file.Key)
    }
    
}




#************* How to download a file from S3 ********************************************
Read-S3Object -BucketName lcp2-sql-backups-us-east-1/IP-0AE81B47/Backups -Key Backups.log -File c:\temp\Backups.log


#******************** Copy new backups to S3 ***************************
#************* Create a folder in a S3 buket ********************************************
$LogFileName     = "AWS_S3_"+(Get-Date).ToString("yyyyMMdd_HHmm")+".log"
$LogFileFullName = "D:\Backups\"+$LogFileName
$BulkFolder      = "lcp2-sql-backups-us-east-1/"+(Get-ChildItem -path env:computername | select -Property Value -Verbose).Value+"/Backups"
$NewFolder       = $BulkFolder+"/"+(Get-Date).ToString("yyyyMMdd_HHmm")
Write-S3Object -BucketName $NewFolder -Key "Backups.log" -File "D:\Backups\Backups.log"
$filesToCopy = (Get-ChildItem D:\Backups\*.bak | Where-Object {($_.CreationTime -gt ((Get-Date).AddHours(-6)))})
Add-Content -Path $LogFileFullName -Value ($filesToCopy.Count.ToString()+" files to upload tp S3 bucket.")
foreach ($file in $filesToCopy)
{
    Write-S3Object -BucketName $NewFolder -Key $file.Name -File $file.FullName
    Add-Content -Path $LogFileFullName -Value ("Uploading "+$file.Name+" "+$file.CreationTime.ToString("yyyy-MM-dd HH:mm"))
}
Write-S3Object -BucketName $BulkFolder -Key $LogFileName -File $LogFileFullName
