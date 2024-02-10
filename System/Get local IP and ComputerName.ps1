Clear-Host
$ComputerName = (Get-ChildItem -path env:computername | select -Property Value -Verbose).Value

$IP = [System.net.dns]::GetHostEntry((Get-ChildItem -path env:computername | select -Property Value -Verbose).Value).AddressList | Where-Object {($_.IsIPv6LinkLocal -eq $false)} | %{$_.IPAddressToString} 


$ComputerName
$IP