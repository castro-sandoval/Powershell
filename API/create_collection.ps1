#  Use this script to add a collection to a dataset in the LLamasoft cloud. 


#  The following section contains variables necessary to run the script. Type the value you want to specify between the empty set of quotes.
#-------------------------------------------------------------------

#  Type your API key here.
$API_KEY = ""

#  Type the name of the dataset here.
$DATASET_NAME = ""

#  Type the name of the collection here.
$COLLECTION_NAME = ""

#  Type the names and properties of the collection attributes (table columns) here. One column must have the "isKey" property set to "true". This column will be the key column. The attribute values below match the column names in the sample "records.csv" file. 
$COLLECTION_ATTRIBUTES = @{
    attributes = @(
    @{
        name="orderId";
        type="int";
        isKey="true"
    },
    @{
        name="orderCategory";
        type="string";
        isKey="false"
    },
    @{
        name="orderProduct";
        type="string";
        isKey="false"
    },
    @{
        name="orderQuantity";
        type="int";
        isKey="false"
    },
    @{
        name="OrderDate";
        type="string";
        isKey="false"
    }
    )
}

#-------------------------------------------------------------------


#  The following section contains lines of script necessary for the API to connect to the LLamasoft cloud. Do not modify this section.
#-------------------------------------------------------------------

#  This line specifies to run the script using the Tls12 security protocol type. 
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#  This line defines the API path.
$API_PATH = "https://api.llama.ai/"

#  This line defines the endpoint URI.
$ENDPOINT_URI = "v1/dataset/name/$DATASET_NAME/collection/$COLLECTION_NAME"

# This line constructs the full URL required to access the endpoint. 
$CREATE_COLLECTION_URL = $API_PATH + $ENDPOINT_URI

# This line specifies to convert the collection attribute values to the JSON format. 
$JSON = $COLLECTION_ATTRIBUTES | ConvertTo-Json

# These lines define the headers used in the HTTP request: the API key and the content type of the body.
$headers = @{    
     'X-API-Key' = $API_KEY
    }
$headers.Add("Content-Type", "application/json")

# These lines execute the API request.
Write-Host "Creating collection $COLLECTION_NAME in dataset $DATASET_NAME..."
$create_response = Invoke-WebRequest $CREATE_COLLECTION_URL -Method Post -Headers $headers -Body $JSON

# This line creates a small delay to provide enough time for the transaction to complete successfully.
Start-Sleep -Seconds 5

# These lines check for the response indicating success and if the status code is returned display a message.
if ($create_response.StatusCode -eq 201)
{
    Write-Host "Created the $COLLECTION_NAME collection in the $DATASET_NAME dataset successfully."
}

#-------------------------------------------------------------------
