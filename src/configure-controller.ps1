function make-controller () {
    # create vm
    multipass.exe launch -n controller --bridged --cloud-init .\cloud-init-controller.yaml # -m 128M

    # add ssh key pair
    multipass.exe exec controller "ssh-keygen"
}

function make-cloudinit () {
    $cloudinit_path = "./cloud-init.yaml"
    # create cloud-init file
    New-Item -Path $cloudinit_path

    $cloud_init_content = @"
#cloud-config
ssh_authorized_keys:
  - $(multipass.exe exec controller -- "cat" "/home/ubuntu/.ssh/id_rsa.pub")
"@

    # add content to file along
    Add-Content -Path $cloudinit_path -Value $cloud_init_content

}

function make-server ($server_ip) {
    # launch server
    multipass.exe launch -n server --bridged -m 3G --cloud-init .\cloud-init.yaml

    # retrieve ip of server
    $mps = multipass.exe list --format json | ConvertFrom-Json

    $server_ip = $mps.list | Where-Object {$_.name -eq "server"} |
    Select-Object -Property ipv4

    # install k3s server
    multipass.exe exec controller -- "k3sup" "install" "--ip" "$($server_ip.ipv4[0])" "--user" "ubuntu" "--k3s-extra-args" "--advertise-address=$($($server_ip.ipv4[0]))"

}

# agents need to already be setup for ssh to controller, these could be RPIs or another computer
function configure-agent ($agent_ip) {

    # retrieve ip of server
    $mps = multipass.exe list --format json | ConvertFrom-Json

    $server_ip = $mps.list | Where-Object {$_.name -eq "server"} |
    Select-Object -Property ipv4
    
    # configure agent
    ## need to get the user & ip config
    multipass.exe exec controller -- "k3sup" "join" "--server-ip" "$($server_ip.ipv4[0])" "--user" "ubuntu" "--ip" "$($agent_ip)"

}