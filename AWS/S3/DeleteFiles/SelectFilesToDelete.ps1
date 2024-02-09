Clear-Host
$binFolder = "C:\Users\sandoval.castroneto\Documents\Projects\Back up project\Powershell\bin"
Import-Module -Name ($binFolder+"\DFTlibrary.dll")
$AccessKey = Get-awsaccessKey
$SecretKey = Get-awssecretkey
$sqllogin = Get-sqllogin
$sqlpwrd  = Get-sqlpwrd

$KeyFile = "c:\temp\cleanS3.txt"
$Bucket  = "lcp2-sql-backups-us-east-1"
$BAKTypes = @("LOG","DIFF","FULL")

$Folder = "IP-0AE87C31"

#============================================================

$Prefix = $Folder

    if (Test-Path -Path $KeyFile)
    {
        Remove-Item -Path $KeyFile -Force
    }
    $files = Get-S3Object -BucketName $Bucket -MaxKey 100 -KeyPrefix $Prefix -AccessKey $AccessKey -SecretKey $SecretKey #| Where-Object {(($_.Key).Substring(1,5) -eq "DIFF_")}
    if ($files.Count -gt 0)
    {
        foreach($file in $files) {
            Add-Content -Path $KeyFile -Value ($file.key)
        }
    }
    Write-Host ("SelectFiles = "+$files.Count.ToString()+" files.") -ForegroundColor Yellow

