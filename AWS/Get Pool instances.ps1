Set-AWSCredential -AccessKey  -SecretKey 
#$region = "eu-central-1"
$region = "us-east-1"

$outputFile = "C:\Users\sandoval.castroneto\Documents\PowerShell\MyRDC\MyRDC_AWS\Poolnodes.txt"

if (Test-Path -Path $outputFile)
{
    Remove-Item -Path $outputFile
}

Clear-Host
Write-Host $outputFile
Write-Host ("Searching instances in "+$region+" ...")
$username=""
$password=""
$nodes = (Get-EC2Instance -Region $region).Instances

foreach($node in $nodes)
{
    $nodedetails = ($node | select InstanceId, InstanceType, PrivateIpAddress)
    
    $tag_name = $node | select -ExpandProperty tag | ?{$_.Key -eq "Name"}
    if ($tag_name.Value -like "*pool*")
    {
        
        Add-Content -Path $outputFile -Value $tag_name.Value
        Add-Content -Path $outputFile -Value $nodedetails.PrivateIpAddress
        Add-Content -Path $outputFile -Value $username
        Add-Content -Path $outputFile -Value $password
        
        write-host ($tag_name.Value+" - "+$nodedetails.PrivateIpAddress) -ForegroundColor Yellow
        <#
        $nodedetails.InstanceId     
        $nodedetails.InstanceType.Value
        $nodedetails.PrivateIpAddress
        #>
    }
}

