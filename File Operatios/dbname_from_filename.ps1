Function Extract_dbname_FomFilename {
    param (
        [string] $Filename
    )
    $a = $Filename.ToCharArray()
    [array]::Reverse($a)
    $Filename = -join($a)
    $i=$Filename.IndexOf("\")
    $k=$Filename.IndexOf(".")
    $a=$Filename.SubString($k+1,$i-$k-1).ToCharArray()
    [array]::Reverse($a)
    return -join($a)
}