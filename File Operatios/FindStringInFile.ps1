<#**************************************************************************************************************************************
This script drilldown through a folter structure from a RootFolder, find all files and for each file that contais a string StrToFind


Select-String -Path .\*.txt -Pattern 'stringToFind'

**************************************************************************************************************************************#>

$RootFolder  = 'C:\Users\sandoval.castroneto\Documents\PowerShell\'
$LogFile     = 'C:\Temp\FindStringInFile.log'

$exclusions  = @("*.dll","*.exe","*.pdb","*.lic","*.zip")   # Exclusion list for file search -> file will be ignored

$CheckOnlyExtensions = ".ps1"

$StrToFind   = 'filter'
$Str2ToFind   = ''

$LogFolders = $False

<#************************************************************************************************************************************#>
function FormatDatetime {
    param( [String]$dt )
    return ($dt.SubString(6,2)+"/"+$dt.SubString(4,2)+"/"+$dt.SubString(0,4)+" "+$dt.SubString(8,2)+":"+$dt.SubString(10,2)+":"+$dt.SubString(12,2)+"   (dd/mm/yyyy hh:nn:ss)")
}
<#****************************************************************************************************************************************#>
$FoundInFiles = @()

cls
if (Test-Path $LogFile) {
    Remove-Item -Path $LogFile
}

$LogMessage = ("Search string: "+$StrToFind+"   from  "+$RootFolder)
Write-Host $LogMessage
Add-Content -Path $LogFile -Value ("Log for Search for string in file - Created: "+(FormatDatetime (Get-Date -Format yyyMMddHmmss) ))
Add-Content -Path $LogFile -Value $LogMessage


$LogMessage = '-'*100
Add-Content -Path $LogFile -Value $LogMessage

$ScriptStartDate=(GET-DATE)

$LogMessage = "Searching for '"+$StrToFind
Add-Content -Path $LogFile -Value $LogMessage


$LogMessage = '-'*100
Add-Content -Path $LogFile -Value $LogMessage


#========== Collect folder structure =============
$Folders = @()
$Folders += $RootFolder

Write-Host ("Reading folders under "+$RootFolder)

foreach($Folder in Get-ChildItem -Path $RootFolder -Directory -Recurse) {
    $Folders += ($Folder.FullName.ToString())
}


#========= Go through each folder ================
$Count_TotalFolders=1
foreach ($Folder in $Folders) 
{
    if ($CheckOnlyExtensions -eq "") {
        $Files = (Get-ChildItem -Path $Folder -Exclude $exclusions | Where-Object {(!$_.PSIsContainer)})
    } else {
        $Files = (Get-ChildItem -Path $Folder -Exclude $exclusions | Where-Object {((!$_.PSIsContainer) -and ($_.Extension -eq $CheckOnlyExtensions))})
    }


    if ($Files.Length -gt 0) 
    {
        if ($LogFolders -eq $True) {
            $LogMessage = ($Files.Count.ToString() +" files found on "+$Folder+" folder.  (excluding "+$exclusions+")"  )
            Add-Content -Path $LogFile -Value $LogMessage
        }

        foreach($File in $Files)
        {
            $Count_Files+=1

            if ($Files.Length -gt 0 -and $LogFolders -eq $True) {
                $LogMessage = ("      Analysing "+$File.FullName)
                Add-Content -Path $LogFile -Value $LogMessage
            }

            $StrFound=0
            $FileContent = Get-Content -Path $File.FullName

            $LineNumber = 1
            $StringInLines = ""
            foreach($line in $FileContent)
            {
            
                if(($line.IndexOf($StrToFind) -ge 0) -and (($line.IndexOf($Str2ToFind) -ge 0) -OR ($Str2ToFind -eq ""))) {
                    $StrFound = $StrFound + 1
                    $StringInLines += ($LineNumber.ToString()+" ")
                }
                $LineNumber+=1
            }
            if ($StrFound -gt 0) 
            {
                $FoundInFiles += ($File.FullName+" lines "+$StringInLines)
                
                if ($LogFolders -eq $True) {
                    $LogMessage = ("               "+$StrFound.ToString()+" occurance found in file "+$File.FullName+" lines "+$StringInLines)
                    Add-Content -Path $LogFile -Value $LogMessage
                }
            }

        } # foreach($File in $Files)
    } # if ($Files.Length -gt 0)
    else
    {
        if ($LogFolders -eq $True) {
            Add-Content -Path $LogFile -Value ("No files found on "+$Folder+" folder.  (excluding "+$exclusions+")")
        }
    }
    Write-Host ($Count_TotalFolders.ToString()+" / "+$Folders.Count.ToString()+" folders searched...")
    $Count_TotalFolders+=1
} # foreach ($Folder in $Folders) 


$ScriptEndDate=(GET-DATE)
$Duration = NEW-TIMESPAN –Start $ScriptStartDate –End $ScriptEndDate

$LogMessage = ("Total script duration: "+$Duration.ToString())
Write-Host ""
Write-Host $LogMessage
Write-Host ""
Add-Content -Path $LogFile -Value ('-'*100)
Add-Content -Path $LogFile -Value ""
Add-Content -Path $LogFile -Value $LogMessage
Add-Content -Path $LogFile -Value ""
Add-Content -Path $LogFile -Value (('-'*45)+" THE END "+('-'*45))
Add-Content -Path $LogFile -Value ""
Add-Content -Path $LogFile -Value "Found in files:"
Add-Content -Path $LogFile -Value ""

Write-Host ""

if ($FoundInFiles.Count -gt 0) {
    Write-Host "Found in files:"

    foreach($LogMessage in $FoundInFiles) {
        Add-Content -Path $LogFile -Value $LogMessage
        Write-Host $LogMessage
    }
} else {
    Write-Host "String NOT found in any files."
}
Add-Content -Path $LogFile -Value ('-'*100)
Add-Content -Path $LogFile -Value ""