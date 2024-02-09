$strFile = "C:\temp\20201130-databases.xlsx" #   USTransplaceNewTL_AllData_Q32019_ForTransplace.xlsx"
$objExcel = New-Object -ComObject Excel.Application
$WorkBook = $objExcel.Workbooks.Open($strFile)


$XMLstrFile = "C:\temp\excel.xml"
$SheetIndex =1 
$WorkBook.SaveAs($XMLstrFile, $SheetIndex)

#$objExcel.WorkBooks | Select-Object -Property name, path, author

#$objExcel.WorkBooks | Get-Member
#"--------------------------------------------------------------------"
#$WorkBook | Get-Member -Name *xml*

$WorkBook.Close($false)
$objExcel.Quit()

