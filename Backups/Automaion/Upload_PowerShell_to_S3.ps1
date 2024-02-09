cls

<#==================================================================================================================================
    Constants definition
==================================================================================================================================#>
$LocalFolder     = "C:\Users\sandoval.castroneto\Documents\LLamasoft\DEVOPS\Back up project\Powershell\"
                    
$LogFileName     = "UploadToS3_"+(Get-Date).ToString("yyyyMMdd_HHmm")+".log"
$LogFileFullName = $LocalFolder+$LogFileName
$BulkFolder      = "lcp2-sql-backups-us-east-1"
$Prefix          = "/Bin/"

#==================================================================================================================================
# Get .ps1 files from local folder
$filesToCopy = (Get-ChildItem -Path ($LocalFolder+"\*.ps1"))


Add-Content -Path $LogFileFullName -Value ($filesToCopy.Count.ToString()+" files to upload tp S3 bucket/Bin.")
foreach ($file in $filesToCopy)
{
    $S3file = Get-S3Object -BucketName $BulkFolder -Key ($Prefix+$file.Name)
    if ($S3file.Key -gt 0) {
        if ($file.CreationTime -gt $S3file.LastModified) {
            Add-Content -Path $LogFileFullName -Value ("Local file "+$file.Name+" is newer than S3. Uploading "+$BulkFolder+$file.Name)
            Write-S3Object -BucketName $BulkFolder -Key ($Prefix+$file.Name) -File $file.FullName
            Write-Host ("Updating "+$file.Name) -BackgroundColor DarkGreen -ForegroundColor White
        } else {
            Add-Content -Path $LogFileFullName -Value ("Local file "+$file.Name+" found in S3 as "+$BulkFolder+$file.Name)
            Write-Host ("No action for "+$file.Name) -ForegroundColor Yellow
        }
    } else 
    {
        Add-Content -Path $LogFileFullName -Value ("File "+$file.Name+" not found in S3. Uploading "+$BulkFolder+$file.Name)
        Write-S3Object -BucketName $BulkFolder -Key ($Prefix+$file.Name) -File $file.FullName
        Write-Host ("Uploading "+$file.Name) -ForegroundColor Green
    }
    
}

Get-ChildItem -Path ($LocalFolder+"UploadToS3_*.log") | Where-Object {($_.CreationTime -lt ((Get-Date).AddDays(-7)))} | Remove-Item -Force