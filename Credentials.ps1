$password = ConvertTo-SecureString 'MySecretPassword' -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ('llamadev\Sandoval.CastroNeto', $password)


$credential.GetNetworkCredential().UserName
$credential.GetNetworkCredential().Password
