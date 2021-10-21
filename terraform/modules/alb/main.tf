variable "server_lb_sg_id" {}
variable "subnet_ids" {}
variable "vpc_id" {}
variable "ec2_instances" {}

# ALB
resource "aws_lb" "servers" {
  name               = "nomad-consul-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.server_lb_sg_id]
  subnets            = var.subnet_ids
}

# Target group for the web servers
resource "aws_lb_target_group" "nomad_servers" {
  name     = "nomad-servers-tg"
  port     = 4646
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

# Consul server target group
resource "aws_lb_target_group" "consul_servers" {
  name     = "consul-servers-tg"
  port     = 8500
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

# ALB listener for nomad
resource "aws_lb_listener" "nomad_lb" {
  load_balancer_arn = aws_lb.servers.arn
  port              = "4646"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nomad_servers.arn
  }
}

# ALB listener for consul
resource "aws_lb_listener" "consul_lb" {
  load_balancer_arn = aws_lb.servers.arn
  port              = "8500"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.consul_servers.arn
  }
}

# Find the consul target group
data "aws_lb_target_group" "find_consul_servers" {
  name = "consul-servers-tg"
  depends_on = [
    aws_lb_target_group.consul_servers,
  ]
}

# Attach an EC2 instance to the target group on port 8500
resource "aws_lb_target_group_attachment" "consul" {
  count = 3
  target_group_arn = data.aws_lb_target_group.find_consul_servers.arn
  target_id        = "${element(var.ec2_instances.*.id, count.index)}"
  port             = 8500
}

# Find the nomad target group
data "aws_lb_target_group" "find_nomad_servers" {
  name = "nomad-servers-tg"
  depends_on = [
    aws_lb_target_group.nomad_servers
  ]
}

# Attach an EC2 instance to the target group on port 4646
resource "aws_lb_target_group_attachment" "nomad" {
  count = 3
  target_group_arn = data.aws_lb_target_group.find_nomad_servers.arn
  target_id        = "${element(var.ec2_instances.*.id, count.index)}"
  port             = 4646
}

