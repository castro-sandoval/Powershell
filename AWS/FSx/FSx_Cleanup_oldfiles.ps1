Clear-Host

$BackupTypes=@("FULL","DIFF","LOG")


$AllDevices = @("\\amznfsxmd8zsrjo.scg.guru\share\",
         #       "\\amznfsxmzz6t0eu.scg.guru\share\",
                "\\amznfsxumd0wg1i.scg.guru\share\")


foreach($device in $AllDevices) {
    
    $FSxPath=$device+"Backups\"
    write-host("Aquiring directories from "+$FSxPath+" ...") -ForegroundColor Green
    $servers=(Get-ChildItem -Path $FSxPath -Depth 1 -Directory).FullName
    foreach($server in $servers) {
        
        write-host("Aquiring subfolders from "+($server+"\")+" ...") -ForegroundColor Green
        $subfolder=(Get-ChildItem -Path ($server+"\") -Depth 1 -Directory).FullName
        if ($subfolder) {
            $FSxPathr=$subfolder
        } else {
            $FSxPath=$server
        }

        Write-Host($FSxPath) -BackgroundColor Green -ForegroundColor White


        foreach($BackupType in $BackupTypes) {
            $FileNameFilter = "\"+$BackupType+"*.BAK"
            $cutoff = (Get-Date).AddDays(-40)
        
            write-host("Reading from "+$FSxPath+$FileNameFilter+"    on or before ="+ $cutoff.ToString("yyyyMMdd"))

            $filesToDelete = Get-ChildItem -Path ($FSxPath+$FileNameFilter) | Where-Object{($_.CreationTime -le $cutoff)} | Select-Object -Last 1000
            Do {
                write-host("     Deleting "+$filesToDelete.count.ToString()+" from "+ $FSxPath+$FileNameFilter) -ForegroundColor Cyan
                $filesToDelete | Remove-Item -Force
                
                $filesToDelete = Get-ChildItem -Path ($FSxPath+$FileNameFilter) | Where-Object{($_.CreationTime -le $cutoff)} | Select-Object -Last 1000
            } while ($filesToDelete.count -gt 0)
            write-host("     Finished deleting from "+ $FSxPath+$FileNameFilter) -ForegroundColor Green
        }
    }
}