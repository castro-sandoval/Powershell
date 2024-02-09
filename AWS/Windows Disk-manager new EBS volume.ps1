#Create the EBS Volume:

$volume = New-EC2Volume -Size $sizeInGB -AvailabilityZone $az -VolumeType $vType

#Attach the Volume to the EC2:
Add-EC2Volume -InstanceId $toInstanceId -VolumeId $volume.Id -Device $devId -Region $region

#Windows side:
#locate the ebs volume you just attached
$diskNumber = (Get-Disk | ? { 
    ($_.OperationalStatus -eq "Offline") -and ($_."PartitionStyle" -eq "RAW") }).Number

#initialize the disk
Initialize-Disk -Number $diskNumber -PartitionStyle GPT

#create max-space partition, assign drive letter, make "active"
$part = New-Partition -DiskNumber $diskNumber -UseMaximumSize -IsActive -AssignDriveLetter

#format the new drive
Format-Volume -DriveLetter $part.DriveLetter -Confirm:$FALSE