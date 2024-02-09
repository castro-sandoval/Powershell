# List all available logs
$WMI = Get-WMIObject -ClassName 'Win32_NTEventlogfile'
$WMI |Format-Table -AutoSize

# This will return all log names to use with Get-WinEvent
====================================== Get-WinEvent =====================================================
$startLimit = [datetime]::parseexact('2019-11-01 00:00:00', 'yyyy-MM-dd HH:mm:ss', $null)

#Get-WinEvent -FilterHashtable @{ LogName="System"; StartTime=$startLimit } -MaxEvents 50 | Where-Object {($_.Category -ne "Backup") -and ($_.Message -like "*stop*")}
Get-WinEvent -FilterHashtable @{ LogName="Application"; StartTime=$startLimit; ProviderName="MSSQLSERVER" } -MaxEvents 50 | Where-Object {($_.Category -ne "Backup") -and ($_.Message -like "*stop*")}

====================================== Get-EventLog =====================================================

$dateLimit = [datetime]::parseexact('2018-11-14 00:00:06', 'yyyy-MM-dd HH:mm:ss', $null)
$Errors = (Get-EventLog -LogName Application -After $dateLimit -EntryType Error| where EventID -EQ 3041 | select -Property TimeGenerated, Source, Message) | Sort-Object TimeGenerated
if ($Errors.Length -gt 0) {
    Write-Host ($Errors.Length.ToString()+" erros found.")
    $i=0
    while ($i -lt $Errors.Length) {
        Write-Host ($Errors[$i].TimeGenerated.ToString("yyyy-MM-dd HH:mm:ss")+" "+$Errors[$i].Source+" "+$Errors[$i].Message.replace(". Check the backup application log for detailed messages.",""))
        $i++
    }
}

=========================================================================================================
