
clear-host
$strFile = "C:\temp\20201130-databases.xlsx"
$objExcel = New-Object -ComObject Excel.Application
$WorkBook = $objExcel.Workbooks.Open($strFile)

$FormulaFound = 0

$AllSheetNames=($WorkBook.sheets | Select-Object -Property Name).Name
foreach($SheetName in $AllSheetNames) {
    $WorkSheet = $WorkBook.sheets.item($SheetName)
    Write-Host $SheetName -ForegroundColor Blue -BackgroundColor Gray

    $Sheet = $Workbook.Worksheets.Item($SheetName)
    $objRange = $Sheet.UsedRange
    $RowCount = $objRange.Rows.Count
    $ColumnCount = $objRange.Columns.Count
    Write-Host "RowCount:" $RowCount
    Write-Host "ColumnCount" $ColumnCount

    
    for($R=1; $R -le $RowCount; $R++)
    {
        for($C=1; $C -le $ColumnCount; $C++)
        {
            if ($worksheet.Columns.Item($C).Rows.Item($R).Text)
            {
                #$worksheet.Columns.Item($C).Rows.Item($R).Text.SubString(0,1)
                if ($worksheet.Columns.Item($C).Rows.Item($R).Formula.SubString(0,1) -eq "=")
                {
                    write-host ($R.ToString()+"x"+$C.ToString()+" is formula: "+$worksheet.Columns.Item($C).Rows.Item($R).Formula)
                    $FormulaFound=1
                    break
                }
            }
        }
        if($FormulaFound -eq 1) 
        {
            break
        }
    }
}

$WorkBook.Close($false)
$objExcel.Quit()

$FormulaFound