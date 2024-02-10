Invoke-Command -Computername SCASTRO-T460S -ScriptBlock { Stop-Service -Name 'Bonjour Service' -force }

Invoke-Command -Computername SCASTRO-T460S -ScriptBlock { Start-Service -Name 'Bonjour Service' }  