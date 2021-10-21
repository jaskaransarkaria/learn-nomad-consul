output "ec2_servers" {
  value = aws_instance.server
}

output "server_private_ip" {
  value = aws_instance.server.*.private_ip
}

output "client_private_ip" {
  value = aws_instance.client.*.private_ip
}

output "bastion_ips" {
  value = aws_instance.bastion.*.public_ip
}

