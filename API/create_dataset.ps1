#  Use this script to create a empty dataset for use with the llama.ai Quick Start Tutorial.


#  The following section contains variables necessary to run the script. Type the value you want to specify between the empty set of quotes.
#-------------------------------------------------------------------

#  Type your API key here.
$API_KEY = ""

#  Type the name of the dataset here.
$DATASET_NAME = ""

#-------------------------------------------------------------------


#  The following section contains lines of script necessary for the API to connect to the LLamasoft cloud. Do not modify this section.
#-------------------------------------------------------------------

#  This line specifies to run the script using the Tls12 security protocol type. 
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#  This line defines the API path.
$API_PATH = "https://api.llama.ai/"

#  This line defines the endpoint URI.
$ENDPOINT_URI = "v1/dataset/$DATASET_NAME"

# This line constructs the full URL required to access the endpoint. 
$CREATE_DATASET_URL = $API_PATH + $ENDPOINT_URI

# These lines define the headers used in the HTTP request: the API key and the content type of the body.
$headers = @{    
     'X-API-Key' = $API_KEY
    }
$headers.Add("Content-Type", "application/json")

# These lines execute the API request.
Write-Host "Creating dataset $DATASET_NAME..."
$create_response = Invoke-WebRequest $CREATE_DATASET_URL -Method Post -Headers $headers

# This line creates a small delay to provide enough time for the transaction to complete successfully.
Start-Sleep -Seconds 5

# These lines check for the response indicating success and if the status code is returned display a message.
if ($create_response.StatusCode -eq 202)
{
    Write-Host "Created the $DATASET_NAME dataset successfully."
}

#-------------------------------------------------------------------