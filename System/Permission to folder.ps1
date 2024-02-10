$Folder   = "C:\Dataops"
$Username = 'LLAMADEV\sandoval.castroneto'
$Acl = Get-Acl $Folder
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($Username, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$Acl.SetAccessRule($Ar)
Set-Acl $Folder $Acl






#=========================================================================
$Folder   = "C:\Databases\Backup"
$Username = 'NT Service\MSSQL$MSSQLSERVER2014'
$Acl = Get-Acl $Folder
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($Username, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$Acl.SetAccessRule($Ar)
Set-Acl $Folder $Acl


#=========================================================================

$path = "C:\Databases" #Replace with whatever file you want to do this to.
$user = 'NT Service\MSSQL$MSSQLSERVER2014' #User account to grant permisions too.
$Rights = "FullControl" #Comma seperated list.
$InheritSettings = "Containerinherit, ObjectInherit" #Controls how permissions are inherited by children
$PropogationSettings = "None" #Usually set to none but can setup rules that only apply to children.
$RuleType = "Allow" #Allow or Deny.


$acl = Get-Acl $path
$perm = $user, $Rights, $InheritSettings, $PropogationSettings, $RuleType
$rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $perm
$acl.SetAccessRule($rule)
$acl | Set-Acl -Path $path

*********************************************************************************************************

$path = 'C:\Test'
$acl = Get-Acl -Path $path
$accessrule = New-Object System.Security.AccessControl.FileSystemAccessRule ('SYSTEM', 'FullControl', 'ContainerInherit, ObjectInherit', 'InheritOnly', 'Allow')
$acl.SetAccessRule($accessrule)
Set-Acl -Path $path -AclObject $acl