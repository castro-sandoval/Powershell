#  Use this script to upload records into a dataset collection in the LLamasoft cloud. 


#  The following section contains variables necessary to run the script. 
#-------------------------------------------------------------------

#  Type your API key here.
$API_KEY = ""

#  Type the name of the dataset here.
$DATASET_NAME = ""

#  Type the name of the collection here.
$COLLECTION_NAME = ""

#  Type the name of the CSV file containing the records and the path to the file's location. 
$CSVFILEPATH = "./records.csv"

#-------------------------------------------------------------------


#  The following section contains lines of script necessary for the API to connect to the LLamasoft cloud. Do not modify this section.
#-------------------------------------------------------------------

#  This line specifies to run the script using the Tls12 security protocol type. 
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#  This line defines the API path.
$API_PATH = "https://api.llama.ai/"

#  This line defines the endpoint URI.
$ENDPOINT_URI = "v1/dataset/name/$DATASET_NAME/collection/$COLLECTION_NAME/record"

# This line constructs the full URL required to access the endpoint. 
$UPLOAD_COLLECTION_URL = $API_PATH + $ENDPOINT_URI

# These lines define the headers used in the HTTP request: the API key and the content type of the body.
$headers = @{    
     'X-API-Key' = $API_KEY
    }
$headers.Add("Content-Type", "application/json")

# These lines specify to covert the records from the CSV file to the JSON format. 
Write-Host "Reading data from CSV file..."
$JSON = Import-Csv -Path "$CSVFILEPATH" | ConvertTo-Json -Compress | Foreach {$_ -creplace '"NULL"','null' -replace ':"([0-9]+)"',':$1'}

# These lines execute the API request.
Write-Host "Uploading data to cloud..."
$upload_response = Invoke-WebRequest $UPLOAD_COLLECTION_URL -Method Patch -Headers $headers -Body $JSON

# This line creates a small delay to provide enough time for the transaction to complete successfully.
Start-Sleep -Seconds 5

# These lines check for the response indicating success and if the status code is returned display a message.
if ($upload_response.StatusCode -eq 202)
{
    Write-Host "Uploaded the records from the $CSVFILEPATH file to the $COLLECTION_NAME collection in the $DATASET_NAME dataset successfully."
}

#-------------------------------------------------------------------
