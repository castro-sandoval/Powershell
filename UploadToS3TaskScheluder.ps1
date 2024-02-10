Param ([string]$BackupDevice, $InstanceName, $user, $secret)

$ps1File = $BackupDevice+"UploadBackupsToS3.ps1"
$Taskname = "UploadBackupsToS3"
$LogFile  = $BackupDevice+"UploadToS3TaskScheluder_"+(Get-date).ToString("yyyyMMddHHmmss")+".log"

Add-Content -Path $LogFile -Value ((Get-date).ToString("yyyy-MM-dd HH:mm:ss")+" - Starting UploadToS3TaskScheluder.ps1")

<#**************************************************************************************************************************************
                                            FUNCTIONS
**************************************************************************************************************************************#>

function taskExists
{
  param ( [string]$pTaskName)
   $schedule = new-object -com Schedule.Service 
   $schedule.connect() 
   $tasks = $schedule.getfolder("\").gettasks(0)
   $exists = $false
   foreach ($task in ($tasks | select Name)) {
      if($($task.name) -eq $pTaskName) {
         $exists = $true
         break
      }
   }
   return $exists
}

function createTask 
{
  param
  (
    [string] $Fullfilename,
    [string] $BackupDevice, 
    [string] $InstanceName,
    [string] $pUser,
    [string] $pPassword
  )
    $Argument = '-f "'+$Fullfilename+'" -BackupDevice '+$BackupDevice+' -InstanceName '+$InstanceName
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument $Argument

    Add-Content -Path $LogFile -Value ((Get-date).ToString("yyyy-MM-dd HH:mm:ss")+" - Action (PowerShell.exe -Argument "+$Argument+")     -TaskName "+$Taskname+' -Description "Upload local BAK to S3"')
    Register-ScheduledTask -Action $action -TaskName $Taskname -Description "Upload local BAK to S3" -User $pUser -Password $pPassword -AsJob
}

function IsRunning
{
  param ( [string]$pTaskName)
    $is_running=$false
    if (taskExists -pTaskName $pTaskName)
    {
        if (Get-ScheduledTask -TaskPath "\" -TaskName $pTaskName | ? state -eq "Running")
        {
            $is_running=$true
        }
        else
        {
            $is_running=$false
        }
    }
    return $is_running

}

function runTaskOnce
{
    param ( [string]$pTaskName,
            [string] $pStartAt,
            [string] $pUser,
            [string] $pPassword)
    # create new or reset the schedule to ...
    $Time = New-ScheduledTaskTrigger -At $pStartAt -Once
    Set-ScheduledTask -TaskName $pTaskName -Trigger $Time -User $pUser -Password $pPassword 
}

<#**************************************************************************************************************************************
                                            SCRIPT BODY
**************************************************************************************************************************************#>

if (taskExists -pTaskName $Taskname)
{
    Add-Content -Path $LogFile -Value ((Get-date).ToString("yyyy-MM-dd HH:mm:ss")+" - taskExists -pTaskName "+$Taskname)
}
else
{
    Add-Content -Path $LogFile -Value ((Get-date).ToString("yyyy-MM-dd HH:mm:ss")+" - createTask -Fullfilename "+$ps1File+" -BackupDevice "+$BackupDevice+" -InstanceName "+$InstanceName+"  -pUser "+$user+" -pPassword *****************" )
    createTask -Fullfilename $ps1File -BackupDevice $BackupDevice -InstanceName $InstanceName -pUser $user -pPassword $secret | Out-Null
}


if (IsRunning -pTaskName $Taskname)
{
    Add-Content -Path $LogFile -Value ((Get-date).ToString("yyyy-MM-dd HH:mm:ss")+" - "+$Taskname+" is already running. Not starting...")
}
else
{
    $StartAt = ((Get-Date).AddMinutes(2)).ToString( [cultureinfo]::CurrentCulture.DateTimeFormat.ShortTimePattern)
    Add-Content -Path $LogFile -Value ((Get-date).ToString("yyyy-MM-dd HH:mm:ss")+" - Starting "+$Taskname+" at "+$StartAt)
    runTaskOnce -pTaskName $Taskname -pStartAt $StartAt -pUser $user -pPassword $secret 
}
