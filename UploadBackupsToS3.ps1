Param ([string]$BackupDevice, $InstanceName)


if ((!($BackupDevice)) -or (!($InstanceName)))
{
    exit
}


$BucketName="lcp2-sql-backups-us-east-1"

#*********************************************************
function LastMondayyyyyMMdd {
    if ((Get-date).DayOfWeek.value__ -gt 0)
    {
        $ThisWeekMonday = (Get-date).AddDays(1- (Get-date).DayOfWeek.value__)
    } else {
        $ThisWeekMonday = (Get-date).AddDays(-6)
    }
    return $ThisWeekMonday.ToString("yyyyMMdd")   
}

#*********************************************************

function Delete-Week-DIFF
{
  param
  (
    [string] $prefix
  )

    $keysToDelete = @((Get-S3Object -BucketName $BucketName -KeyPrefix $prefix | Where-Object {$_.key -like "*DIFF*"}).key)
    $returnValue = $keysToDelete.Count
    if ($returnValue -gt 0) 
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
            Remove-S3Object -BucketName $BucketName -KeyCollection $subset -force | Out-Null    
            $init+=$Subset_size
        }
        $keysToDelete = @((get-s3object -BucketName $BucketName -KeyPrefix $prefix | Where-Object {$_.key -like "*DIFF*"}).key)
        if ($keysToDelete) {
            Remove-S3Object -BucketName $BucketName -KeyCollection $keysToDelete -force | Out-Null
        }
        $keysToDelete=@()
        $subset = @()
    }
    return $returnValue 
}

#******************** Copy new backups to S3 ***************************
#************* Create a folder in a S3 buket ********************************************
$LogFileName     = "AWS_UploadToS3_"+(Get-Date).ToString("yyyyMMdd_HHmm")+".log"
$LogFileFullName = $BackupDevice+$LogFileName

$InstanceName=$InstanceName.Replace("\","/")
$keyPrefix = "/"+$InstanceName+"/Backups/Week_"+(LastMondayyyyyMMdd)

#=========================================================================================================================================================================
if ((Get-Date).DayOfWeek.value__ -eq 1) {
    Add-Content -Path $LogFileFullName -Value ("==============================================================================")
    Add-Content -Path $LogFileFullName -Value ("It's a Monday. Clean DIFF files from "+$keyPrefix+" before uploading FULL backups")
    $keysToDelete = Delete-Week-DIFF -prefix $keyPrefix
    Add-Content -Path $LogFileFullName -Value ($keysToDelete.ToString()+ " files removed from "+$keyPrefix)
    Add-Content -Path $LogFileFullName -Value ("==============================================================================")
}

#=========================================================================================================================================================================
$filesToCopy = (Get-ChildItem -Path ($BackupDevice+"*.bak") -Include DIFF*.bak, FULL*.bak -Exclude LOG_*.bak)

Add-Content -Path $LogFileFullName -Value ($filesToCopy.Count.ToString()+" files to upload to S3 bucket.")
foreach ($file in $filesToCopy)
{
   
    $filekey = ($keyPrefix.Substring(1,$keyPrefix.Length-1)+"/"+$file.Name)

    #Check if file is already there before copying
    if ((Get-S3Object -BucketName $BucketName -KeyPrefix $keyPrefix | Where-Object {$_.key -eq $filekey }) ) {
        Add-Content -Path $LogFileFullName -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" File already exists in S3 "+$keyPrefix+": "+$file.FullName+" "+$file.CreationTime.ToString("yyyy-MM-dd HH:mm"))
    } else {
        Add-Content -Path $LogFileFullName -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" Uploading "+$file.FullName+"  TO  "+$keyPrefix+"/"+$file.Name+"  -> File creation: "+$file.CreationTime.ToString("yyyy-MM-dd HH:mm"))
        Write-S3Object -BucketName ($BucketName+$keyPrefix) -Key $file.Name -File $file.FullName
    }
}

Write-S3Object -BucketName ("$BucketName/"+$InstanceName.Replace("\","/")+"/Logs") -Key $LogFileName -File $LogFileFullName
Add-Content -Path $LogFileFullName -Value ("=========================================================================================================================================================================")
Add-Content -Path $LogFileFullName -Value ((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")+" Finished")
Add-Content -Path $LogFileFullName -Value ("=========================================================================================================================================================================")
Add-Content -Path $LogFileFullName -Value ("")