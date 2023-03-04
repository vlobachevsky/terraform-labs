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

# Create subnets
resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-1A"
  }
}

resource "aws_subnet" "public_1b" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-1B"
  }
}

resource "aws_subnet" "private_1a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Private-1A"
  }
}

resource "aws_subnet" "private_1b" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Private-1B"
  }
}

# Route table for private subnets
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "Private-RT"
  }
}

# Associations between the route table and private subnets
resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_1b" {
  subnet_id      = aws_subnet.private_1b.id
  route_table_id = aws_route_table.private_rt.id
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

# Elastic IP
resource "aws_eip" "nat_gateway" {
  vpc = true
}

# NAT gateway
# Can't create the resource in KK playground. 
# Error: error creating EC2 NAT Gateway: UnauthorizedOperation: You are not authorized to perform this operation.
# resource "aws_nat_gateway" "my_nat_gw" {
#   allocation_id = aws_eip.nat_gateway.id
#   subnet_id     = aws_subnet.public_1a.id

#   tags = {
#     Name = "MyNATGW"
#   }

#   depends_on = [aws_internet_gateway.my_igw]
# }

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

# EC2 instance in the Public-1A subnet
resource "aws_instance" "host_1a" {
  ami                         = "ami-0dfcb1ef8550277af"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_1a.id
  vpc_security_group_ids      = [aws_security_group.public_web.id]
  associate_public_ip_address = true

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
