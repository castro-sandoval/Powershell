function Hex2Dec
{
param($HEX)
ForEach ($value in $HEX)
{
    [Convert]::ToInt32($value,16)
}
}