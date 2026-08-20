
# Create a VPC
resource "aws_vpc" "main" { #aws_vpc = Tipul resursei (ce se creează în AWS), main = Numele local
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name        = "project-vpc-${var.environment}"
    Environment = var.environment
  }
}

#Create public subnets
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id # Conectare la VPC
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true # Alocă IP public automat pentru instanțe

  tags = {
    Name = "public-subnet-1a-${var.environment}"
  }
}

#Create IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id # Conectare la VPC

  tags = {
    Name = "main-igw-${var.environment}"
  }
}

#Create route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  # Regula de rutare: Tot traficul destinat exteriorului (0.0.0.0/0) merge prin IGW
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id # Conectare la IGW
  }

  tags = {
    Name = "public-route-table-${var.environment}"
  }
}

# Connecting the route table with the subnets
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
