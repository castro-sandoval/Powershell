$mdfPath = "C:\Databases\MSSQLSERVER\copiedDB.mdf"
$mdfPath = "C:\Databases\MSSQLSERVER\MSSQLSERVER2017\MSSQL14.MSSQLSERVER2017\MSSQL\DATA\master.mdf"
Clear-Host
#====================================================================================================================
function Get-CompatibilityLevel
{
    Param ( [Parameter(Mandatory)]$InternalVer)
    if (($InternalVer -ge 895) -and ($InternalVer -le 904))
    { return 150 }
    else
    {
        if (($InternalVer -ge 868) -and ($InternalVer -le 869))
        { return 140 }
        else
        {
            switch ($InternalVer) {
                852 {130;break}
                782 {120;break}
                706 {110;break}
                default {0;break}
            }
        }
    }
}
function Get-Version
{
    Param ( [Parameter(Mandatory)]$CompatibilityLevel)
    switch ($CompatibilityLevel) {
        150 {2019;break}
        140 {2017;break}
        130 {2016;break}
        120 {2014;break}
        110 {2012;break}
        default {0;break}
    }
}
#====================================================================================================================
try 
{
    $Version = get-content -Encoding Byte $mdfPath | select-object -skip 0x12064 -first 2
    write-host ($mdfPath+" is "+(Get-Version -CompatibilityLevel (Get-CompatibilityLevel -InternalVer (($Version[1]*256)+$Version[0]))).ToString())
}
catch {
    write-host ($mdfPath+" is in use. Stop SQLServer service and try agaain.")
    Get-Service | Where-Object {(($_.Name -like "*SQLSERVER*") -and ($_.Status -eq "Running"))}
}
