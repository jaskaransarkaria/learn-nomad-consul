packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  vpc_id = "vpc-0383b61088104b500"
  public_subnet_id = "subnet-01692ca41a0558ac5"
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "packer-ubuntu-18-nomad-consul-aws"
  instance_type = "t2.micro"
  region        = "eu-west-2"
  vpc_id = local.vpc_id
  subnet_id = local.public_subnet_id
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-bionic-18.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
}

build {
  name    = "learn-packer"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "shell" {
    environment_vars = [
      "CONSUL_VERSION=1.8.0",
      "CONSUL_URL=https://releases.hashicorp.com/consul",
      "NOMAD_VERSION=1.1.0",
      "DEBIAN_FRONTEND=noninteractive"
    ]
    inline = [
      "sudo apt-get update",
      "echo Installing Unzip",
      "sudo apt-get install -y unzip",
      "echo Installing Consul",
      "echo $CONSUL_URL/$CONSUL_VERSION/consul_\"$CONSUL_VERSION\"_linux_amd64.zip",
      "curl --remote-name $CONSUL_URL/$CONSUL_VERSION/consul_\"$CONSUL_VERSION\"_linux_amd64.zip",
      "curl --remote-name $CONSUL_URL/$CONSUL_VERSION/consul_\"$CONSUL_VERSION\"_SHA256SUMS",
      "curl --remote-name $CONSUL_URL/$CONSUL_VERSION/consul_\"$CONSUL_VERSION\"_SHA256SUMS.sig",
      "ls",
      "unzip consul_\"$CONSUL_VERSION\"_linux_amd64.zip",
      "sudo chown root:root consul",
      "sudo mv consul /usr/bin/",
      "consul --version",
      "sudo useradd --system --home /etc/consul.d --shell /bin/false consul",
      "sudo mkdir --parents /opt/consul",
      "sudo chown --recursive consul:consul /opt/consul",
      "echo Installing Nomad",
      "curl --remote-name https://releases.hashicorp.com/nomad/$NOMAD_VERSION/nomad_\"$NOMAD_VERSION\"_linux_amd64.zip",
      "unzip nomad_\"$NOMAD_VERSION\"_linux_amd64.zip",
      "sudo chown root:root nomad",
      "sudo mv nomad /usr/local/bin/",
      "nomad version",
      "sudo useradd --system --home /etc/nomad.d --shell /bin/false nomad",
      "sudo mkdir --parents /opt/nomad",
      "sudo chown --recursive nomad:nomad /opt/nomad",
      "echo Nomad and Consul are installed",
    ]
  }
}

