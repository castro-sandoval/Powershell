<#**************************************************************************************************************************************
This script drilldown through a folter structure from a RootFolder, find all files and for each file that contais a string StrToFind
replace it with a new one NewStr
**************************************************************************************************************************************#>

$RootFolder  = 'C:\Users\sandoval.castroneto\Documents\LLamasoft\DevOps\Bayer\Bayer Workflow\For Adam\For Adam\DG Packages\Complete Auto'
$LogFile     = $RootFolder+'\FindStringInFile.log'

$exclusions  = @("*.dll","*.exe","*.pdb","*.lic","*.zip")   # Exclusion list for file search -> file will be ignored


$StrToFind   = 'Demand_SCG'


<#************************************************************************************************************************************#>
function FormatDatetime {
    param( [String]$dt )
    return ($dt.SubString(6,2)+"/"+$dt.SubString(4,2)+"/"+$dt.SubString(0,4)+" "+$dt.SubString(8,2)+":"+$dt.SubString(10,2)+":"+$dt.SubString(12,2)+"   (dd/mm/yyyy hh:nn:ss)")
}
<#****************************************************************************************************************************************#>
$allReplacements = @()

cls
if (Test-Path $LogFile) {
    Remove-Item -Path $LogFile
}
Add-Content -Path $LogFile -Value ("Backup databases log file - Created: "+(FormatDatetime (Get-Date -Format yyyMMddHmmss) ))
$LogMessage = '-'*100
Add-Content -Path $LogFile -Value $LogMessage

$ScriptStartDate=(GET-DATE)

$LogMessage = "Searching for '"+$StrToFind
Add-Content -Path $LogFile -Value $LogMessage
Write-Host $LogMessage

$LogMessage = '-'*100
Add-Content -Path $LogFile -Value $LogMessage


#========== Collect folder structure =============
$Folders = @()
$Folders += $RootFolder

foreach($Folder in Get-ChildItem -Path $RootFolder -Directory -Recurse) {
    $Folders += ($Folder.FullName.ToString())
}


#========= Go through each folder ================
foreach ($Folder in $Folders) 
{
        
    $Files = (Get-ChildItem -Path $Folder -Exclude $exclusions | Where-Object {((!$_.PSIsContainer) -and ($_.Extension -eq ".dgproj"))})


    if ($Files.Length -gt 0) 
    {
        $LogMessage = ($Files.Count.ToString() +" files found on "+$Folder+" folder.  (excluding "+$exclusions+")"  )
        Add-Content -Path $LogFile -Value $LogMessage

        Write-host ""
        Write-Host $LogMessage

        foreach($File in $Files)
        {
            $LogMessage = ("      Analysing "+$File.FullName)
            Add-Content -Path $LogFile -Value $LogMessage
            if ($Files.Length -gt 0) {
                Write-Host $LogMessage
            }
            $StrFound=0
            $FileContent = Get-Content -Path $File.FullName
            foreach($line in $FileContent)
            {
            
                if($line.IndexOf($StrToFind) -ge 0) {
                    $StrFound = $StrFound + 1
                }
            }
            if ($StrFound -gt 0) 
            {
                $allReplacements += $File.FullName
                $LogMessage = ("               "+$StrFound.ToString()+" occurance found in file "+$File.FullName)
                Write-host $LogMessage
                Add-Content -Path $LogFile -Value $LogMessage
            }

        } # foreach($File in $Files)
    } # if ($Files.Length -gt 0)
    else
    {
        Add-Content -Path $LogFile -Value ("No files found on "+$Folder+" folder.  (excluding "+$exclusions+")")
    }
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
Add-Content -Path $LogFile -Value "Modified files:"
Add-Content -Path $LogFile -Value ""
foreach($LogMessage in $allReplacements) {
    Add-Content -Path $LogFile -Value $LogMessage
}
Add-Content -Path $LogFile -Value ('-'*100)
Add-Content -Path $LogFile -Value ""