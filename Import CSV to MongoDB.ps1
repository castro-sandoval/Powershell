<#
    .NOTES
    You'll need the excellent C# driver: http://docs.mongodb.org/ecosystem/drivers/csharp/
#>
Add-Type -Path "c:\mongodb\bin\MongoDB.Bson.dll"
Add-Type -Path "c:\mongodb\bin\MongoDB.Driver.dll"

Function Import-CsvToMongo{
    param($path, $dbUrl, $collection, $matchCol) #matchCol is used as a lookup to check if entry is to be added or updated

    $db = [MongoDB.Driver.MongoDatabase]::Create($dbUrl)
    $collection = $db[$collection]
    $sort = [MongoDB.Driver.Builders.SortBy]::Null

    Import-Csv $path | % {
        $q = [MongoDB.Driver.QueryDocument] @{ $matchCol = $_.$matchCol}
        $update = New-Object MongoDB.Driver.Builders.UpdateBuilder
        $i = $_
        $i | Get-Member -MemberType NoteProperty | % {
            $update.Set($_.Name, [MongoDB.Bson.BsonValue] $i.$($_.Name)) | out-null
        }

        $collection.FindAndModify($q, $sort, $update, $true, $true)
    }
}

# Example call
<#
Import-CsvToMongo -path "C:\myfile.csv" `
    -dbUrl "mongodb://localhost/trumptown?safe=true;slaveok=true" `
    -collection "core" `
    -matchCol "id"
#>