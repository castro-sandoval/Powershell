#Get-Module AzureRM -ListAvailable

$User = ""
$Password = ConvertTo-SecureString "" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Password


#--- Login to azure account
Login-AzureRmAccount -Credential $Credential


Find-AzureRmResourceGroup | Where-Object {($_.location -EQ "westeurope" -and $_.Properties -like "*provisioningState=Succeeded*")}

Find-AzureRmResource -ResourceType "Microsoft.Sql/servers"

Find-AzureRmResource -ResourceType "Microsoft.Sql/servers/databases" -ExpandProperties | Where-Object {$_.Name -like "*Sample*"}
