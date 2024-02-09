
<#****************************************************************************************************************************************************
Return the next available drive letter, between D and Z which does not exist or in use
Note: Net Object [Char] used to represent a Unicode character, 68..90 represented to letters D..Z. 
This converted Unicode characters and Get-PSDrive is compared using If statement and shows the next available drive letter
****************************************************************************************************************************************************#>

$map_path="\\192.168.0.27\home"
$NewDrive=((68..90 | %{$L=[char]$_; if ((gdr).Name -notContains $L) {$L}})[0])
New-PSDrive -Name $NewDrive -PSProvider FileSystem -Root $map_path -Persist

Remove-PSDrive -Name $NewDrive

Remove-PSDrive -Name "E"