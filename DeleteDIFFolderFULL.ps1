$LogFile = ($Args[0]+"BackupsClean_"+(Get-Date).ToString("yyyyMMddHHmmss")+".log")

Add-Content -Path $LogFile -Value ("----------------------------------------------------------------------------------------------------------------------------------------------")
$Bkups = Get-ChildItem -Path ($Args[0]+"DIFF*.bak") | Select -Property Name, LastWriteTime, Fullname
foreach($BkupFile in $Bkups) {
    $dbname = $BkupFile.Name.Substring(20,$BkupFile.Name.Length-20)
    $FULLfiles = Get-ChildItem -Path ($Args[0]+"FULL*"+$dbname) | Select -Property Name, LastWriteTime
    if ($FULLfiles) {
        foreach($FULLfile in $FULLfiles) {
            if ($FULLfile.LastWriteTime -ge $BkupFile.LastWriteTime) {
                Add-Content -Path $LogFile -Value ($BkupFile.Fullname+"  "+$BkupFile.LastWriteTime+" removed")
                Remove-Item -Path $BkupFile.FullName -Force
            }
        }
    } else {
        Add-Content -Path $LogFile -Value ($BkupFile.Fullname+"  "+$BkupFile.LastWriteTime+" removed (No full backup file related to this file was found)")
        Remove-Item -Path $BkupFile.FullName -Force
    }
}
