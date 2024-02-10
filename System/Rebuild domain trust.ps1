Reset-ComputerMachinePassword -Server "llamadev-dc4" -Credential "******"
Reset-ComputerMachinePassword -Server "llamadev-dc4" -Credential "*******"

<#
Reference:
https://serverfault.com/questions/826192/win-2012-domainthe-trust-relationship-between-this-workstation-and-the-primary

If you can gain access to a command prompt on the remote computer, via:

Enter-PSSession BrokenWorkstation
then you can use:

Test-ComputerSecureChannel –Credential YourDomain/DomainAdmin -Repair
There is also the possibility that it is just the system password that is messed up, so could use this too:

Reset-ComputerMachinePassword -Credential YourDomain/DomainAdmin -Server dc.yourdomain.local
That is if you have Powershell v3 on the workstation. If not then try the following:

WMIC /node:BrokenWorkstation process call create "netdom.exe resetpwd /s:dc.yourdomain.local /ud:YourDomain/DomainAdmin /pd:*"
shareimprove this answerfollow



#>