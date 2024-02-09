$volRegion  = "us-east-1b"
if (!($Instance.InstanceId)) {
    write-host ("Instance "+$InstanceID+" not running") -ForegroundColor red -BackgroundColor Black
    exit
} else
{
    $BlockDeviceMappings = ($Instance.BlockDeviceMappings)
    foreach($BlockDevice in $BlockDeviceMappings) 
    {
        if (!($BlockDevice.Ebs.DeleteOnTermination) -and ($BlockDevice.Ebs.Status -eq "attached")) 
        {
            write-host ("Detaching/Dismounting volume Id "+$BlockDevice.Ebs.VolumeId.ToString()+" ...") -ForegroundColor Gray -BackgroundColor Black
            #Dismount-EC2Volume -VolumeId $BlockDevice.Ebs.VolumeId -InstanceId $InstanceID -Region $Region -force
            DO {
                Start-Sleep -Seconds 5 # time to dismount the volume
                $volume_state = (Get-EC2Volume -VolumeId $BlockDevice.Ebs.VolumeId).State
                write-host ("State of volume Id "+$BlockDevice.Ebs.VolumeId.ToString()+" = "+$volume_state) -ForegroundColor Cyan -BackgroundColor Black
            } while ($volume_state -ne "available")
            
            write-host ("Removing volume Id "+$BlockDevice.Ebs.VolumeId.ToString()+" ...") -ForegroundColor Gray -BackgroundColor Black
            #Remove-EC2Volume -VolumeId $BlockDevice.Ebs.VolumeId -Region $Region -force
            Start-Sleep -Seconds 5
            write-host ("Volume Id "+$BlockDevice.Ebs.VolumeId.ToString()+" removed.") -ForegroundColor Green -BackgroundColor Black
        }
        
    }
}