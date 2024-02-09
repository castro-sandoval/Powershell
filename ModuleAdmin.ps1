

<#****************************************************************************
                        Constant definition
****************************************************************************#>
$BaseFolder   = "c:\temp\LLamaAdmin"

#----------------------------------------------------------------------------
$IncomeFolder = $BaseFolder+"\Income"
$LogFolder    = $BaseFolder+"\Log"

#----------------------------------------------------------------------------
$ServerName   = (Get-ChildItem -path env:computername | select -Property Value -Verbose).Value
$date = Get-date -Format "yyyyMMdd"
$IndexFile = $BaseFolder+"\IndexPage.html"

<#****************************************************************************
                    Check folder structure
****************************************************************************#>
if (!(Test-Path $BaseFolder)) {
    New-Item -ItemType Directory $BaseFolder
}
if (!(Test-Path $IncomeFolder)) {
    New-Item -ItemType Directory $IncomeFolder
}
if (!(Test-Path $LogFolder)) {
    New-Item -ItemType Directory $LogFolder
}


<#****************************************************************************
      Receive file from remote servers
****************************************************************************#>


$RemoteComputerName = "TKOPT-999999"


$OutputFile = ($IncomeFolder+"\Services_"+$date+"_"+$RemoteComputerName+".HTML")
#----  Generate the file remotely -----------
Get-Service | Select -Property Name | ConvertTo-Html | Out-File $OutputFile



#----  Copy the file from remote server to this server Income folder -----------
Copy-Item -Path ??? -Destination $IncomeFolder




<#****************************************************************************
      Create exibition UI for the pages
****************************************************************************#>
if (Test-Path -Path $IndexFile) {
    Remove-Item -Path $IndexFile -Force
}

Add-Content -Path $IndexFile -Value "<!DOCTYPE html PUBLIC ""-//W3C//DTD XHTML 1.0 Strict//EN""  ""http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"">" -Encoding Unicode
Add-Content -Path $IndexFile -Value "<html xmlns=""http://www.w3.org/1999/xhtml"">" -Encoding Unicode
Add-Content -Path $IndexFile -Value "<head>" -Encoding Unicode
Add-Content -Path $IndexFile -Value "<title>LLamaAdmin</title>" -Encoding Unicode
Add-Content -Path $IndexFile -Value "</head><body>" -Encoding Unicode

$Files = (Get-Item -Path ($IncomeFolder+"\*.html"))

Add-Content -Path $IndexFile -Value ("<P>"+$Files.Count.ToString()+ " files found.") -Encoding Unicode

foreach ($file in $Files) {
    $NewLink = "<P><a href="""+ $file.FullName  +""">"+$file.Name+"</a>" 
    Add-Content -Path $IndexFile -Value $NewLink -Encoding Unicode
}

Add-Content -Path $IndexFile -Value "</body></html>" -Encoding Unicode