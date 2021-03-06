provider "aws" {
  region = "eu-west-2"
}

terraform {
  required_version = ">= 0.12"

  backend "s3" {
    bucket = "jazz-terraform"
    key    = "terraform.tfstate"
    region = "eu-west-2"
  }

}

module "vpc" {
  source        = "./modules/vpc"
  region_az     = local.region_az
  vpc_cidr      = local.vpc_cidr
  public_subnets_cidr = local.public_subnets_cidr
  private_subnets_cidr = local.private_subnets_cidr
  name         = var.name
}

module "security_groups" {
  source = "./modules/security_groups"
  name = var.name
  vpc_id = module.vpc.vpc_id
  whitelist_ip = var.whitelist_ip
}

module "policies_and_roles" {
  source = "./modules/policies_and_roles"
  name = var.name
}

module "ec2" {
  source = "./modules/ec2"
  name = var.name
  server_count = var.server_count
  client_count = var.client_count
  region = var.region
  nomad_binary = var.nomad_binary
  ami = var.ami
  server_instance_type = var.server_instance_type
  client_instance_type = var.client_instance_type
  key_name = var.key_name
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids = module.vpc.public_subnet_ids
  sg_primary_id = module.security_groups.sg_primary_id
  root_block_device_size = var.root_block_device_size
  instance_profile = module.policies_and_roles.instance_profile
}

module "alb" {
  source = "./modules/alb"
  name = var.name
  server_lb_sg_id = module.security_groups.sg_server_lb_id
  subnet_ids = module.vpc.public_subnet_ids
  vpc_id = module.vpc.vpc_id
  ec2_servers = module.ec2.ec2_servers
  ec2_clients = module.ec2.ec2_clients
}

