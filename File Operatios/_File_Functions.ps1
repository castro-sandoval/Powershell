
$Testfile = "C:\Temp\tempdb_usage.tmp"

<#################################################################################################################
    If file exists, only change the file extention
#################################################################################################################>
Function ChangeFileExtention($FilePath, $NewExtention)
{ 
    If (Test-Path -Path $FilePath)
    {
        $file = Get-Item -Path $FilePath
        $NewName = ($file.DirectoryName+"\"+$file.Basename+"."+$NewExtention)
        if ($NewName -ne $FilePath)
        {
            Rename-Item -Path $FilePath -NewName $NewName
        }
        $file = Get-Item -Path $NewName
    }
    else
    {
        $file = ""
    }
    return $file
}

<#################################################################################################################
    If file exists, change the file BaneName and extention
#################################################################################################################>
Function RenameFile($FilePath, $NewName)
{ 
    If (Test-Path -Path $FilePath)
    {
        $file = Get-Item -Path $FilePath
        $NewName = ($file.DirectoryName+"\"+$Newname)
        if ($NewName -ne $FilePath)
        {
            Rename-Item -Path $FilePath -NewName $NewName
        }
        $file = Get-Item -Path $NewName
    }
    else
    {
        $file = ""
    }
    return $file
}

<#################################################################################################################
    If file exists, only change the file BaseName. Keep the same extension.
#################################################################################################################>
Function RenameFileBasename($FilePath, $NewBasename)
{ 
    If (Test-Path -Path $FilePath)
    {
        $file = Get-Item -Path $FilePath
        $NewName = ($file.DirectoryName+"\"+$NewBasename+"."+$file.Extension)
        if ($NewName -ne $FilePath)
        {
            Rename-Item -Path $FilePath -NewName $NewName
            $file = Get-Item -Path $NewName
            
        }
    }
    else
    {
        $file = ""
    }
    return $file
}




Clear-Host
Function Extract_dbname_FomFilename {
    param (
        [string] $Filename
    )
    $a = $Filename.ToCharArray()
    [array]::Reverse($a)
    $Filename = -join($a)
    $i = $Filename.IndexOf("_")
    $a = $Filename.SubString(4,$i-4).ToCharArray()
    [array]::Reverse($a)
    return -join($a)
}

$Filename = "FULL_20211022000501_msdb.bak"
$dbname = Extract_dbname_FomFilename -Filename $Filename
$dbname

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