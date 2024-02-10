<#

.SYNOPSIS 
    
    The script would check the servers for memory including physical and virtual 
    and proviude the report of the current usage in HTML formatted output

 .DESCRIPTION 
 
The script would check the servers for memory including physical and virtual and provide the report of
the current configuration and usage in HTML formatted output file. It would be very helpful when you need
to check the server performance, it also provide the last reboot time details to make the decession
whehter its need a reboot as part of troubleshooting

 

The server list which needs to be checked should be there in the path c:\temp\servers.txt,
or you can edit the script to modify the location.

############################################################################### 

    

 .NOTES 
    Author  : Kamaraj Ulaganathan
    Email: kamaraj0926@outlook.com 
    Website: www.msexchangescripts.com
    Requires: PowerShell Version 2.0

    #> 




$Header = @"
<style>
TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH {border-width: 2px;padding: 3px;border-style: solid;border-color: black;background-color: #6495ED;}
TD {border-width: 2px;padding: 3px;border-style: solid;border-color: black;}
.odd  { background-color:#ffffff;}
.even { background-color:#dddddd;}
</style>
<title> Title of my Report 
</title>
"@

$b = Get-Date -format f
$Pre = $b


$TotVirtMemory = @{Name="Total Virtual Memory(GB)";expression={[math]::round(($_.TotalVirtualMemorySize / 1047553),3)}}

$TotVisMemory = @{Name="Total Physical Memory (GB)";expression={[math]::round(($_.TotalVisibleMemorySize / 1047553),3)}}

$SizeStoredInPagingFiles = @{Name="SizeStoredInPagingFiles(GB)";expression={[math]::round(($_.SizeStoredInPagingFiles / 1047553),3)}}

$FreeRAM = @{Name="FreeRAM(GB)";expression={[math]::round(($_.FreePhysicalMemory / 1047553),3)}}

$FreeSPinPagingFiles = @{Name="FreeSPaceinPaging Files(GB)";expression={[math]::round(($_.FreeSpaceInPagingFiles / 1047553),3)}}

$FreeVirtMemory = @{Name="FreeVirtMemory(GB)";expression={[math]::round(($_.FreeVirtualMemory / 1047553),3)}}

$uptime = @{Name="Last Reboot";expression={$_.ConvertToDateTime($_.LastBootUpTime)}}

$server = @{Name="Server";expression={$_.csname}}



$commitbytesinperc = @{name = "% CommitedBytes in use";expression={[math]::round(([math]::round((($_.TotalVirtualMemorySize - $_.FreeVirtualMemory)/ 1047553),3)/([math]::round(($_.TotalVirtualMemorySize / 1047553),3))*100),3)}}

$output = Get-Content C:\temp\servers.txt| foreach-object {Get-WmiObject -Class Win32_OperatingSystem -Computer $_ | select $server,$TotVirtMemory,$TotVisMemory,$SizeStoredInPagingFiles,$FreeRAM,$FreeSPinPagingFiles,$FreeVirtMemory,$commitbytesinperc,$uptime}

$output | ConvertTo-HTML -Head $header -PreContent "<h3><b><font color=Black>$pre</b></font> <br></h3>" -body "<b><font color=Black>=========         Memory Usage Report            =========</b></font> <br> " | Out-File "c:\temp\memusage.htm"

Invoke-Expression "c:\temp\memusage.htm"
