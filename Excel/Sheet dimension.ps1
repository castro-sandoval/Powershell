Clear-Host
$File = "C:\temp\20201130-databases.xlsx"
$SheetName = "Sheet2"
$Excel = New-Object -ComObject "Excel.Application"

$Workbook = $Excel.workbooks.open($File)
$Sheet = $Workbook.Worksheets.Item($SheetName)
$objRange = $Sheet.UsedRange
$RowCount = $objRange.Rows.Count
$ColumnCount = $objRange.Columns.Count
Write-Host "RowCount:" $RowCount
Write-Host "ColumnCount" $ColumnCount



$Workbook.Close($false)
$Excel.Quit()