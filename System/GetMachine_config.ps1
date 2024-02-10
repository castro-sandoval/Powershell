
Set-AWSCredentials -AccessKey  -SecretKey 
Clear-Host
$instanceId = Invoke-WebRequest -Uri http://169.254.169.254/latest/meta-data/instance-id
$instanceType = (Get-EC2InstanceAttribute -InstanceId $instanceId -Attribute instanceType).InstanceType
$Instance = (Get-EC2Instance -InstanceId $instanceId).instances 


$ip=$instance.NetworkInterfaces[0].PrivateIpAddress
$name = ($instance.tag | Where-Object {$_.key -eq "Name"}).Value




$OutputFile="C:\temp\"+$ip.Replace(".","-")+" "+(Get-ComputerInfo -Property "CsName").CsName+".txt"

if (!(Test-Path -Path "c:\temp")) {
    New-Item -Path "c:\temp" -ItemType Directory -Force
}


if (Test-Path -Path $OutputFile) {
    Remove-Item -Path $OutputFile -Force
}
Add-Content -Path $OutputFile -Value ('SysInfo updated '+(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))



Add-Content -Path $OutputFile -Value ("AWS Name tag: "+$name+" (IP: "+$ip+")")
Add-Content -Path $OutputFile -Value ("InstanceId: "+$instanceId.Content+" (Type: "+$instanceType+")")

$SysInfo = Get-ComputerInfo -Property "CsName","TimeZone","WindowsProductName","OsType","OsVersion","WindowsEditionId","OsTotalVisibleMemorySize","OsFreePhysicalMemory","CsNumberOfLogicalProcessors","CsNumberOfProcessors","CsProcessors"

Add-Content -Path $OutputFile -Value ("Host name: "+$Info[0].CsName)
Add-Content -Path $OutputFile -Value ("TimeZone: "+$Info[0].TimeZone)
Add-Content -Path $OutputFile -Value ($Info[0].WindowsProductName+" ("+$Info[0].OsType+" "+$Info[0].OsVersion+" "+$Info[0].WindowsEditionId+" edition)")
Add-Content -Path $OutputFile -Value ("OsTotalVisibleMemorySize "+$Info[0].OsTotalVisibleMemorySize.ToString())
Add-Content -Path $OutputFile -Value ("FreePhysicalMemory "+$Info[0].OsFreePhysicalMemory.ToString())
Add-Content -Path $OutputFile -Value ($Info[0].CsNumberOfProcessors.ToString()+" x "+$Info[0].CsProcessors[0].Description+" processor(s)")
Add-Content -Path $OutputFile -Value ($Info[0].CsNumberOfLogicalProcessors.ToString()+" Logical Processors")

Add-Content -Path $OutputFile -Value ""
Add-Content -Path $OutputFile -Value "Hotfixes/Patches"
$HotFixes = Get-HotFix | Select -Property "HotFixID","Caption","InstalledOn" | Sort-Object -Property "InstalledOn"
foreach($HotFix in $HotFixes) {
    Add-Content -Path $OutputFile -Value ($HotFix[0].InstalledOn.ToString("yyyy-MM-dd")+" : HotFixID: "+$HotFix[0].HotFixID+" ("+$HotFix[0].caption+")")
}

