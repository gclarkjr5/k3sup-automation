param (
    [String]
    $config_file
)

. $PSScriptRoot\src\k3sup-work.ps1

$obj = Get-Content -Path $config_file | ConvertFrom-Json

# Get the top level names of the json object
$types = $obj |
    Get-Member |
    Where-Object {$_.MemberType -eq 'NoteProperty'} | Select-Object Name

# Turn the json into a list
$config = $types.Name |
    ForEach-Object {
        $type = $_
        $obj.$_ | Select-Object *, @{l="type"; e={$type}}
    }

# test controller ssh connection
$ssh_test = $config |
    Where-Object {$_.type -eq "controller"} |
    ForEach-Object{Test-NetConnection -ComputerName $_.ip -Port 22}

# on any fails, exit and end program
$ssh_test |
    Where-Object {!$_.TcpTestSucceeded} |
    ForEach-Object{Write-Error "SSH not available on port 22 for $($_.ComputerName)"; exit}

reset-k3sup $config


