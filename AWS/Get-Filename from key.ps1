clear-host
function Get-FilenameFromKey
{
    param ([string] $key, [boolean]$IncludeTimestamp)
    
    $a = $key.ToCharArray()
    [array]::Reverse($a)
    $a = ($a -join '')
    if ($IncludeTimestamp)
    {
        $a = $a.Substring(0,$a.IndexOf("/"))
    }
    else
    {
        $a = $a.Substring(0,$a.IndexOf("/")-20)
    }
    $filename = $a.ToCharArray()
    [array]::Reverse($filename)
    $filename = ($filename -join '')
    return $filename
}


$mykey = "IP-0AE87D14/PLATFORM/Backups/Week_20200525/FULL_20200531051017_MasterQueue_24631.bak"
Get-FilenameFromKey -key $mykey -IncludeTimestamp $True
Get-FilenameFromKey -key $mykey -IncludeTimestamp $False


