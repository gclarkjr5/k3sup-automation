function Write-Log {
    param (
        [Parameter(ValueFromPipeline=$true)]
        $LogString
    )
    
    $Logfile = "$($PSScriptRoot)\..\log.log"
    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $LogMessage = "$($Stamp): $($LogString)"
    Add-Content $LogFile -value $LogMessage
}

function uninstall-k3sup-general ($obj, $controller) {

    # configure command
    $type = if ($obj.type -eq "agent") {"$($obj.type)-"}
    elseif ($obj.type -eq "server") {''}
    else {Write-Error "Unkown node type passed $($obj.type)"; exit}

    $command = "sudo /usr/local/bin/k3s-$($type)uninstall.sh"

    Write-Log "Uninstalling $($obj.type) -- ssh $($obj.root_user)@$($obj.ip) $($command)"

    $inner_command = "ssh $($obj.root_user)@$($obj.ip) $($command)"

    ssh "$($controller.root_user)@$($controller.ip)" $inner_command

}


function install-k3sup-server ($server, $controller) {
    
    $extra_args = "'--node-external-ip=$($server.ip) --node-ip=$($server.ip)'"
    $command =  "k3sup install --ip $($server.ip) --user $($server.root_user) --k3s-extra-args $($extra_args)"
    
    Write-Log "Installing server -- ssh  $($controller.root_user)@$($controller.ip) $($command)"
    ssh "$($controller.root_user)@$($controller.ip)" $command

}

function install-k3sup-agent ($agent, $controller, $server) {

    ## TODO:    pass through all arguments of k3sup to use them at the command line

    $command = "k3sup join --server-ip $($server.ip) --server-user $($server.root_user) --user $($agent.root_user) --ip $($agent.ip)"
    
    Write-Log "Installing agent -- ssh $($controller.root_user)@$($controller.ip) $($command)"
    ssh "$($controller.root_user)@$($controller.ip)" $command

}


# Install k3sup
function install-k3sup ($obj) {
    
    $controller = $obj | Where-Object {$_.type -eq "controller"}
    $server = $obj | Where-Object {$_.type -eq "server"}

    $server | ForEach-Object {install-k3sup-server $_ $controller}
    $obj | Where-Object {$_.type -eq "agent"} | ForEach-Object {install-k3sup-agent $_ $controller $server}

}

# Uninstall k3sup
function uninstall-k3sup ($obj) {
    
    $controller = $obj | Where-Object {$_.type -eq "controller"}
    $obj | Where-Object {$_.type -in "agent", "server"} | ForEach-Object {uninstall-k3sup-general $_ $controller}

}

function reset-k3sup ($obj) {
    uninstall-k3sup $obj
    Start-Sleep -S 3
    install-k3sup $obj
}