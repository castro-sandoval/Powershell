Clear-Host
$disks = (Get-Disk | Select-Object -Property DiskNumber, PartitionStyle, OperationalStatus, HealthStatus, AllocatedSize, LogicalSectorSize, PhysicalSectorSize, NumberOfPartitions)

foreach($disk in $disks)
{
    Write-Host ("Disk "+$disk.DiskNumber.ToString()+" / Partitions: "+$disk.NumberOfPartitions+" - "+$disk.PartitionStyle+" - "+$disk.OperationalStatus+" - "+$disk.HealthStatus+" - AllocatedSize: "+[Math]::Round(($disk.AllocatedSize/1GB),0)+"GB - PhysicalSectorSize: "+$disk.PhysicalSectorSize) -BackgroundColor Yellow -ForegroundColor Black

    $Partitions= (Get-Partition | Where-Object {($_.Type -ne "Reserved") -and ($_.DiskNumber -eq $disk.DiskNumber)} | Select-Object -Property Type, DriveLetter, PartitionNumber, Size, AccessPaths)
    foreach($Partition in $Partitions)
    {
        Write-Host ("Partition Number: "+$Partition.PartitionNumber.ToString()+" - Type: "+ $Partition.Type+" / DriveLetter: "+$Partition.DriveLetter+" / Size: "+[Math]::Round(($Partition.Size/1GB),0)+"GB") -BackgroundColor Cyan -ForegroundColor Black

        $Volumes = (Get-Volume | Where-Object {($_.DriveLetter -eq $Partition.DriveLetter) -and ($_.Path -iin $Partition.AccessPaths)} | Select-Object -Property DriveLetter, DriveType, OperationalStatus, HealthStatus, AllocationUnitSize, FileSystem, FileSystemLabel, Path)
        foreach ($Volume in $Volumes)
        {
            if (($Partition.Type -ne "IFS") -and ($Volume.AllocationUnitSize/1KB -ne 64))
            {
                Write-Host ("AllocationUnitSize not 64KB.") -ForegroundColor Red -BackgroundColor White
            }
            $Volume
        }
    }
}
