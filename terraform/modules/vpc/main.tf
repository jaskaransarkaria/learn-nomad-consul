variable "region_az" {}
variable "vpc_cidr" {}
variable "public_subnets_cidr" {}
variable "private_subnets_cidr" {}
variable "owner" {}

# 1. Create vpc
resource "aws_vpc" "vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Owner = var.owner
  }
}

# 2. Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Owner = var.owner
  }
}

# elastic ip for NAT
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
}

# NAT
resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id     = "${element(aws_subnet.public.*.id, 0)}"
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Owner = var.owner
  }
}

# 3. Create Custom Route Table
resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }


  tags = {
    Owner = var.owner
  }
}

# 4. Create a Subnet 
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.vpc.id
  count = "${length(var.public_subnets_cidr)}"
  cidr_block              = "${element(var.public_subnets_cidr, count.index)}"
  availability_zone       = "${element(var.region_az, count.index)}"
  map_public_ip_on_launch = true

  tags = {
    Owner = var.owner
  }
}


resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.vpc.id
  count = "${length(var.private_subnets_cidr)}"
  cidr_block              = "${element(var.private_subnets_cidr, count.index)}"
  availability_zone       = "${element(var.region_az, count.index)}"

  tags = {
    Owner = var.owner
  }
}

# 5. Associate subnet with Route Table
resource "aws_main_route_table_association" "main_rtb_association" {
  vpc_id         = aws_vpc.vpc.id
  route_table_id = aws_route_table.rtb.id
}

# routing table for public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Owner = var.owner
  }
}

# routing table for private subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Owner = var.owner
  }
}

# link igw to public route table
resource "aws_route" "public_igw" {
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

# link nat gateway to private routing table
resource "aws_route" "private_nat_gateway" {
  route_table_id = "${aws_route_table.private.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.nat.id}"
}

# route table associations
resource "aws_route_table_association" "public" {
  count          = "${length(var.public_subnets_cidr)}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "private" {
  count          = "${length(var.private_subnets_cidr)}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${aws_route_table.private.id}"
}

/*==== VPC's Default Security Group ======*/
resource "aws_security_group" "default" {
  name        = "${var.owner}-default-sg"
  description = "Default security group to allow inbound/outbound from the VPC"
  vpc_id      = "${aws_vpc.vpc.id}"
  depends_on  = [aws_vpc.vpc]
  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }
  
  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = "true"
  }
  tags = {
    Owner = var.owner
}
}
