output "IP_Addresses" {
  value = <<CONFIGURATION

Client public IPs: ${join(", ", module.ec2.client_private_ip)}

Server public IPs: ${join(", ", module.ec2.server_private_ip)}

To connect, add your private key and SSH into any client or server with
`ssh ubuntu@PUBLIC_IP`. You can test the integrity of the cluster by running:

  $ consul members
  $ nomad server members
  $ nomad node status

If you see an error message like the following when running any of the above
commands, it usually indicates that the configuration script has not finished
executing:

"Error querying servers: Get http://127.0.0.1:4646/v1/agent/members: dial tcp
127.0.0.1:4646: getsockopt: connection refused"

Simply wait a few seconds and rerun the command if this occurs.

The Nomad UI can be accessed at http://${module.alb.server_lb_ip[0]}:4646/ui.
The Consul UI can be accessed at http://${module.alb.server_lb_ip[0]}:8500/ui.

Set the following for access from the Nomad CLI:

  export NOMAD_ADDR=http://${module.alb.server_lb_ip[0]}:4646

CONFIGURATION

}

resource "local_file" "client_and_server_addresses" {
  content = <<EOT
[servers]
${join("\n",formatlist("%s ansible_connection=ssh", module.ec2.server_private_ip))}

[servers:vars]
ansible_ssh_common_args = "-F ./ssh.cfg"

[clients]
${join("\n",formatlist("%s ansible_connection=ssh", module.ec2.client_private_ip))}

[clients:vars]
ansible_ssh_common_args = "-F ./ssh.cfg"

EOT

  filename = "../ansible/ansible.cfg"
}

resource "local_file" "ssh_config" {
  content = <<EOT
Host ${replace(local.private_subnets_cidr[0], "0/24", "*")}
  ProxyJump bastion-0
  IdentityFile ${var.key_location}
  StrictHostKeyChecking accept-new
  User ubuntu

Host ${replace(local.private_subnets_cidr[1], "0/24", "*")}
  ProxyJump bastion-1
  IdentityFile ${var.key_location}
  StrictHostKeyChecking accept-new
  User ubuntu

Host ${replace(local.private_subnets_cidr[2], "0/24", "*")}
  ProxyJump bastion-2
  IdentityFile ${var.key_location}
  StrictHostKeyChecking accept-new
  User ubuntu

Host bastion-0
  Hostname ${module.ec2.bastion_ips[0]}
  User ubuntu
  IdentityFile ${var.key_location}
  ControlMaster auto
  ControlPath ~/.ssh/ansible-%r@%h:%p
  ControlPersist 5m
  StrictHostKeyChecking accept-new

Host bastion-1
  Hostname  ${module.ec2.bastion_ips[1]}
  User ubuntu
  IdentityFile ${var.key_location}
  ControlMaster auto
  ControlPath ~/.ssh/ansible-%r@%h:%p
  ControlPersist 5m
  StrictHostKeyChecking accept-new

Host bastion-2
  Hostname  ${module.ec2.bastion_ips[2]}
  User ubuntu
  IdentityFile ${var.key_location} 
  ControlMaster auto
  ControlPath ~/.ssh/ansible-%r@%h:%p
  ControlPersist 5m
  StrictHostKeyChecking accept-new

EOT

filename = "../ansible/ssh.cfg" 
}
