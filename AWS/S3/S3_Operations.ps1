#Set-AWSCredential -AccessKey AKIAIK6ODY2F7MFNUVBQ -SecretKey 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
Set-AWSCredential -AccessKey AKIAQ7FRZQP3ZO7BLDLL -SecretKey 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



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



#******************** UPLOAD to S3 ***************************
#Set-AWSCredential -AccessKey AKIAIK6ODY2F7MFNUVBQ -SecretKey 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
Set-AWSCredential -AccessKey AKIAQ7FRZQP3ZO7BLDLL -SecretKey 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
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




#***************************** delete files **********************************
Set-AWSCredentials -AccessKey AKIAIK6ODY2F7MFNUVBQ -SecretKey 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
$AgeLimit    = ((Get-Date).AddMonths(-1)).ToString("yyyyMMdd_0000")
$LogFileName = ("D:\Backups\S3BucketCleanup_"+(Get-Date).ToString("yyyyMMdd_HHmm")+".log")
Add-Content -Path $LogFileName -Value ("Removing files older than "+$AgeLimit)
$KeyPref = ("/"+(Get-ChildItem -path env:computername | select -Property Value -Verbose).Value+"/Backups/")
$objs =  (Get-S3Object -BucketName lcp2-sql-backups-us-east-1 -KeyPrefix $KeyPref | Where-Object {($_.Key.Substring(20,13) -lt $AgeLimit )}).Key
Add-Content -Path $LogFileName -Value ("Files to delete: "+$objs.Count.ToString())
if ($objs.Length -gt 0) {
    Add-Content -Path $LogFileName -Value $objs
    Remove-S3Object -BucketName lcp2-sql-backups-us-east-1 -KeyCollection $objs -Force
} else {
    Add-Content -Path $LogFileName -Value "No files found to delete."
}




#---------------- delete de last folder only ----------------------

Set-AWSCredentials -AccessKey AKIAIK6ODY2F7MFNUVBQ -SecretKey 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

#******************** List files from a S3 Bucket ***************************
cls
$objs = Get-S3Object -BucketName lcp2-sql-backups-us-east-1 -KeyPrefix /IP-0AE81B47/Backups/
$FolderToDelete = "99999999_9999"
foreach($obj in $objs) {
    if ($obj.key.Substring(20,13) -le $FolderToDelete) {
        $FolderToDelete=$obj.key.Substring(19,15)
    }
}
Write-Host $FolderToDelete

$objs = (Get-S3Object -BucketName lcp2-sql-backups-us-east-1 -KeyPrefix /IP-0AE81B47/Backups/ | Where-Object {($_.Key -like ("*"+$FolderToDelete+"*"))} | Select -Property Key).Key
Add-Content -Path "D:\Backups\AWS_Cleanup.log" -Value $objs
Remove-S3Object -BucketName lcp2-sql-backups-us-east-1 -KeyCollection $objs -Force



#*******************************************************************
#  Clean local DIFF files older than the last FULL file
#*******************************************************************
Set-AWSCredentials -AccessKey AKIAIK6ODY2F7MFNUVBQ -SecretKey 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

#Get last FULL backup
$LogFile = "D:\Backups\Backups.log"
$LastFullBkups = Get-Item -Path "d:\Backups\FULL*.bak" | Select -Property Name, LastWriteTime
foreach($FullBkupFile in $LastFullBkups) {
    $DiffFilename = "D:\Backups\DIFF_*_"+($FullBkupFile.Name.SubString(20, $FullBkupFile.Name.Length-20))
    $FileToRemove = (Get-Item -Path $DiffFilename | Where-Object ({$_.LastWriteTime -gt $FullBkupFile.LastWriteTime})  ).FullName
    if ($FileToRemove.Length -gt 0) {
        Add-Content -Path $LogFile -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" : Removing "+$FileToRemove)
        #Remove-Item -Filter $FileToRemove
    } 
}
