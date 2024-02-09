Clear-Host

$FSX_prod = "\\amznfsxqf9zdq6f.scg.guru\share\"
$FSX_prod_BAK02 = "\\amznfsxumd0wg1i.scg.guru\share\"
$FSX_prod_BAK01 = "\\amznfsxmd8zsrjo.scg.guru\share\"


$server_name = "I-0CC0CFB3D575D"
$Since       = "20220601"
$dbname      = ""
$from        = $FSX_prod
$to          = $FSX_prod_BAK01



#=======================================================
$FSxSource=$from
$destination=$to+"Backups\"+$server_name

$StartDate=[datetime]::parseexact($since, 'yyyyMMdd', $null)
$Types=@("FULL","DIFF","LOG")

while($StartDate -lt (Get-Date).AddDays(-1))
{
    for ($T=0;$T -le 2;$T++)
    {
        $since=$StartDate.ToString("yyyyMMdd")
    
        $Filter=$Types[$T]+"_"+$since+"*"+$dbname+".bak"

        $FullPath=$FSxSource+"Backups\"+$server_name+"\"+$Filter

        Write-Host("From "+$FullPath) -ForegroundColor Green
        Write-Host("To "+$destination) -ForegroundColor Yellow
        get-childitem -Path $FullPath  | Move-Item -Destination $destination
        Write-Host("Done "+$Types[$T]+" at "+$StartDate.ToString("yyyy-MM-dd")) -ForegroundColor Gray
    }

    $StartDate=$StartDate.AddDays(1)
}