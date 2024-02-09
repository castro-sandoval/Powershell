

#=======================================================================================
$BaseFolder = "C:\temp\"
$MyHTMLFile = $BaseFolder+"MyFile.html"

$BaseFolder = "C:\Temp\AppDB\DGE\ConfigurationManager\*.*"
$Image1 = "C:\Users\sandoval.castroneto\Pictures\LLamasoftLogo.jpg"
#=======================================================================================
   if (Test-Path -Path $MyHTMLFile) {
        Remove-Item -Path $MyHTMLFile -Force
    }


#======================================================================================
Add-Content -Path $MyHTMLFile -Value ("<HTML>")
Add-Content -Path $MyHTMLFile -Value ("<form action=""http://"+$ResultHTMLFile+""" method=""post"">")
Add-Content -Path $MyHTMLFile -Value ("<TITLE>"+"My ps1 script output"+"</TITLE>")

Add-Content -Path $MyHTMLFile -Value ("<p><image src="""+$Image1+""" height=25 width=100></image></p>")

Add-Content -Path $MyHTMLFile -Value ("<H3>"+"Listing files from a folder from my PowerShell script"+"</H3>")
Add-Content -Path $MyHTMLFile -Value ("<BODY>")
Add-Content -Path $MyHTMLFile -Value ("<TABLE border=1 width=500>")

Add-Content -Path $MyHTMLFile -Value ("<thead bgcolor=silver><tr><th>Files from "+$BaseFolder+"</th></tr></thead>")
Add-Content -Path $MyHTMLFile -Value ("<tbody>")

Add-Content -Path $MyHTMLFile -Value ("<p>List files from: <input type=""text"" id=""BaseFolder"" name=""BaseFolder"" size=100 maxlength=""100"" minlength=""3"" value="""+$BaseFolder+""" required /></p>")


$files = Get-ChildItem -Path $BaseFolder


foreach($file in $files) {
    Add-Content -Path $MyHTMLFile -Value ("<tr><td>"+$file.name+"</td></tr>")
}
Add-Content -Path $MyHTMLFile -Value ("</tbody>")

Add-Content -Path $MyHTMLFile -Value ("<tfoot bgcolor=silver><tr><td align=center>"+$files.Length.ToString()+" files found.</td></tr></tfoot>")

Add-Content -Path $MyHTMLFile -Value ("</TABLE>")
Add-Content -Path $MyHTMLFile -Value ("</BODY>")
Add-Content -Path $MyHTMLFile -Value ("<p><button name=""submit"" type=""submit"" value=""submit-true"">List files</button></p>")
Add-Content -Path $MyHTMLFile -Value ("</HTML>")
