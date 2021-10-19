# Learn Nomad and Consul

[Nomad](https://www.nomadproject.io/) is a simple and flexible workload orchestrator to deploy and manage containers \
and non-containerized applications across on-prem and clouds at scale.

[Consul](https://www.consul.io/) is a service Mesh for any runtime or cloud. Consul automates networking for simple \
and secure application delivery.

## Prerequisites

- terraform
- ansible
- ssh keys
- packer (optional)

## How it works

1. Export your AWS profile
2. Create and fill out a `terraform.tfvars` in the `terraform/` dir (cross reference `variables.tf`, \
it's advised to spin up 3 servers and at least 1 client)
3. In `terraform/` run `terraform init`
4. In ansible `chmod +x  ./init-agents.sh`
5. In the root dir of the the repo `chmod +x ./create-cluster.sh`
6. `./create-cluster.sh`

This will spin up a nomad and consul cluster, with the consul and nomad servers on the same instance. Consul is span \
up first and is responsible for service discorvery. Nomad then spins up and uses consul to find the other servers.

When it comes to specifying an ami, it is recommended to use packer to create a base image which contains the latest \
versions of nomad and consul. You can use a public ami however it contains quite old versions of nomad and consul \
baked in. Follow these steps to create your own base image (with your AWS credentials exported):

a. `cd packer`
b. `packer init .`
c. `packer build aws-ubuntu.pkr`

After the ec2 instances are span up, then terraform outputs to the server and clients public ips to `ansible.cfg` in \
the `ansible/` dir. Ansible configures the servers first with consul and then nomad (running them both as daemons).
Ansible then sets up the clients and installs docker so that we can run docker based jobs.

## Next steps

Deploy Fabio (a zero conf load balancer) and then deploy some containers! 

[Follow this tutorial](https://learn.hashicorp.com/tutorials/nomad/load-balancing-fabio?in=nomad/load-balancing)

## Todo

- [  ] - Rejig the VPC configuration to make it more production ready
- [  ] - integrate consul connect
- [  ] - research ACL
