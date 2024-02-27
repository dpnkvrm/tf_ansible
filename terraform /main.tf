terraform {
  required_providers {
    aws = "~>5.38"
  }
}

locals {
  project_name = "Zantac-Inc"
  public_subnets_1a =  cidrsubnet(var.vpc_cidr, 8, 0)
  public_subnets_1b = cidrsubnet(var.vpc_cidr, 8, 1)

}

# Create VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${local.project_name}-VPC"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${local.project_name}-IGW"
  }
}

# Create Public Subnets
resource "aws_subnet" "public_subnet_1a" {
  vpc_id = aws_vpc.vpc.id
  availability_zone = "${var.region}a"
  cidr_block = local.public_subnets_1a
  tags = {
    Name = "${local.project_name}-Public-Subnet-01"
  }
}
resource "aws_subnet" "public_subnet_1b" {
  vpc_id = aws_vpc.vpc.id
  availability_zone = "${var.region}b"
  cidr_block = local.public_subnets_1b
  tags = {
    Name = "${local.project_name}-Public-Subnet-02"
  }
}

# Create Public Route table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${local.project_name}-Public-RT"
  }
}

# Create routes to IGW
resource "aws_route" "igw" {
  route_table_id = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

# Create RT Associations - Public Subnets
resource "aws_route_table_association" "public_subnet_1a" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id = aws_subnet.public_subnet_1a.id
}

resource "aws_route_table_association" "public_subnet_1b" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id = aws_subnet.public_subnet_1b.id
}

