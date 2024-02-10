Clear-Host
$binFolder = "C:\Dataops\bin"
Import-Module -Name ($binFolder+"\DFTlibrary.dll")
$AccessKey = Get-awsaccessKey
$SecretKey = Get-awssecretkey
$sqllogin = Get-sqllogin
$sqlpwrd  = Get-sqlpwrd

$KeyFile = "c:\temp\cleanS3.txt"
$Bucket  = "lcp2-sql-backups-us-east-1"
$BAKTypes = @("LOG","DIFF","FULL")

$Folder = "IP-0AE87D14"

#============================================================

function SelectFiles 
{
   param
  (
    [string] $Prefix
  )

    if (Test-Path -Path $KeyFile)
    {
        Remove-Item -Path $KeyFile -Force
    }
    $files = Get-S3Object -BucketName $Bucket -MaxKey 30000 -KeyPrefix $Prefix -AccessKey $AccessKey -SecretKey $SecretKey #| Where-Object {(($_.Key).Substring(1,5) -eq "DIFF_")}
    foreach($file in $files) {
        Add-Content -Path $KeyFile -Value ($file.key)
    }
    Write-Host ("SelectFiles = "+$files.Count.ToString()+" files.") -ForegroundColor Yellow
    return $files.Count
}

function DeleteFiles
{
    $FileContent = Get-Content -Path $KeyFile
    $objs=@()
    $k=0
    foreach($line in $FileContent)
    {
        $objs+=$line
        if ($objs.Length -eq 1000)
        {
            $k++
            Remove-S3Object -BucketName $Bucket -KeyCollection $objs -Force -AccessKey $AccessKey -SecretKey $SecretKey | Out-Null
            Write-Host ("Deleting "+$objs.Length.ToString()+" / "+($k*1000).ToString()) -BackgroundColor Cyan
            $objs.Clear()
            $objs=@()
        }

    }

    if ($objs.Length -gt 0)
    {
        Remove-S3Object -BucketName $Bucket -KeyCollection $objs -Force -AccessKey $AccessKey -SecretKey $SecretKey | Out-Null
        Write-Host ("Deleting "+$objs.Length.ToString()) -BackgroundColor Cyan
        $objs.Clear()
        $objs=@()
    }
}

#==================================================================================================================================

    $FileCount=1
    while ($FileCount -gt 0)
    {
        Write-Host ("Searching "+($Folder)) -ForegroundColor Green
        $FileCount = (SelectFiles -Prefix $Folder)

        if ($FileCount -gt 0)
        {
            Write-Host ("Deleting "+ $FileCount.ToString()+" files from "+$Folder)
            DeleteFiles
            Write-Host ("Delete completed.")
        }
    } 
