
$KeyToDownLoad = "I-077A5742A8C36/Backups/Week_20210510/FULL_20210510060000_3c441376-a132-44ae-9e16-84802c19b968.bak"


Function ExtractFilenameFromS3Key {
    param (
        [string] $S3key
    )
    $a = $S3key.ToCharArray()
    [array]::Reverse($a)
    $Filename = -join($a)
    $Filename=$Filename.Split("/")[0]
    $a = $Filename.ToCharArray()
    [array]::Reverse($a)
    $Filename = -join($a)

    return $Filename
}

Clear-Host
ExtractFilenameFromS3Key -S3key $KeyToDownLoad