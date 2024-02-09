#  Use this script to upload records into a dataset collection in the LLamasoft cloud. 


#  The following section contains variables necessary to run the script. 
#-------------------------------------------------------------------

#  Type your API key here.
$API_KEY = ""

#  Type the name of the dataset here.
$DATASET_NAME = ""

#  Type the name of the collection here.
$COLLECTION_NAME = ""

#  If you want to sort the records by an attribute in the collection, type the name of the attribute here. If you don't specify an attribute to sort by, the default sort order is the key attribute.
$SORT_BY = ""

#  If you want to change the sort direction of the records to ascending or descending order, specify "asc" or "desc" here. The default is ascending order.
$SORT_DIRECTION = "asc"

#  Type the name of the CSV file you want to save with the downloaded records. 
$DOWNLOAD_FILE = "./downloaded_records.csv"

#-------------------------------------------------------------------


#  The following section contains lines of script necessary for the API to connect to the LLamasoft cloud. Do not modify this section.
#-------------------------------------------------------------------

#  This line specifies to run the script using the Tls12 security protocol type. 
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#  This line defines the API path.
$API_PATH = "https://api.llama.ai/"

#  This line defines the endpoint URI.
$ENDPOINT_URI = "v1/dataset/name/$DATASET_NAME/collection/$COLLECTION_NAME/record"

#  This line specifies the query parameters.

$PARAMETERS = "?sortBy=$SORT_BY" + "&sortDirection=$SORT_DIRECTION"



# These lines define the headers used in the HTTP request and execute the API request.

Write-Host "Retrieving records..."

$headers = @{
    'X-API-Key' = $API_KEY
}

# This line constructs the full URL required to access the endpoint. 
$DOWNLOAD_RECORDS_URL = $API_PATH + $ENDPOINT_URI + $PARAMETERS

$items = @()

$pageIndex = 1
$hasNextPage = $true
While ($hasNextPage) {
    $query = @{
        'pageIndex' = $pageIndex
        'pageSize' = '4000'
    }
    $download_response = Invoke-WebRequest $DOWNLOAD_RECORDS_URL -method get -headers $headers -body $query | ConvertFrom-Json
    $items = $items + $download_response.items
    $hasNextPage = $download_response.hasNextPage
    $pageIndex = $pageIndex + 1
}
if ($download_response.StatusCode -eq 200)
{
    Write-Host "Downloaded the records from the $COLLECTION_NAME collection in the $DATASET_NAME dataset to the $DOWNLOAD_FILE file successfully."
}
$items | Export-CSV $DOWNLOAD_FILE -NoTypeInformation

# This line creates a small delay to provide enough time for the transaction to complete successfully.
Start-Sleep -Seconds 5

# These lines check for the response indicating success and if the status code is returned display a message.


#-------------------------------------------------------------------
