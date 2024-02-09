cls
#we specify the directory where all files that we want to upload  
$Dir="D:\BarloworldSCS\ITOperations\SmartLLama\LLamaEyes\Data"    
 
#ftp server 
$ftp = "ftp://217.33.166.82:5000/"
$user = "myuser" 
$pass = "Cherry123!"  
 
$webclient = New-Object System.Net.WebClient 
 
$webclient.Credentials = New-Object System.Net.NetworkCredential($user,$pass)  
 
#list every sql server trace file 
foreach($item in (dir $Dir "*.*")){ 
    "Uploading $item..." 
    $uri = New-Object System.Uri($ftp+$item.Name) 
    $webclient.UploadFile($uri, $item.FullName) 
 } 