$all_Processes = gwmi win32_process -ComputerName . | select ProcessID,ParentProcessID,Description,@{l="Username";e={$_.getowner().user}} | where{$_.Username -like $env:username}
$all_processIDs = $all_Processes.Processid #ARRAY1
$parent_processIDs = $all_Processes.ParentProcessId #ARRAY2

# create a new Array for parents that are gone
$gone = New-Object System.Collections.ArrayList

# loop through all processes
$parent_processIDs | Sort-Object -Unique | ForEach-Object {
# find the ones where the current parent ID is not running
    if ($all_processIDs -notcontains $_)
    {
        $gone.Add($_) | Out-Null
    }
}
# now we have all parentIDs no longer running

# loop through all processes and find those in that list
$all_Processes | Where-Object {$gone -contains $_.ParentProcessId} | ForEach-Object {Get-NetTCPConnection -OwningProcess $_.ProcessID}