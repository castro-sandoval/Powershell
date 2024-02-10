Try
{
    # Try something that could cause an error
    1/0
}
Catch
{
    # Catch any error
    Write-Host "An error occurred "+$Error[0].Exception
}
Finally
{
    # [Optional] Run this part always
    Write-Host "cleaning up ..."
}


##==================================

Get the exception type
$Error[0].Exception.GetType().FullName


Try{
  # Find the user to update
  $ADUser = Get-AzureAdUser -ObjectId $user.UserPrincipalName -ErrorAction Stop
  # Update the job title
  Set-AzureAdUser -ObjectId $ADUser.ObjectId -JobTitle $user.jobtitle -ErrorAction Stop
}
Catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException]{
  # Catch a connection error
  Write-Warning "You need to Connect to AzureAD first"
}
Catch [Microsoft.Open.AzureAD16.Client.ApiException] {
  # Catch the when we are unable to find the user
  Write-Warning "Unable to find the user"
}
Catch {
  Write-Warning "An other error occured"
}


##=========================================================
<#
non-terminating errors. 
These are errors that won’t terminate (stop) the script. These kinds of errors can’t be caught with a catch block by default.

Most cmdlets in PowerShell are non-terminating. They will output an error, which you will see in red in your console, 
if you use them wrong, but they won’t stop the script. The reason for this the default ErrorAction in your PowerShell 
profile, which is set to Continue.
#>

Try {
    dir "c:\some\non-existing\path" -ErrorAction stop
    
}
Catch {
    Write-host "Directory does not exist"
}
