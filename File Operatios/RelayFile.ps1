$filesname="D:\K2Reports\K2DataServicesLogs_*.bak"

if ((Get-ChildItem -Path $filesname).Count -gt 0) {
    if (!(Test-Path -Path "R:\")) {
        $secpasswd = ConvertTo-SecureString "llama123!" -AsPlainText -Force
        $mycreds = New-Object System.Management.Automation.PSCredential ("DCHSSQL\K2ReportUser", $secpasswd)
        New-PSDrive -Name R -PSProvider FileSystem -Root "\\DCHSSQL\K2Reports" -Credential $mycreds
    }
    if (Test-Path -Path "R:\") {
        $files = (Get-ChildItem -Path $filesname)
        Copy-Item -Path $filesname -Destination "R:\"
        Remove-Item -Path $filesname -Force
    }
    Add-Content -Path "D:\K2Reports\K2Reports.log" -Value ((Get-Date).ToString()+" : Files copied to SAASDSRPT:"+$files.FullName)
}
