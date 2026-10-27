resource "aws_vpc" "techsahel" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Public Sunet A - Application tier
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.techsahel.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.az_a
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-a"
    Tier = "public"
  }
}

# Private Subnet A - Database Tier
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.techsahel.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.az_a

  tags = {
    Name = "${var.project_name}-private-a"
    Tier = "private"
  }
}


# Private Subnet B - Database Tier
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.techsahel.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = var.az_b

  tags = {
    Name = "${var.project_name}-private-b"
    Tier = "private"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "techsahel" {
  vpc_id = aws_vpc.techsahel.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.techsahel.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.techsahel.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public_a" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_a.id
}


# Creation of one custom route table for private subnet. Preventing it to use VPC
# Default Route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.techsahel.id

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

resource "aws_route_table_association" "private_a" {
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private_a.id
}

resource "aws_route_table_association" "private_b" {
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private_b.id
}