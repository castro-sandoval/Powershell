Clear-Host


$host_name = (Get-ChildItem -path env:computername | select -Property Value -Verbose).Value
$SQLservices = (Get-Service | Where-Object {($_.BinaryPathName -like "*sqlservr.exe*" )}) | Select-Object -Property ServiceName, Status
foreach($SQLService in $SQLServices)
{    
    if ($SQLService.Status -eq "Running")
    {
        if ($SQLService.ServiceName.IndexOf("$") -eq -1)
        {
            $instanceName = $host_name
        }
        else
        {
            $instanceName = $host_name+"\"+$SQLService.ServiceName.Substring($SQLService.ServiceName.IndexOf("$")+1, $SQLService.ServiceName.Length-$SQLService.ServiceName.IndexOf("$")-1)
        }
        Write-Host ($SQLService.ServiceName+" -> "+$instanceName+" ("+$SQLService.Status+")") -ForegroundColor Green
    }
    else
    {
        Write-Host ($SQLService.ServiceName+" "+$SQLService.Status) -ForegroundColor Red
    }
}

