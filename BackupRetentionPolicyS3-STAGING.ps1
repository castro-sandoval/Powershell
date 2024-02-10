Import-Module -Name ("C:\Dataops\bin\DFTlibrary.dll")
$AccessKey  = Get-awsaccessKey
$SecretKey  = Get-awssecretkey
$sqllogin   = Get-sqllogin
$sqlpwrd    = Get-sqlpwrd

$Env        = "STAGING"

$PolicyPerServer = "select [tag_name], [S3_Bucket], [Server_name], [retentionDays_S3] "
$PolicyPerServer+= "from [Targets].[BackupPolicy] where [Policy_active]=1 and [location]='"+$Env+"'"

Clear-Host
<#************************************************************************************************************************
 1) Retrieve each server policy
 2) Check S3 for files older than retentionDays_S3
************************************************************************************************************************#>

$Policies = (Invoke-Sqlcmd -ServerInstance "." -Username $sqllogin -Password $sqlpwrd -Database "DATAOPS" -Query $PolicyPerServer)
foreach($ServerPolicy in $Policies)
{
    $BucketName = $ServerPolicy.S3_Bucket
    $prefix     = "/"+$ServerPolicy.Server_name
    $Cuttoff    = (Get-Date).AddDays(-$ServerPolicy.retentionDays_S3)

    $keysToDelete = @((Get-S3Object -BucketName $BucketName -KeyPrefix $prefix -AccessKey $AccessKey -SecretKey $SecretKey | Where-Object {$_.LastModified -lt $Cuttoff}).key)

    Write-Host ($ServerPolicy.tag_name+" -> "+ $keysToDelete.Count.ToString()+" keys to delete older than "+$Cuttoff.ToString("yyyy-MM-dd HH:mm:ss") )

    if ($keysToDelete.Count -gt 0) 
    {
        if ($keysToDelete.Count -gt 1000) {
            $Subset_size = 1000
        } else {
            $Subset_size=$keysToDelete.Count
        }
        $init = 0
        while(($init+$Subset_size) -lt $keysToDelete.Count) {
            $subset = @()
            for($i=$init;$i -lt ($init+$Subset_size) ;$i++) {
                $subset+=$keysToDelete[$i]
            }
            Remove-S3Object -BucketName $BucketName -KeyCollection $subset -force -AccessKey $AccessKey -SecretKey $SecretKey | Out-Null    
            $init+=$Subset_size
        }

        $keysToDelete = @((Get-S3Object -BucketName $BucketName -KeyPrefix $prefix -AccessKey $AccessKey -SecretKey $SecretKey | Where-Object {$_.LastModified -lt $Cuttoff}).key)
        if ($keysToDelete) {
            Remove-S3Object -BucketName $BucketName -KeyCollection $keysToDelete -force -AccessKey $AccessKey -SecretKey $SecretKey | Out-Null
        }
        $keysToDelete=@()
        $subset = @()
    }

}


