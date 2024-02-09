

$AgeLimit    = (Get-Date).AddMonths(-1).AddDays(-((Get-Date).AddMonths(-1)).DayOfWeek.value__ + 1).ToString("yyyyMMdd")
$LogFileName = ("C:\Users\Sandoval.CastroNeto\Desktop\S3BucketCleanup_"+(Get-Date).ToString("yyyyMMdd_HHmm")+".log")


<#********************************************************************************************************************************************
                Delete old files that should not be inside some folders
********************************************************************************************************************************************#>
Add-Content -Path $LogFileName -Value ("Check old files that should not be inside some folders")
$objs = (Get-S3Object -BucketName lcp2-sql-backups-us-east-1 -KeyPrefix "/" | Where-Object {( (($_.key.Substring($_.key.IndexOf("Week_")+5,8) -gt $_.key.Substring($_.key.IndexOf("/FULL_")+6,8))) -or (($_.key.Substring($_.key.IndexOf("Week_")+5,8) -gt $_.key.Substring($_.key.IndexOf("/DIFF_")+6,8))) -or (($_.key.Substring($_.key.IndexOf("Week_")+5,8) -gt $_.key.Substring($_.key.IndexOf("/LOG_")+5,8)))     ) }).Key 
Add-Content -Path $LogFileName -Value ("Files to delete: "+$objs.Count.ToString())
Write-Host ($objs.count.ToString()+" files found.")
$ToDelete = 0
if ($objs.Length -gt 0) {
    foreach($obj in $objs) {
        Add-Content -Path $LogFileName -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss:fff")+" | Deleting "+$obj)
        $ToDelete +=1
    }
} else {
    Add-Content -Path $LogFileName -Value "No files found to delete."
}
Write-Host ($ToDelete.ToString()+" files to delete.")