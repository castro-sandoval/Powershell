<#================================================================================================
        Menu structure
-----------|-----------------------------------------------
Options    |      Call
-----------|-----------------------------------------------
0          | Given IP find server
1 to 3     | Master servers - 1 llamadev   2-scg    3-prodeu
4 to 9     | Choose environment - 4-DEV  5-QA  6-STAGING  7-PROD  8-PRODEU
10 to 900  | Servers         
901 to 999 | Admin tasks - 995-Edit   994-Replace   993-DNS List
================================================================================================#>

Set-Variable deltaMaster -Option ReadOnly -Value 1 # To master servers
Set-Variable deltaServers -Option ReadOnly -Value 10 # To servers
Set-Variable deltaEnv -Option ReadOnly -Value 4 # To environment

Set-Variable IPlist -Option ReadOnly -Value  992
Set-Variable dnslist -Option ReadOnly -Value  993
Set-Variable replace -Option ReadOnly -Value  994
Set-Variable edit -Option ReadOnly -Value  995

$masterservers = @("llamadev","scg","prodeu")
Set-Variable MSllamadev -Option ReadOnly -Value 0
Set-Variable MSscg -Option ReadOnly -Value 1
Set-Variable MSprodeu -Option ReadOnly -Value 2

$envdesc = @("dev","qa","staging","prod","prodeu")
Set-Variable dev -Option ReadOnly -Value 0
Set-Variable qa -Option ReadOnly -Value 1
Set-Variable staging -Option ReadOnly -Value 2
Set-Variable prod -Option ReadOnly -Value 3
Set-Variable prodeu -Option ReadOnly -Value 4

#======= color constants =====================
Set-Variable black -Option ReadOnly -Value 0
Set-Variable darkblue -Option ReadOnly -Value 1
Set-Variable darkgreen -Option ReadOnly -Value 2
Set-Variable darkcyan -Option ReadOnly -Value 3
Set-Variable darkred -Option ReadOnly -Value 4
Set-Variable darkmagenta -Option ReadOnly -Value 5
Set-Variable darkyellow -Option ReadOnly -Value 6
Set-Variable gray -Option ReadOnly -Value 7
Set-Variable darkgray -Option ReadOnly -Value 8
Set-Variable blue -Option ReadOnly -Value 9
Set-Variable green -Option ReadOnly -Value 10
Set-Variable cyan -Option ReadOnly -Value 11
Set-Variable red -Option ReadOnly -Value 12
Set-Variable Magenta -Option ReadOnly -Value 13
Set-Variable yellow -Option ReadOnly -Value 14
Set-Variable white -Option ReadOnly -Value 15
#===================================================================================================
$ServerType = New-Object System.Collections.ArrayList
$ServerName = New-Object System.Collections.ArrayList
$ServerIP   = New-Object System.Collections.ArrayList
$ServerPw   = New-Object System.Collections.ArrayList
$ServerUsr  = New-Object System.Collections.ArrayList

$MasterServerName = New-Object System.Collections.ArrayList
$MasterServerIP   = New-Object System.Collections.ArrayList
$MasterServerPw   = New-Object System.Collections.ArrayList
$MasterServerUsr  = New-Object System.Collections.ArrayList

#===================================================================================================
$env=$dev # default env initialization

$columns     = 2
$MyRDCFolder = (split-path -parent $MyInvocation.MyCommand.Definition)+"\dat"

$DLLfolder = "C:\Users\SandovalDeCastroNeto\Documents\PowerShell\MyRDC\"

Import-Module -Name ($DLLfolder+"swUtils.dll")
Import-Module -Name ($DLLfolder+"swkey.dll")
Import-Module -Name ($DLLfolder+"MyRDC.dll")


$input=$env+$deltaEnv
$envFile = $MyRDCFolder+"\MyRDV"+$envdesc[$env]
$MasterFile = $MyRDCFolder+"\master.key"


if (!(Test-Path ($envFile+".dat")) ){
    New-Item -ItemType File ($envFile+".dat")
}

<#===================================================================================================================================== 
                    FUNCTION DEFINITIONS
=====================================================================================================================================#>
function GetColor
{
    param([string]$servername)
            if ($servername -eq "none") 
            {
                return 0
            }
            else 
            {
                if ($servername -like '*dataops_svc*') 
                {
                    return $red
                }
                else
                {
                    if ($servername -like '*permanent*') 
                    {
                        return $white
                    }
                    else
                    {
                        if (($servername -like '*dbmaster*') -or ($servername -like '*dataops*')) 
                        {
                            return $Magenta
                        }
                        else
                        {
                            if ($servername -like '*-sb-*')
                            {
                                return $cyan
                            } 
                            else 
                            {
                                if (($servername -like '*meta*') -or ($servername -like '*datahub*'))
                                {
                                    return $darkyellow
                                }
                                else
                                {
                                    
                                    
                                    if ((($servername -like '*pool*') -and ($servername -like '*01')) -or ($servername -like '*quarantine*'))
                                    {
                                        return $yellow
                                    }
                                    else
                                    {
                                        if (($servername -like '*scdp-reporting-service*') -or ($servername -like '*scdp-restore-sql*'))
                                        {
                                            return $green
                                        }
                                        else
                                        {
                                            return $white
                                        }
                                    }





                                }
                            }

                        }

                    }
                }
            }
}

function OrderDATfile {
    $tempFile = ($envFile+".tmp")
    $ServerName = @() # name
    $IP         = @() # IP
    $Username   = @() # Username
    $Psw        = @() # Pswrd
    $Servers    = Get-Content $envFile+".dat"
    $i=0
    while ($i -lt $Servers.Count) {
        $ServerName+=$Servers[$i]
        $IP+=$Servers[$i+1]
        $Username+=$Servers[$i+2]
        $Psw+=$Servers[$i+3]
        $i=$i+4
    }
    $OrderedServerName = $ServerName | Sort-Object
    #========================================================================================
    if (Test-Path -Path $tempFile) {
        Remove-Item -Path $tempFile -Force
    }
    if (Test-Path -Path ($envFile+".dat")) {
        Remove-Item -Path ($envFile+".dat.old") -Force
        Rename-Item -Path ($envFile+".dat") -NewName ($envFile+".dat.old")
    }
    if (Test-Path -Path ($envFile+".srv")) {
        Remove-Item -Path ($envFile+".srv.old") -Force
        Rename-Item  -Path ($envFile+".srv") -NewName ($envFile+".srv.old")
    }
    #========================================================================================
    for ($k=0;$k -le 1;$k++) {
        Add-Content -Path $tempFile -Value $ServerName[$k]
        Add-Content -Path $tempFile -Value $IP[$k]
        Add-Content -Path $tempFile -Value $Username[$k]
        Add-Content -Path $tempFile -Value $Psw[$k]

        Add-Content ($envFile+".srv") (Format-Encrypt($ServerName[$k]))
        Add-Content ($envFile+".srv") (Format-Encrypt($IP[$k]))
        Add-Content ($envFile+".srv") (Format-Encrypt($Username[$k]))
        Add-Content ($envFile+".srv") (Format-Encrypt($Psw[$k]))
    }
    $i=0
    while ($i -lt $OrderedServerName.Length) {
        if (($OrderedServerName[$i] -ne $ServerName[0]) -and ($OrderedServerName[$i] -ne $ServerName[1])) {
            $k = $ServerName.IndexOf($OrderedServerName[$i]) 
            Add-Content -Path $tempFile -Value $ServerName[$k]
            Add-Content -Path $tempFile -Value $IP[$k]
            Add-Content -Path $tempFile -Value $Username[$k]
            Add-Content -Path $tempFile -Value $Psw[$k]

            Add-Content ($envFile+".srv") (Format-Encrypt($ServerName[$k]))
            Add-Content ($envFile+".srv") (Format-Encrypt($IP[$k]))
            Add-Content ($envFile+".srv") (Format-Encrypt($Username[$k]))
            Add-Content ($envFile+".srv") (Format-Encrypt($Psw[$k]))
        }
        $i++
    }
    # make temp ordered file the new server list file
    Rename-Item -Path $tempFile -NewName ($MyRDCFolder+"\MyRDV.dat")
    Format-swFile -SourceFilePath ($MyRDCFolder+"\MyRDV.dat") -Action "E" -LogFileFolder $MyRDCFolder
    Remove-Item ($envFile+".srv")
    Rename-Item ($envFile+".key") ($envFile+".srv")
    LoadServers

}

function GetMenuOption 
{
    param([int] $Option)

    if ($Option -eq $edit)
    {
        $menuOption = $replace.ToString()+"-Replace   "
    }
    else
    {
        #$menuOption = " 0-Quit"+"   "
        #$menuOption +="LLamadev 2-Master SCG  3-Master ProdEU"+"   "
        $menuOption += ($dev+$deltaEnv).ToString()+"-"+$envdesc[$dev]+"   "
        $menuOption += ($qa+$deltaEnv).ToString()+"-"+$envdesc[$qa]+"   "
        $menuOption += ($staging+$deltaEnv).ToString()+"-"+$envdesc[$staging]+"   "
        $menuOption += ($prod+$deltaEnv).ToString()+"-"+$envdesc[$prod]+"   "
        $menuOption += ($prodeu+$deltaEnv).ToString()+"-"+$envdesc[$prodeu]+"   "

        $menuOption += $dnslist.ToString()+"-Export DNS list    "
        $menuOption += $IPlist.ToString()+"-Export IP list    "

        $menuOption += $edit.ToString()+"-Edit          "
    }

    return $menuOption
}

#==========================================================================================
function Show-Menu
{
    param([int] $Option)

     Clear-Host

     $HalfColumns = ([Math]::Ceiling(($ServerName.count-1)/$columns))
     $columnSize = 80
     $lines      = [math]::ceiling($ServerName.Count/$columns)
     $MyMenu     = New-Object 'object[,]' $lines,$columns
     $MenuColor  = New-Object 'object[,]' $lines,$columns

     Write-Host ("_"*($columnSize*$columns+13))
     
     switch($env)
     {
        $prod   {$BackgroundColor=$red 
                $ForegroundColor=$white 
                }
        $prodeu {$BackgroundColor=$darkmagenta 
                $ForegroundColor=$white 
                }

        default
                {$BackgroundColor=$darkgray
                $ForegroundColor=$white 
                }
        
     }

     Write-Host (GetMenuOption -Option $Option) -BackgroundColor $BackgroundColor -ForegroundColor $ForegroundColor

     Write-Host ("_"*($columnSize*$columns+13))
     
     if ($ServerName.Length -gt 0) {
        $l=0
        $c=0
        $Option=$deltaServers
        For($Position=0; $Position -lt $ServerName.Count; $Position++) {

            $MyMenu[$l,$c] = ($Option.ToString()+("." * (($columnSize-$ServerName[$Position].Length-$ServerIP[$Position].Length)+(2-$Option.ToString().Length))) + $ServerName[$Position] + "  "+ $ServerIP[$Position])+" | "
   

            $MenuColor[$l,$c] = [Enum]::GetValues([ConsoleColor])[ (GetColor -servername $ServerName[$Position]) ]

            if ($Position -eq ($HalfColumns-1)) {
                $c = 1
                $l=0
            } else {
                $l++
            }

            $Option++
            
        } # For

        
        #=====================
        # Print Menu
        for ($l=0;$l -lt ($MyMenu.Count/$columns);$l++) {
            for ($c=0;$c -lt $columns;$c++) {
                Write-Host $MyMenu[$l,$c] -NoNewline -ForegroundColor $MenuColor[$l,$c]
            }
            Write-Host ""
            $columnOptions=""
        }
        
    }
    
    Write-Host ("_"*($columnSize*$columns+13))    
}

#==========================================================================================
function LoadMasterServers {
    $MasterServerName.Clear()
    $MasterServerIP.Clear()
    $MasterServerUsr.Clear()
    $MasterServerPw.Clear()
    $MasterServers = Get-Content ($MasterFile)

    
    $line = 0
    Foreach($lineInfo in $MasterServers) {
        $line = $line + 1
        
        $text = Format-Decrypt($lineInfo)
        #$text = $lineInfo

        switch ($line % 4)
        {
            1 { $MasterServerName.Add($text) > $null }
            2 { $MasterServerIP.Add($text) > $null}
            3 { $MasterServerUsr.Add($text) > $null}
            0 { $MasterServerPw.Add($text) > $null }
        }
    }

    if ((($MassterServers.Length/4) % 2) -ne 0) {
        $text="none"
        $MasterServerName.Add($text) > $null
        $MasterServerIP.Add($text) > $null
        $MasterServerUsr.Add($text) > $null
        $MasterServerPw.Add($text) > $null
    }
     
    if (Test-Path -Path ($envFile+".dat")) {
        Remove-Item ($envFile+".dat")
    }
}

#==========================================================================================
function LoadServers {
    $ServerType.Clear()
    $ServerName.Clear()
    $ServerIP.Clear()
    $ServerUsr.Clear()
    $ServerPw.Clear()
    $Servers = Get-Content ($envFile+".srv")

    
    $line = 0
    Foreach($lineInfo in $Servers) {
        $line = $line + 1
        $text = Format-Decrypt($lineInfo)
        switch ($line % 4)
        {
            1 { $ServerName.Add($text) > $null
                $ServerType.Add($text.Substring(0,1)) > $null                
              }
            2 {$ServerIP.Add($text) > $null}
            3 {$ServerUsr.Add($text) > $null}
            0 {
                $ServerPw.Add($text) > $null
              }
        }
    }

    if ((($Servers.Length/4) % 2) -ne 0) {
        $text="none"
        $ServerName.Add($text) > $null
        $ServerType.Add($text.Substring(0,1)) > $null                
        $ServerIP.Add($text) > $null
        $ServerUsr.Add($text) > $null
        $ServerPw.Add($text) > $null
    }
     
    if (Test-Path -Path ($envFile+".dat")) {
        Remove-Item ($envFile+".dat")
    }
}

#==========================================================================================
function ExportServerList {
    $Outputfilepath = $envFile+".dat"
    if (Test-Path -Path $Outputfilepath) {
        Remove-Item $Outputfilepath
    }
    $Position = 0
    For($Position=0; $Position -lt $ServerName.Count; $Position++) {
        Add-Content -Path $Outputfilepath -Value $ServerName[$Position]
        Add-Content -Path $Outputfilepath -Value $ServerIP[$Position]
        Add-Content -Path $Outputfilepath -Value $ServerUsr[$Position]
        Add-Content -Path $Outputfilepath -Value $ServerPw[$Position]
    }
}

#==========================================================================================
function ExportIPList {
    $Outputfilepath = $envFile+"_IPs.txt"
    if (Test-Path -Path $Outputfilepath) {
        Remove-Item $Outputfilepath
    }
    $Position = 0
    For($Position=0; $Position -lt $ServerName.Count; $Position++) {
        #Add-Content -Path $Outputfilepath -Value $ServerName[$Position]
        Add-Content -Path $Outputfilepath -Value $ServerIP[$Position]
        #Add-Content -Path $Outputfilepath -Value $ServerUsr[$Position]
        #Add-Content -Path $Outputfilepath -Value $ServerPw[$Position]
    }
}

#==========================================================================================
function ExportDNSList {
    $Outputfilepath = $envFile+".csv"
    if (Test-Path -Path $Outputfilepath) {
        Remove-Item $Outputfilepath
    }
    $Position = 0
    $separator = "`t "
    Add-Content -Path $Outputfilepath -Value ("ENV"+$separator+"CONSUL KEY"+$separator+"CONSUL CONNECTION STRING"+$separator+"DNS - CNAME"+$separator+"DNS - A RECORD")
    For($Position=0; $Position -lt $ServerName.Count; $Position++) {
        if ($ServerName[$Position] -like "*pool1*")
        {
            $srvname=$ServerName[$Position].Substring($ServerName[$Position].IndexOf("pool"), $ServerName[$Position].Length-$ServerName[$Position].IndexOf("pool"))
            $env = ($srvname -split "-")[2]
            $env_lastChar = $env.Substring($env.Length-2,2)
            if($env_lastChar -match "^\d+$")
            {
               $env=$env.Substring(0,$env.Length-2)
            }
            $line = $env+$separator+$srvname+".llamaprod.net"+$separator+"Data Source="+$srvname+".llamaprod.net,50000;Integrated Security=false;User ID=platformuser;Password=*********"+$separator+$srvname+".llamaprod.net"+$separator+$ServerIP[$Position]
            Add-Content -Path $Outputfilepath -Value $line
        }
    }
}

function RDP_MasterServer
{
    param([int] $Option)

                $Server=$MasterServerIP[[int]$Option-$deltaMaster]
                $User=""""+$MasterServerUsr[[int]$Option-$deltaMaster]+""""
                $Password=$MasterServerPw[[int]$Option-$deltaMaster]
                Write-Host ("Connecting to "+$MasterServerName[[int]$Option-$deltaMaster]) -BackgroundColor DarkGray -ForegroundColor Yellow
                Start-Sleep -Seconds 2

                cmdkey /generic:TERMSRV/$Server /user:$User /pass:$Password
                mstsc /v:$Server
}

function Find_IP {
    param([string]$IP)

    $found = 0 
    for($i=0;$i -lt $envdesc.Count; $i++) {
    $srvFile = $MyRDCFolder+"\MyRDV"+$envdesc[$i]+".srv"
        
        write-host ("Search "+$IP+" on "+$srvFile)
        $Servers = Get-Content ($srvFile)
    
        $line = 0
        Foreach($lineInfo in $Servers) {
            $line = $line + 1
            $text = Format-Decrypt($lineInfo)
            
            switch ($line % 4)
            {
                1 { $line_name = $text }
                2 { $line_IP = $text }
            }

            if ($line_IP -eq $IP) {
                Write-Host 
                Write-Host ("Found "+$IP+" as "+$line_name) -ForegroundColor Green
                $found = 1
                break
            }
        }
        if ($found -eq 1) {
            break
        }

    }

    if ($found -eq 0) {
        Write-Host ($IP+" not found.") -ForegroundColor Red
    }

    Write-Host 
    $input = Read-Host "Press 9 to show menu"

}
#==========================================================================================
LoadMasterServers
LoadServers

Do
{
    Clear-Host
    
    Show-Menu -Option $input
    
    
    switch($env)
    {
        $prod    {Write-host ((" "*20)+"env: "+$envdesc[$env]+(" "*20)) -BackgroundColor red -ForegroundColor yellow }
        $staging {Write-host ((" "*20)+"env: "+$envdesc[$env]+(" "*20)) -BackgroundColor Yellow -ForegroundColor Black}
        $prodeu  {Write-host ((" "*20)+"env: "+$envdesc[$env]+(" "*20)) -BackgroundColor Magenta -ForegroundColor white}
        $qa      {Write-host ((" "*20)+"env: "+$envdesc[$env]+(" "*20)) -BackgroundColor Cyan -ForegroundColor black}
        default  {Write-host ((" "*20)+"env: "+$envdesc[$env]+(" "*20)) -BackgroundColor green -ForegroundColor black}
    }

    

    $input = Read-Host "Please make a selection"
    switch ($input)
    {
        0 {
            Clear-Host
            $FindIP = Read-Host "IP: "
            Find_IP -IP $FindIP
        }
        
        $export {            
            ExportServerList
        }

        #========= call master servers ==============
        ($MSllamadev+$deltaMaster) { RDP_MasterServer -Option $input }
        ($MSscg+$deltaMaster) { RDP_MasterServer -Option $input }
        ($MSprodeu+$deltaMaster) { RDP_MasterServer -Option $input }

        #======== Change environments ================
        ($dev+$deltaEnv) 
        {
            if ($env -ne $dev) 
            {
                $env=$dev
                $envFile = $MyRDCFolder+"\MyRDV"+$envdesc[$env]
                LoadServers
            }
        }

        ($qa+$deltaEnv) 
        {
            if ($env -ne $qa) 
            {
                $env=$qa
                $envFile = $MyRDCFolder+"\MyRDV"+$envdesc[$env]
                LoadServers
            }
        }

        ($staging+$deltaEnv) 
        {
            if ($env -ne $staging) 
            {
                $env=$staging
                $envFile = $MyRDCFolder+"\MyRDV"+$envdesc[$env]
                LoadServers
            }
        }

        ($prod+$deltaEnv) 
        {
            if ($env -ne $prod)
            {
                Write-Host ((" "*10)+"Your are about to enter PROD environment"+(" "*10)) -ForegroundColor Yellow -BackgroundColor Red
                $confirmation = Read-Host "Do you want to load PROD?  Y/N"
                if ($confirmation.ToString().ToUpper() -eq "Y")
                { 
                    $env=$prod
                    $envFile = $MyRDCFolder+"\MyRDV"+$envdesc[$env]
                    LoadServers
                }
            }
        }

        ($prodeu+$deltaEnv) 
        {
            if ($env -ne $prodeu) 
            {
                Write-Host ((" "*10)+"Your are about to enter PRODEU environment"+(" "*10)) -ForegroundColor Yellow -BackgroundColor DarkMagenta
                $confirmation = Read-Host "Do you want to load PRODEU?  Y/N"
                if ($confirmation.ToString().ToUpper() -eq "Y")
                { 
                    $env=$prodeu
                    $envFile = $MyRDCFolder+"\MyRDV"+$envdesc[$env]
                    LoadServers
                }
            }
        }

        #=========== replace file option ===============
        $replace {
            Format-swFile -SourceFilePath ($envFile+".dat") -Action "E" -LogFileFolder $MyRDCFolder
            Remove-Item ($envFile+".srv")
            Rename-Item ($envFile+".key") ($envFile+".srv")
            LoadServers
        }
        <#
        960 {
            OrderDATfile
        }
        #>

        $dnslist {
            ExportDNSList
            write-host ($envFile+".dat") -ForegroundColor Yellow -BackgroundColor Gray
            Start-Sleep -Seconds 3
        }

        $IPlist {
            ExportIPList
            write-host ($envFile+"_IP.txt") -ForegroundColor Yellow -BackgroundColor Gray
            Start-Sleep -Seconds 3
        }
 
        default 
        {

            if (($input -ge $deltaServers) -and (([Int]$input - $deltaServers) -le $ServerIP.Count))
            {
                $ServerOption = $input-$deltaServers

                $Server=$ServerIP[[int]$ServerOption]
                $User=""""+$ServerUsr[[int]$ServerOption]+""""
                $Password=$ServerPw[[int]$ServerOption]
                Write-Host ("Connecting to "+$ServerName[[int]$ServerOption]) -BackgroundColor Gray -ForegroundColor black
                Start-Sleep -Seconds 2

                cmdkey /generic:TERMSRV/$Server /user:$User /pass:$Password
                mstsc /v:$Server
                

            } else 
            {
                Write-Host ("         Invalid option. Try again...           ")  -BackgroundColor red -ForegroundColor white

                Start-Sleep -Seconds 3
            }

        } # default 
    } # switch
}
until ($input -lt 0)
