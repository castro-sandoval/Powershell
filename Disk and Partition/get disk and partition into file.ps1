# Set output files
$DisksInfoFile   = "c:\DisksInfo.txt"
$VolumesInfoFile = "c:\VolumesInfo.txt"
# Check if output files exists and delete old ones
if (Test-Path -Path $DisksInfoFile)
{
    Remove-Item -Path $DisksInfoFile -Force
}
if (Test-Path -Path $VolumesInfoFile)
{
    Remove-Item -Path $VolumesInfoFile -Force
}
# Output information to output files
Get-Disk | Sort-Object -Property DiskNumber | Format-Table DiskNumber, @{n="SizeGB";e={[math]::Round($_.Size/1GB,0)}}, PartitionStyle, OperationalStatus, HealthStatus | out-file -FilePath $DisksInfoFile
Get-Volume | Sort-Object -Property DriveLetter | Format-Table DriveLetter, FileSystemLabel, @{n="SizeGB";e={[math]::Round($_.Size/1GB,0)}}, @{n="AllocationUnitSizeKB";e={[math]::Round($_.AllocationUnitSize/1KB,0)}} | out-file -FilePath $VolumesInfoFile



