
function FormatedDatetime {
    param( [int]$fmt )
    $dt=(Get-Date -Format yyyymmddhhmmssfff)
    switch ($fmt) 
    {
        0 { return ($dt.SubString(6,2)+"/"+$dt.SubString(4,2)+"/"+$dt.SubString(0,4)+" "+$dt.SubString(8,2)+":"+$dt.SubString(10,2)+":"+$dt.SubString(12,2)+"."+$dt.SubString(14,3)+"   (dd/mm/yyyy hh:nn:ss.fff)") }
        1 { return ($dt.SubString(6,2)+"/"+$dt.SubString(4,2)+"/"+$dt.SubString(0,4)+" "+$dt.SubString(8,2)+":"+$dt.SubString(10,2)+":"+$dt.SubString(12,2)+"   (dd/mm/yyyy hh:nn:ss)") }
        2 { return ($dt.SubString(4,2)+"/"+$dt.SubString(6,2)+"/"+$dt.SubString(0,4)+" "+$dt.SubString(8,2)+":"+$dt.SubString(10,2)+":"+$dt.SubString(12,2)+"   (mm/dd/yyyy hh:nn:ss)") }
        3 { return ($dt.SubString(6,2)+"-"+$dt.SubString(4,2)+"-"+$dt.SubString(0,4)+" "+$dt.SubString(8,2)+":"+$dt.SubString(10,2)+":"+$dt.SubString(12,2)+"   (dd-mm-yyyy hh:nn:ss)") }
        4 { return ($dt.SubString(4,2)+"-"+$dt.SubString(6,2)+"-"+$dt.SubString(0,4)+" "+$dt.SubString(8,2)+":"+$dt.SubString(10,2)+":"+$dt.SubString(12,2)+"   (mm-dd-yyyy hh:nn:ss)") }
        5 { return ($dt.SubString(6,2)+"/"+$dt.SubString(4,2)+"/"+$dt.SubString(0,4)+"   (dd/mm/yyyy)") }
        6 { return ($dt.SubString(4,2)+"/"+$dt.SubString(6,2)+"/"+$dt.SubString(0,4)+"   (mm/dd/yyyy)") }
        7 { return ($dt.SubString(8,2)+":"+$dt.SubString(10,2)+":"+$dt.SubString(12,2)+"   (hh:nn:ss.fff)") }
        7 { return ($dt.SubString(8,2)+":"+$dt.SubString(10,2)+":"+$dt.SubString(12,2)+"   (hh:nn:ss)") }
        8 { return ($dt.SubString(8,2)+":"+$dt.SubString(10,2)+"   (hh:nn)") }

        default { return $dt.ToString() }
    }
}



<#****************************************************************************************************************************************#>
cls
Write-Host (FormatedDatetime 99)
Write-Host (FormatedDatetime 0)
Write-Host (FormatedDatetime 1)
Write-Host (FormatedDatetime 2)
Write-Host (FormatedDatetime 3)
Write-Host (FormatedDatetime 4)
Write-Host (FormatedDatetime 5)
Write-Host (FormatedDatetime 6)
Write-Host (FormatedDatetime 7)
Write-Host (FormatedDatetime 8)

