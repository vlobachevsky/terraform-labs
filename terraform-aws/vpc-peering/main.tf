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

provider "aws" {
  alias  = "us_east_2"
  region = "us-east-2"
}

# Create VPC
resource "aws_vpc" "my_vpc_mgmt" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "MyVPC-MGMT"
  }
}

resource "aws_vpc" "my_vpc_prod" {
  provider   = aws.us_east_2
  cidr_block = "10.1.0.0/16"

  tags = {
    Name = "MyVPC-PROD"
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

# resource "aws_subnet" "public_1b_mgmt" {
#   vpc_id                  = aws_vpc.my_vpc_mgmt.id
#   cidr_block              = "10.0.2.0/24"
#   availability_zone       = "us-east-1b"
#   map_public_ip_on_launch = true

#   tags = {
#     Name = "Public-1B"
#   }
# }

resource "aws_subnet" "public_1a_prod" {
  provider                = aws.us_east_2
  vpc_id                  = aws_vpc.my_vpc_prod.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-1A"
  }
}

# resource "aws_subnet" "public_1b_prod" {
#   provider                = aws.us_east_2
#   vpc_id                  = aws_vpc.my_vpc_prod.id
#   cidr_block              = "10.1.2.0/24"
#   availability_zone       = "us-east-2b"
#   map_public_ip_on_launch = true

#   tags = {
#     Name = "Public-1B"
#   }
# }

# Create peering connection
resource "aws_vpc_peering_connection" "owner" {
  vpc_id      = aws_vpc.my_vpc_mgmt.id
  peer_vpc_id = aws_vpc.my_vpc_prod.id
  peer_region = "us-east-2"

  tags = {
    Name = "MyPeer"
  }
}

# Accept the peering connection
resource "aws_vpc_peering_connection_accepter" "accepter" {
  provider                  = aws.us_east_2
  vpc_peering_connection_id = aws_vpc_peering_connection.owner.id
  auto_accept               = true
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

resource "aws_security_group" "vpcpeer_prod" {
  provider    = aws.us_east_2
  name        = "vpcpeer-prod"
  description = "VPCPEER-PROD"
  vpc_id      = aws_vpc.my_vpc_prod.id

  # All traffic to all destinations (just for now)
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "ICMP"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Name = "VPCPEER-PROD"
  }
}

# Create internet gateway
resource "aws_internet_gateway" "my_igw_mgmt" {
  vpc_id = aws_vpc.my_vpc_mgmt.id

  tags = {
    Name = "MyIGW"
  }
}

resource "aws_default_route_table" "my_vpc_mgmt_default" {
  default_route_table_id = aws_vpc.my_vpc_mgmt.default_route_table_id

  route {
    cidr_block                = "10.1.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.owner.id
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw_mgmt.id
  }

  tags = {
    Name = "MAIN"
  }
}

resource "aws_default_route_table" "my_vpc_prod_default" {
  provider               = aws.us_east_2
  default_route_table_id = aws_vpc.my_vpc_prod.default_route_table_id

  route {
    cidr_block                = "10.0.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.owner.id
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

resource "aws_instance" "public_1a_prod" {
  provider               = aws.us_east_2
  ami                    = "ami-00eeedc4036573771"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_1a_prod.id
  vpc_security_group_ids = [aws_security_group.vpcpeer_prod.id]

  tags = {
    Name = "Public 1A"
  }
}
