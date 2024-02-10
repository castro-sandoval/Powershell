$IP='10.232.26.101'
$rawIP=$IP.Split(".")
$hostID = (('{0:X2}' -f [int]$rawIP[0])+('{0:X2}' -f [int]$rawIP[1])+('{0:X2}' -f [int]$rawIP[2])+('{0:X2}' -f [int]$rawIP[3]))
$hostID
