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
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "MyVPC"
  }
}

# Create subnet
resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-1A"
  }
}

# Internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "MyIGW"
  }
}

# Add route to the internet gateway in main route table
resource "aws_default_route_table" "my_vpc" {
  default_route_table_id = aws_vpc.my_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "MAIN"
  }
}

# Security group
resource "aws_security_group" "public_web" {
  name        = "public-web"
  description = "Public Web Access"
  vpc_id      = aws_vpc.my_vpc.id

  # All traffic to all destinations
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 430
    to_port     = 430
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Public-Web"
  }
}

# EC2 instance in the Public-1A subnet
resource "aws_instance" "public_1a" {
  ami                         = "ami-0dfcb1ef8550277af"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_1a.id
  vpc_security_group_ids      = [aws_security_group.public_web.id]

  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y httpd
  systemctl start httpd
  systemctl enable httpd
  INTERFACE=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/)
  SUBNETID=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$${INTERFACE}/subnet-id)
  echo '<center><h1>This instance is in the subnet wih ID: SUBNETID </h1></center>' > /var/www/html/index.txt
  sed "s/SUBNETID/$SUBNETID/" /var/www/html/index.txt > /var/www/html/index.html
  EOF

  tags = {
    Name = "Public 1A"
  }
}
