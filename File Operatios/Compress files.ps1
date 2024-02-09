
Compress-Archive -Path $DataFilesFolder -DestinationPath $OutputFile -CompressionLevel Optimal
Expand-Archive $IncomeFolder\$file -DestinationPath $IncomeFolder


#================================================================

$DestFileName = "C:\Users\sandoval.castroneto\Documents\ITOperations\servername"+ (Get-Date -Format yyyddMMHmmss)+".zip"
Compress-Archive -Path "C:\Users\sandoval.castroneto\Documents\ITOperations\*.v*" -DestinationPath $DestFileName -CompressionLevel Optimal