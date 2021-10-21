variable "name" {}
variable "server_count" {}
variable "client_count" {}
variable "region" {}
variable "nomad_binary" {}
variable "ami" {}
variable "key_name" {}
variable "private_subnet_ids" {}
variable "public_subnet_ids" {}
variable "sg_primary_id" {}
variable "root_block_device_size" {}
variable "instance_profile" {}
variable "server_instance_type" {}
variable "client_instance_type" {}

variable "retry_join" {
  type = map(string)

  default = {
    provider  = "aws"
    tag_key   = "ConsulAutoJoin"
    tag_value = "auto-join"
  }
}

data "template_file" "user_data_server" {
  template = file("${path.root}/user-data-server.sh")

  vars = {
    server_count = var.server_count
    region       = var.region
    retry_join = chomp(
      join(
        " ",
        formatlist("%s=%s", keys(var.retry_join), values(var.retry_join)),
      ),
    )
    nomad_binary = var.nomad_binary
  }
}

data "template_file" "user_data_client" {
  template = file("${path.root}/user-data-client.sh")

  vars = {
    region = var.region
    retry_join = chomp(
      join(
        " ",
        formatlist("%s=%s ", keys(var.retry_join), values(var.retry_join)),
      ),
    )
    nomad_binary = var.nomad_binary
  }
}

resource "aws_instance" "server" {
  ami                    = var.ami
  instance_type          = var.server_instance_type
  key_name               = var.key_name
  subnet_id = "${element(var.private_subnet_ids, count.index)}"
  vpc_security_group_ids = [var.sg_primary_id]
  count                  = var.server_count

  # instance tags
  tags = merge(
    {
      "Name" = "${var.name}-server-${count.index}"
    },
    {
      "${var.retry_join.tag_key}" = "${var.retry_join.tag_value}"
    },
  )

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.root_block_device_size
    delete_on_termination = "true"
  }

  user_data            = data.template_file.user_data_server.rendered
  iam_instance_profile = var.instance_profile.name
}

resource "aws_instance" "client" {
  ami                    = var.ami
  instance_type          = var.client_instance_type
  key_name               = var.key_name
  subnet_id = "${element(var.private_subnet_ids, count.index)}"
  vpc_security_group_ids = [var.sg_primary_id]
  count                  = var.client_count
  depends_on             = [aws_instance.server]

  # instance tags
  tags = merge(
    {
      "Name" = "${var.name}-client-${count.index}"
    },
    {
      "${var.retry_join.tag_key}" = "${var.retry_join.tag_value}"
    },
  )

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.root_block_device_size
    delete_on_termination = "true"
  }

  ebs_block_device {
    device_name           = "/dev/xvdd"
    volume_type           = "gp2"
    volume_size           = "50"
    delete_on_termination = "true"
  }

  user_data            = data.template_file.user_data_client.rendered
  iam_instance_profile = var.instance_profile.name
}

resource "aws_instance" "bastion" {
  ami = "ami-0194c3e07668a7e36" # ubuntu 16
  instance_type = "t2.micro"
  key_name = var.key_name
  subnet_id = "${element(var.public_subnet_ids, count.index)}"
  vpc_security_group_ids = [var.sg_primary_id]
  count = var.server_count

  tags = {
    Name = "bastion-${count.index}"
  }
}
