output "server_lb_ip" {
  value = aws_lb.servers.*.dns_name
}

