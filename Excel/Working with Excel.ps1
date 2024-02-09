
clear-host
$strFile = "C:\temp\20201130-databases.xlsx" #   USTransplaceNewTL_AllData_Q32019_ForTransplace.xlsx"
$objExcel = New-Object -ComObject Excel.Application
$WorkBook = $objExcel.Workbooks.Open($strFile)
#$objExcel.WorkBooks | Select-Object -Property name, path, author

# $objExcel.WorkBooks | Get-Member
$WorkBook | Get-Member -Name *sheet*



$AllSheetNames=($WorkBook.sheets | Select-Object -Property Name).Name

foreach($SheetName in $AllSheetNames) {
    $WorkSheet = $WorkBook.sheets.item($SheetName)
    Write-Host $SheetName -ForegroundColor Blue -BackgroundColor Gray

    
    $RowCount=-1
    Do
    {
        $ColCount=-1
        $RowCount+=1
        $ColHasData = $worksheet.Rows.Item($RowCount).Columns.Item($ColCount+1).Text

            Do
            {
                 $ColCount+=1
                 $ColHasData = $worksheet.Rows.Item($RowCount).Columns.Item($ColCount+1).Text
            } while ($ColHasData)

    } while ($HasData)

    $RowCount.ToString()+" rows and "+$ColCount.ToString()+" cols"

}


<#

if ($RowCount -gt 0) 
{
    $worksheet.cells.Item(1, 1).value2

    $worksheet.Columns.Item(2).Rows.Item(1).Text
    $worksheet.Rows.Item(2).Columns.Item(3).Text
}
#>

$WorkBook.Close($false)

