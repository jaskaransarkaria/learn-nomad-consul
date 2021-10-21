output "server_private_ip" {
  value = module.ec2.server_private_ip
}

output "client_private_ip" {
  value = module.ec2.client_private_ip
}

output "bastion_ips" {
  value = module.ec2.bastion_ips
}

output "public_subnets_cidr" {
  value = local.public_subnets_cidr
}

output "private_subnets_cidr" {
  value = local.private_subnets_cidr
}

output "server_lb_ip" {
  value = module.alb.server_lb_ip
}

