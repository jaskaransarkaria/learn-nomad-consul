output "sg_primary_id" {
  value = aws_security_group.primary.id 
}

output "sg_server_lb_id" {
  value = aws_security_group.server_lb.id
}
