﻿

$sysInfo = systeminfo /fO CSV | ConvertFrom-Csv

$sysInfo.'OS Name'
$sysInfo.'OS Version'
$sysInfo.'OS Manufacturer'
$sysInfo.'OS Configuration'
$sysInfo.'OS Build Type'
$sysInfo.'Registered Owner'
$sysInfo.'Registered Organization'
$sysInfo.'Product ID'
$sysInfo.'Original Install Date'
$sysInfo.'System Boot Time'
$sysInfo.'System Manufacturer'
$sysInfo.'System Model'
$sysInfo.'System Type'
$sysInfo.'Processor(s)'
$sysInfo.'BIOS Version'
$sysInfo.'System Locale'
$sysInfo.'Input Locale'
$sysInfo.'Time Zone'
$sysInfo.'Total Physical Memory'
$sysInfo.'Available Physical Memory'
$sysInfo.'Virtual Memory: Max Size'
$sysInfo.'Virtual Memory: Available'
$sysInfo.'Virtual Memory: In Use'
$sysInfo.'Domain'
$sysInfo.'Logon Server'
$sysInfo.'Network Card(s)'
$sysInfo.'Hotfix(s)'