$binFolder = "C:\Dataops\bin"
Import-Module -Name ($binFolder+"\DFTlibrary.dll")
$AccessKey = Get-awsaccessKey
$SecretKey = Get-awssecretkey
$sqllogin = Get-sqllogin
$sqlpwrd  = Get-sqlpwrd

$KeyFile = "c:\temp\cleanS3.txt"
$Bucket  = "lcp2-sql-backups-us-east-1"

$FileContent = Get-Content -Path $KeyFile
$objs=@()
$k=0
foreach($line in $FileContent)
{
    $objs+=$line
    if ($objs.Length -eq 1000)
    {
        $k++
        Remove-S3Object -BucketName $Bucket -KeyCollection $objs -Force -AccessKey $AccessKey -SecretKey $SecretKey
        Write-Host ("Deleting "+$objs.Length.ToString()+" / "+($k*1000).ToString()) -BackgroundColor Cyan
        $objs.Clear()
        $objs=@()
    }

}

if ($objs.Length -gt 0)
{
    Remove-S3Object -BucketName $Bucket -KeyCollection $objs -Force -AccessKey $AccessKey -SecretKey $SecretKey
    Write-Host ("Deleting "+$objs.Length.ToString()) -BackgroundColor Cyan
    $objs.Clear()
    $objs=@()
}