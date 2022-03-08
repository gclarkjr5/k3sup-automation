
function uninstall-k3sup-general ($obj) {

    # configure command
    $type = if ($obj.type -eq "agent") {"$($obj.type)-"}
    elseif ($obj.type -eq "server") {''}
    else {Write-Error "Unkown node type passed $($obj.type)"}

    $command = "sudo /usr/local/bin/k3s-$($type)uninstall.sh"

    ssh "$($obj.root_user)@$($obj.ip)" $command

}


function install-k3sup-server ($server, $controller) {

    $extra_args = "'--node-external-ip=$($server.ip) --node-ip=$($server.ip)'"
    $command =  "k3sup install --ip $($server.ip) --user $($server.root_user) --k3s-extra-args $($extra_args)"
    
    ssh "$($controller.root_user)@$($controller.ip)" $command

}

function install-k3sup-agent ($agent, $controller, $server) {

    $command = "k3sup join --server-ip $($server.ip) --server-user $($server.root_user) --user $($agent.root_user) --ip $($agent.ip)"
    
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
    $obj | Where-Object {$_.type -in "agent", "server"} | ForEach-Object {uninstall-k3sup-general $_}
}

function reset-k3sup ($obj) {
    uninstall-k3sup $obj
    Start-Sleep -S 3
    install-k3sup $obj
}