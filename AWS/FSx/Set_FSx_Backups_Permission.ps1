$FSx_endpoint = "\\amznfsx4gsbryes.llamadev.local\share\"
$FSx_Folder   = "Backups"
$Username     = "scg\svc_pipesqlagnt"
#===============================================
$map_drive_letter = ((68..90 | %{$L=[char]$_; if ((gdr).Name -notContains $L) {$L}})[0])
New-PSDrive -Name $map_drive_letter -PSProvider FileSystem -Root $FSx_endpoint -Persist
    
$Folder=$map_drive_letter+":\"+$FSx_Folder
if (!(Test-Path -Path $Folder))
{
    New-Item -Path $Folder -ItemType Directory
    $Acl = Get-Acl $Folder
    $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($Username, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $Acl.SetAccessRule($Ar)
    Set-Acl $Folder $Acl
}
Remove-PSDrive -Name $map_drive_letter
