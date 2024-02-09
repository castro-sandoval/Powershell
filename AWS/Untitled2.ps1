Get-AWSCmdletName -Service S3


$WriteProps = @{
    'BucketName' = 'my-test-bucket'    # S3 Bucket Name
    'Key'        = 'my-s3-file.log'    # Key used to identify the S3 Object
    'File'       = 'C:\my-s3-file.log' # Local File to upload
    'Region'     = 'us-east-1'         # AWS Region
    'AccessKey'  = 'MY_AWS_ACCESS_KEY' # AWS Account Access Key
    'SecretKey'  = 'MY_AWS_SECRET_KEY' # AWS Account Secret Key
}

