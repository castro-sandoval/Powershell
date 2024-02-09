
Clear-Host

Set-AWSCredentials -AccessKey  -SecretKey 

$interval = New-Object Amazon.CostExplorer.Model.DateInterval
$interval.Start = "2020-09-09"
$interval.End = "2020-09-11" #(Get-Date).ToString("yyyy-MM-ddThh:mm:ssZ")


#=========== Dimension ================
$dimension = New-Object Amazon.CostExplorer.Model.DimensionValues
$dimension.Key = "SERVICE"
$dimension.Values ="Amazon Elastic Compute Cloud - Compute"

$Filter = New-Object Amazon.CostExplorer.Model.Expression
$Filter.Dimensions = $dimension



$groupInfo = New-Object Amazon.CostExplorer.Model.GroupDefinition
$groupInfo.Type = "TAG"

<#
AZ, INSTANCE_TYPE, LINKED_ACCOUNT, OPERATION, PURCHASE_TYPE, SERVICE, 
USAGE_TYPE, PLATFORM, TENANCY, RECORD_TYPE, LEGAL_ENTITY_NAME, 
DEPLOYMENT_OPTION, DATABASE_ENGINE, CACHE_ENGINE, INSTANCE_TYPE_FAMILY, 
REGION, BILLING_ENTITY, RESERVATION_ID, SAVINGS_PLANS_TYPE, SAVINGS_PLAN_ARN, 
OPERATING_SYSTEM
#>
$groupInfo.Key = "Name"


#$metric = @("BlendedCost","UsageQuantity")
$metric = @("BlendedCost")


# BLENDED_COST, UNBLENDED_COST, AMORTIZED_COST, NET_AMORTIZED_COST, NET_UNBLENDED_COST, USAGE_QUANTITY, NORMALIZED_USAGE_AMOUNT
$costUsage = Get-CECostAndUsage -TimePeriod $interval -Granularity DAILY -Metric $metric -GroupBy $groupInfo
$results = $costUsage.ResultsByTime
foreach($result in $results)
{
    ($result.Groups[0].Metrics.Values[0]).Unit+" "+ ($result.Groups[0].Metrics.Values[0]).Amount
    
}




