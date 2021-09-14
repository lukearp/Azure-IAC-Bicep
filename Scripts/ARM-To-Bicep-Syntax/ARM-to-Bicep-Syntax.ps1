param (
    $path,
    $scope
)
$armTemplate = Get-Content -Path $path
$newArray = @()
foreach($line in $armTemplate)
{
    $beforeColon = $line.Split(':')[0]
    $afterColon = $line.Split(':')[1]
    if($null -ne $afterColon)
    {
        if($afterColon -like "*https")
        {
            $afterNoQuotes = "'https://" + $line.Split("https://")[1].Replace("'","\'").Replace("`"","'") -replace "(,$)",""
        } elseif ($afterColon -like "*http") 
        {
            $afterNoQuotes = "'http://" + $line.Split("https://")[1].Replace("'","\'").Replace("`"","'") -replace "(,$)",""
        }
        else {
            $afterNoQuotes = $afterColon.Replace("'","\'").Replace("`"","'") -replace "(,$)",""
        }
    }
    if($beforeColon.Contains("`""))
    {
        $beforeNoQuotes = $beforeColon.Replace("`"","")
        if($beforeNoQuotes -like "*schema*")
        {
            $beforeNoQuotes = "`'`$schema`'"
        }
    }
    if($line.Contains("`": "))
    {
        $newArray += $beforeNoQuotes + ": " + $afterNoQuotes
    }
    else {
        $newArray += $line.Replace("'","\'").Replace("`"","'") -replace "(,$)",""
    }
}

$bicepModule = @'
targetScope = '{1}'
var template = {0}
output templateObj object = template
'@

$bicepModule -f $($newArray -join "`n"), $scope | Out-File gen.bicep 