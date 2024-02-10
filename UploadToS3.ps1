Import-Module -Name ("C:\Dataops\bin\DFTlibrary.dll")
$AccessKey = Get-awsaccessKey
$SecretKey = Get-awssecretkey
$sqllogin = Get-sqllogin
$sqlpwrd  = Get-sqlpwrd
Set-AWSCredential -AccessKey $AccessKey -SecretKey $SecretKey
#==========================================================================================================
$BucketName="lcp2-sql-backups-us-east-1"


$query = "select DevicePath+'Backups\' as [DevicePath]
            from [Backups].[Devices]
            where DevicePath in (
                SELECT distinct [FULL_backup_device_path] FROM [DATAOPS].[Targets].[BackupPolicy]
                union
                SELECT distinct [DIFF_backup_device_path] FROM [DATAOPS].[Targets].[BackupPolicy]
                union
                SELECT distinct [TRN_backup_device_path] FROM [DATAOPS].[Targets].[BackupPolicy]
                )"

$SourceDevices = Invoke-Sqlcmd -ServerInstance "." -Username $sqllogin -Password $sqlpwrd -Database "DATAOPS" -Query $query

foreach($Device in $SourceDevices)
{
    Write-Host ($Device.DevicePath) -BackgroundColor Cyan
    $Servers = Get-ChildItem -Name ($Device.DevicePath+"*") -Directory
    foreach($Server in $Servers)
    {
        $NamedInstance = Get-ChildItem -Name ($Device.DevicePath+$Server+"\*") -Directory
        if ($NamedInstance)
        {
            $Server+="\"+$NamedInstance
        }

        $ServerFiles = Get-ChildItem -Name ($Device.DevicePath+$Server+"\FULL_20211022*.BAK") -File -Recurse
        Write-Host ("Server "+$Server+" has "+$ServerFiles.Count.ToString()+" on "+$Device.DevicePath+$Server+"\FULL_20211022*.BAK")
    }
}

<#

#==========================================================================================================
$file=(Get-ChildItem -Path $filePath)
$key=$Prefix+$file.Name

Write-S3Object -BucketName $BucketName -Key $key -File $file.FullName


#>