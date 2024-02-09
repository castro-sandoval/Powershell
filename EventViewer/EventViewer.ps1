$dateLimit = Get-Date
$dateLimit = $dateLimit.AddHours(-6)
$ip=(get-WmiObject Win32_NetworkAdapterConfiguration | Where {($_.Ipaddress.length -gt 1)})
$instance=(Get-EC2Instance -Region $region -Filter @{Name="network-interface.addresses.private-ip-address";Value=$ip.IPAddress[0]}).Instances
$name = $instance.tag | Where-Object {$_.key -eq "Name"} | select -Property Value
$messages = Get-EventLog -LogName Application -After $dateLimit -EntryType Error,Warning | select -Property EventID, TimeGenerated, Message, Source | Where-Object {($_.Source -like "*SQL*")}


if (Test-Path -Path

if ($messages.Count -gt 0)
{

    ($name).Value
    $ip.ipaddress[0]

    foreach ($message in $messages) 
    {
      
      $INSERT = "INSERT INTO [DataOps].[EventViewer]([tag_name], [tag_IP], [EventID], [Source], [ServerTime], [Message]) VALUES ('"+$name.Value+"','"+$ip.ipaddress[0]+"',"+$message.EventID.ToString()+",'"+$message.Source.ToString()+"','"+$message.TimeGenerated.ToString("yyyy-MM-dd HH:mm:ss:nn")+"','"+($message.Message.ToString()).Replace("'","""")+"');"
      $INSERT

    }
}
else {
"no messages"
}
