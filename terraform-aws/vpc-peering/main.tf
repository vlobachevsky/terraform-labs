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
  region = "us-east-1"
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

resource "aws_subnet" "public_1b_mgmt" {
  vpc_id                  = aws_vpc.my_vpc_mgmt.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-1B"
  }
}

resource "aws_subnet" "public_1a_prod" {
  provider   = aws.us_east_2
  vpc_id                  = aws_vpc.my_vpc_prod.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-1A"
  }
}

resource "aws_subnet" "public_1b_prod" {
  provider   = aws.us_east_2
  vpc_id                  = aws_vpc.my_vpc_prod.id
  cidr_block              = "10.1.2.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-1B"
  }
}

# Create peering connection
resource "aws_vpc_peering_connection" "owner" {
  vpc_id = "${aws_vpc.my_vpc_mgmt.id}"
  peer_vpc_id = "${aws_vpc.my_vpc_prod.id}"

  tags = {
    Name = "MyPeer"
  }
}
