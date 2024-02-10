cls

$Processes = Get-Process | select -Property Name, Id | Where-Object {$_.Name -eq "agent"}

foreach($process in $Processes) {
    $NetDetails = Get-NetTCPConnection | Where-Object {($_.OwningProcess -eq $process.Id) -and ($_.LocalAddress -contains "127.0.0.1")}
    $PortCount = ($NetDetails.LocalPort).count
    if ($PortCount -gt 0) {
        Write-Host $process.Name
        $p=0
        while ($p -lt $PortCount) {
            if ($p -eq 0) {
                Write-Host ($NetDetails.LocalAddress[$p]+","+$NetDetails.LocalPort[$p])
            } else {
                if (($NetDetails.LocalAddress[$p] -ne $NetDetails.LocalAddress[$p-1]) -or ($NetDetails.LocalPort[$p] -ne $NetDetails.LocalPort[$p-1])) {
                    Write-Host ($NetDetails.LocalAddress[$p]+","+$NetDetails.LocalPort[$p])
                }
            }
            $p++
        }
        Write-Host "======================================================================================================"
    }
}
