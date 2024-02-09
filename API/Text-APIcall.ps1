
Clear-Host

<#===================================================================================================================================== 
                    PARAMETER DEFINITIONS
=====================================================================================================================================#>
$Username = ""
$Password = ""

    <#****************************************************************************************
    Parameters definition
    ****************************************************************************************#>


    $userId            = "47DA3A86-A040-4FAE-8F90-19D7D1B380F8"
    $userName          = "monarch.testing@llamasoft.com"
    $connectionKey     = "Monarch"
    $authHost          = "https://qa.llama.ai"


    <#****************************************************************************************
                                            Create objects
    ****************************************************************************************#>
    $body    = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"

    <#****************************************************************************************
                                            Get authentication token
    ****************************************************************************************#>
    Write-Host ((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss")+" - STEP 2 - Get authentication token")
    $uri=$authHost+"/api/authentication/connect/token"

    $headers.Clear()
    $body.Clear()

    $headers.Add("Authorization", "Bearer $token")

    $body.Add("client_id","8c107649-2c17-4eeb-9f20-bc5a17c66ccb")
    $body.Add("client_secret","0490116b-f224-4b46-b897-e95fcefb47c1")
    $body.Add("grant_type","impersonation")
    $body.Add("impersonate_user","$userName")
    $body.Add("scope","openid profile llamasoft_platform scg_ws_api")


    Write-Host ("POST "+$uri)
    try 
    {
        $token = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -ErrorAction Stop
        Write-Host ((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss")+" - Token aquired!") -ForegroundColor Green
    } 
    catch 
    {
        Write-Host ((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss")+" - failed!") -ForegroundColor Red
    }
    
