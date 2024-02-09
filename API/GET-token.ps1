Clear-Host
$env      = "PROD"

Switch($env) {
    "DEV" { 
            $authHost      = "https://dev.llama.ai"
            $client_id     = "8c107649-2c17-4eeb-9f20-bc5a17c66ccb"
            $client_secret = "0490116b-f224-4b46-b897-e95fcefb47c1"
        }
    "QA" {
        
            $authHost      = "https://qa.llama.ai"
            $client_id     = "8c107649-2c17-4eeb-9f20-bc5a17c66ccb"
            $client_secret = "0490116b-f224-4b46-b897-e95fcefb47c1"
        }
    "STAGING" {
        
            $authHost      = "https://staging.llama.ai"
            $client_id     = "8c107649-2c17-4eeb-9f20-bc5a17c66ccb"
            $client_secret = "0D502DAE-DF91-450C-AF24-42EADA1E37B6"
        }
    "PROD" {
        
            $authHost      = "https://us.llama.ai"
            $client_id     = "8c107649-2c17-4eeb-9f20-bc5a17c66ccb"
            $client_secret = "EC2230EC-38B8-48A9-9663-95C739FE97D4"
        }
}


    <#****************************************************************************************
                                            Create objects
    ****************************************************************************************#>
    $body    = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"

    <#****************************************************************************************
                                            Get authentication token
    ****************************************************************************************#>
    Write-Host ((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss")+" - Get authentication token")
    $uri=$authHost+"/api/authentication/connect/token"

    $headers.Clear()
    $body.Clear()

    $headers.Add("Authorization", "Bearer $token")

    $body.Add("client_id",$client_id)
    $body.Add("client_secret",$client_secret)
    
    $body.Add("grant_type","impersonation")
    $body.Add("impersonate_user","sandoval.castroneto@coupa.com")
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
    
