# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "main-vpc" }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "main-igw" }
}

# Public Subnets
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[0]
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { Name = "public1" }
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[1]
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = { Name = "public2" }
}

# Private Subnets
resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[0]
  availability_zone = "us-east-1a"
  tags = { Name = "private1" }
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[1]
  availability_zone = "us-east-1b"
  tags = { Name = "private2" }
}

# Elastic IP for NAT
resource "aws_eip" "nat" {
  vpc = true
}

# NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public1.id
  tags = { Name = "main-nat" }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "public-rt" }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_assoc2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "private-rt" }
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_assoc2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private.id
}
