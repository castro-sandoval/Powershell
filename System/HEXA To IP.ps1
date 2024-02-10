cls
$HEXA="0AE8C8E6"

$HX = @(("0x000000"+($HEXA).Substring(0,2)), 
        ("0x000000"+($HEXA).Substring(2,2)),
        ("0x000000"+($HEXA).Substring(4,2)),
        ("0x000000"+($HEXA).Substring(6,2))
        )

Write-Output ($HEXA+" = IP "+([uint32]$HX[0]).ToString()+"."+([uint32]$HX[1]).ToString()+"."+([uint32]$HX[2]).ToString()+"."+([uint32]$HX[3]).ToString())