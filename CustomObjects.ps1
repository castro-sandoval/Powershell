cls
$PSMajorVersion       = $PSVersionTable.PSVersion.Major
if ($PSMajorVersion -ge 5) {
    Write-Host ("Compression available! This is PowerShell "+$PSVersionTable.PSVersion.ToString())
} else {
    Write-Host ("Compression NOT available! This is PowerShell "+$PSVersionTable.PSVersion.ToString())
}

<#____________________________________________________________________________________________________________________
                                Saving the information to file
______________________________________________________________________________________________________________________#>

cls
$BaseFolder = "C:\Users\sandoval.castroneto\Desktop\"
$HistoryFile       = "MyFile"


if (Test-Path -Path ($BaseFolder+$HistoryFile+".zip")) {
    Remove-Item -Path ($BaseFolder+$HistoryFile+".zip") -Force
}

$DBHistory = @()

$loop = 0
while ($loop -lt 3) {
    
    $FileInfo = @((Get-Date), ("dbname"+$loop.ToString()), ("logicalFN"+$loop.ToString()) , ("D"+$loop.ToString()), (123*+$loop) )
    $n = New-Object System.Object
    $n = $n | Add-Member @{DateTime=$FileInfo[0];Database=$FileInfo[1];LogicalFileName=$FileInfo[2];Filetype=$FileInfo[3];SizeMB=$FileInfo[4]} -PassThru

    
    $DBHistory+=$n

    $loop+=1
}


$DBHistory | Export-Csv -Path ($BaseFolder+$HistoryFile+".bin")
Compress-Archive -Path ($BaseFolder+$HistoryFile+".bin") -DestinationPath ($BaseFolder+$HistoryFile+".zip") -CompressionLevel Optimal


if (Test-Path -Path ($BaseFolder+$HistoryFile+".bin")) {
    Remove-Item -Path ($BaseFolder+$HistoryFile+".bin") -Force
}



<#____________________________________________________________________________________________________________________
                                Retrieving the information from file
______________________________________________________________________________________________________________________#>

cls
$BaseFolder = "C:\Users\sandoval.castroneto\Desktop\"
$HistoryFile       = "MyFile"


Expand-Archive ($BaseFolder+$HistoryFile+".zip") -DestinationPath $BaseFolder

if (Test-Path -Path ($BaseFolder+$HistoryFile+".zip")) {
    Remove-Item -Path ($BaseFolder+$HistoryFile+".zip") -Force
}


$DBHistory = Import-Csv -Path ($BaseFolder+$HistoryFile+".bin")

if (Test-Path -Path ($BaseFolder+$HistoryFile+".bin")) {
    Remove-Item -Path ($BaseFolder+$HistoryFile+".bin") -Force
}

$DBHistory
