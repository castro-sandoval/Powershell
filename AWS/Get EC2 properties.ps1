$query="delete from [Targets].[EC2Properties]"
Invoke-Sqlcmd -ServerInstance "." -Username "" -Password "" -Database "DATAOPS" -Query $query

<#===========================================================================================================================
        Fill table with one row per target to make sure all targets are in the table
===========================================================================================================================#>
$query="INSERT INTO [Targets].[EC2Properties]([server_id]) SELECT server_id from [Targets].[Instances]"
Invoke-Sqlcmd -ServerInstance "." -Username "" -Password "" -Database "DATAOPS" -Query $query

<#===========================================================================================================================
         Fill details for each EC2
===========================================================================================================================#>
$query="SELECT [server_id], [tag_IP], [AWS_account] FROM [Targets].[Instances] where [AWS_account]='066'"
$Targets = Invoke-Sqlcmd -ServerInstance "." -Username "" -Password "" -Database "DATAOPS" -Query $query

foreach($Target in $Targets)
{
    if ($Target.AWS_account -eq "066")
    {
        $AccessKey="AKIAIK6ODY2F7MFNUVBQ"
        $SecretKey="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"
    }
    else
    {
        $AccessKey=""
        $SecretKey=""
    }
    
    $instance=(Get-EC2Instance -AccessKey $AccessKey -SecretKey $SecretKey -Region "us-east-1" -Filter @{Name="network-interface.addresses.private-ip-address";Value=$Target.tag_IP}).Instances
    
    $query="UPDATE [Targets].[EC2Properties] SET [updated_on]=GETDATE(), [InstanceId]='"+$instance[0].InstanceId.ToString()+"',[InstanceType]='"+$instance[0].InstanceType.Value.ToString()+"',[AMIId]='"+$instance[0].ImageId.ToString()+"',[Launch_time]='"+$instance[0].LaunchTime.ToString("yyyy-MM-dd HH:mm:ss")+"',[Tag_name]='"+($instance[0].Tag  | Where-Object {$_.key -eq "Name"} | select -Property Value).value+"'"
    $query=$query+"WHERE [server_id]="+$Target.server_id.ToString()
    Invoke-Sqlcmd -ServerInstance "." -Username "" -Password "" -Database "DATAOPS" -Query $query
}

