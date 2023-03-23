terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

# Create VPC
resource "aws_vpc" "my_vpc_mgmt" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "MyVPC-MGMT"
  }
}


# Create subnets
resource "aws_subnet" "public_1a_mgmt" {
  vpc_id                  = aws_vpc.my_vpc_mgmt.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-1A"
  }
}

# Create security groups
resource "aws_security_group" "public_web" {
  name        = "public-web"
  description = "Public Web Access"
  vpc_id      = aws_vpc.my_vpc_mgmt.id

  # All traffic to all destinations
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All traffic to all destinations (just for now)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Public-Web"
  }
}

resource "aws_security_group" "vpcpeer_mgmt" {
  name        = "vpcpeer-mgmt"
  description = "VPCPEER-MGMT"
  vpc_id      = aws_vpc.my_vpc_mgmt.id

  # All traffic to all destinations (just for now)
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "ICMP"
    cidr_blocks = ["10.1.0.0/16"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["10.1.0.0/16"]
  }

  tags = {
    Name = "VPCPEER-MGMT"
  }
}

# Create internet gateway
resource "aws_internet_gateway" "my_igw_mgmt" {
  vpc_id = aws_vpc.my_vpc_mgmt.id

  tags = {
    Name = "MyIGW"
  }
}

# Add routes to main route table for the VPCs
resource "aws_default_route_table" "my_vpc_mgmt_default" {
  default_route_table_id = aws_vpc.my_vpc_mgmt.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw_mgmt.id
  }

  tags = {
    Name = "MAIN"
  }
}

# Launch instances
resource "aws_instance" "public_1a_mgmt" {
  ami                    = "ami-0dfcb1ef8550277af"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_1a_mgmt.id
  vpc_security_group_ids = [aws_security_group.public_web.id, aws_security_group.vpcpeer_mgmt.id]

  tags = {
    Name = "Public 1A"
  }
}

# S3 Gateway endpoint 
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.my_vpc_mgmt.id
  service_name = "com.amazonaws.us-east-1.s3"
}

# Endpoint association for route table
resource "aws_vpc_endpoint_route_table_association" "s3_endpoint_route_table_link" {
  route_table_id  = aws_default_route_table.my_vpc_mgmt_default.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}
