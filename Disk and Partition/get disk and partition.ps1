Import-Module -Name ("C:\Dataops\bin\DFTLibrary")

$AccessKey=Get-awsaccessKey
$SecretKey=Get-awssecretkey

$ip=get-WmiObject Win32_NetworkAdapterConfiguration|Where {$_.Ipaddress.length -gt 1} 
$ip = $ip.ipaddress[0]
$instance=(Get-EC2Instance -AccessKey $AccessKey -SecretKey $SecretKey -Region $region -Filter @{Name="network-interface.addresses.private-ip-address";Value=$ip}).Instances
Write-Host ($instance.InstanceId+"    "+$name+"    "+$IP+"  "+$instance.InstanceType.Value) -ForegroundColor Yellow

Write-Host ("getting disk details...") -ForegroundColor Green
# List the disks for NVMe volumes

function Get-EC2InstanceMetadata {
    param([string]$Path)
    (Invoke-WebRequest -Uri "http://169.254.169.254/latest/$Path").Content 
}

function GetEBSVolumeId {
    param($Path)
    $SerialNumber = (Get-Disk -Path $Path).SerialNumber
    if($SerialNumber -clike 'vol*'){
        $EbsVolumeId = $SerialNumber.Substring(0,20).Replace("vol","vol-")
    }
    else {
       $EbsVolumeId = $SerialNumber.Substring(0,20).Replace("AWS","AWS-")
    }
    return $EbsVolumeId
}

function GetDeviceName{
    param($EbsVolumeId)
    if($EbsVolumeId -clike 'vol*'){
    
        $Device  = ((Get-EC2Volume -VolumeId $EbsVolumeId ).Attachment).Device
        $VolumeName=""
    }
     else {
        $Device = "Ephemeral"
        $VolumeName = "Temporary Storage"
    }
    Return $Device,$VolumeName
}

function GetDriveLetter{
    param($Path)
    $DiskNumber =  (Get-Disk -Path $Path).Number
    if($DiskNumber -eq 0){
        $VirtualDevice = "root"
        $DriveLetter = "C"
        $PartitionNumber = (Get-Partition -DriveLetter C).PartitionNumber
    }
    else
    {
        $VirtualDevice = "N/A"
        $DriveLetter = (Get-Partition -DiskNumber $DiskNumber).DriveLetter
        if(!$DriveLetter)
        {
            $DriveLetter = ((Get-Partition -DiskId $Path).AccessPaths).Split(",")[0]
        } 
        $PartitionNumber = (Get-Partition -DiskId $Path).PartitionNumber   
    }
    
    return $DriveLetter,$VirtualDevice,$PartitionNumber

}

$Report = @()
foreach($Path in (Get-Disk).Path)
{
    $Disk_ID = ( Get-Partition -DiskId $Path).DiskId
    $Disk = ( Get-Disk -Path $Path).Number
    $EbsVolumeId  = GetEBSVolumeId($Path)
    $Size =(Get-Disk -Path $Path).Size
    $DriveLetter,$VirtualDevice, $Partition = (GetDriveLetter($Path))

    $Device,$VolumeName = GetDeviceName($EbsVolumeId)

    $Disk = New-Object PSObject -Property @{
      Disk          = $Disk
      Partitions    = $Partition
      DriveLetter   = $DriveLetter
      EbsVolumeId   = $EbsVolumeId 
      Device        = $Device 
      VirtualDevice = $VirtualDevice 
      VolumeName    = $VolumeName
      Iops          = (get-ec2volume -VolumeId $EbsVolumeId)[0].Iops
    }
	$Report += $Disk

} 


$Report | Sort-Object Disk | Format-Table -AutoSize -Property Disk, Partitions, DriveLetter, Iops, EbsVolumeId, Device, VirtualDevice, VolumeName

Get-Disk | Sort-Object -Property DiskNumber | Format-Table DiskNumber, @{n="SizeGB";e={[math]::Round($_.Size/1GB,0)}}, PartitionStyle, OperationalStatus, HealthStatus, LogicalSectorSize, PhysicalSectorSize, UniqueId
Get-Volume | Sort-Object -Property DriveLetter | Format-Table DriveLetter, FileSystemLabel, @{n="SizeGB";e={[math]::Round($_.Size/1GB,0)}}, @{n="AllocationUnitSizeKB";e={[math]::Round($_.AllocationUnitSize/1KB,0)}}

