cls
$IP="10.232.200.230"
$a=$IP.Split(".")

Write-Output ($IP+" = IP-"+('{0:X2}' -f [int]$a[0])+('{0:X2}' -f [int]$a[1])+('{0:X2}' -f [int]$a[2])+('{0:X2}' -f [int]$a[3]))
