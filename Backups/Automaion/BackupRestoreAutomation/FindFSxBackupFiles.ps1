Clear-Host


$servername = "IP-0AE8798D"
$dbname = "K2Logs"
$fromDevicePath = "\\amznfsxmd8zsrjo.scg.guru\share\"
$BackupPolicy_FSxFolder = "\\amznfsxmd8zsrjo.scg.guru\share\Backups\IP-0AE8798D"


<###########################################################################################################
Script body
###########################################################################################################>

$map_path = $BackupPolicy_FSxFolder
write-host ($BackupPolicy_FSxFolder) -ForegroundColor Yellow
$NewDrive=((68..90 | %{$L=[char]$_; if ((gdr).Name -notContains $L) {$L}})[0])
$drive=New-PSDrive -Name $NewDrive -PSProvider FileSystem -Root $map_path -Persist


$BackupTypes = @('FULL','DIFF','LOG')
$BackupFound = @(0,0,0)
$BackupTime = @($null,$null,$null)




$BT=0
$FSxFileFilter=$drive.Name+":\"+$BackupTypes[$BT]+"_*"+$dbname+".bak"
$FULL_backupFile =(Get-ChildItem -Path $FSxFileFilter | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | select Name).Name

if ($FULL_backupFile) {
write-host($FULL_backupFile) -ForegroundColor Green
} else {
write-host("Not found") -ForegroundColor red
}


$FULL_backupTimestamp = [datetime]::parseexact($FULL_backupFile.Split("_")[1], 'yyyyMMddHHmmss', $null)
$BackupFound[0]=1

write-host($FULL_backupFile) -ForegroundColor Green
write-host($FULL_backupTimestamp) -ForegroundColor Green

$BT=1
$FSxFileFilter=$drive.Name+":\"+$BackupTypes[$BT]+"_*"+$dbname+".bak"
$DIFF_backupFile =(Get-ChildItem -Path $FSxFileFilter | Where-Object {($_.LastWriteTime -gt $FULL_backupTimestamp)} | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | select Name).Name
$DIFF_backupTimestamp = [datetime]::parseexact($DIFF_backupFile.Split("_")[1], 'yyyyMMddHHmmss', $null)

write-host($DIFF_backupFile) -ForegroundColor cyan
write-host($DIFF_backupTimestamp) -ForegroundColor cyan


$BT=2
$FSxFileFilter=$drive.Name+":\"+$BackupTypes[$BT]+"_*"+$dbname+".bak"
$TRN_backupfiles = (Get-ChildItem -Path $FSxFileFilter | Where-Object {($_.LastWriteTime -gt $DIFF_backupTimestamp)} | Sort-Object LastWriteTime).Name
foreach($TRN_backupfile in $TRN_backupfiles) {
    write-host($TRN_backupfile) -ForegroundColor yellow
    $TRN_backupTimestamp = [datetime]::parseexact($TRN_backupfile.Split("_")[1], 'yyyyMMddHHmmss', $null)
    write-host($TRN_backupTimestamp) -ForegroundColor yellow

}



Remove-PSDrive -Name $NewDrive
