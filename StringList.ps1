$MyInList = New-Object System.Collections.Generic.List[string]
$MyInList.Add('one')
$MyInList.Add('two')
$MyInList.Add('three')
$MyInList

#=================================================================================

$MyInList = New-Object System.Collections.Generic.List[string]
[string[]]$a = 'one','two','three'
$MyInList.AddRange($a)
$MyInList

#=================================================================================

foreach($s in $MyInList){$s}

#=================================================================================

for($i=0;$i -lt $MyInList.Count;$i++){$MyInList[$i]}

