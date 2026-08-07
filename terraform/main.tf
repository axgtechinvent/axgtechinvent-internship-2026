terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  #Implementation of the S3 backend
  backend "s3" {
    bucket       = "my-team-tfstate-bucket-2026" # Bucket-ul S3 creat
    key          = "dev/terraform.tfstate"       # Calea din S3 unde se va salva starea
    region       = "eu-central-1"
    use_lockfile = true # Tabela pentru locking
    encrypt      = true # Criptarea fișierului pe S3
  }
}

#Implementation of the AWS Provider
provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = {
      ManagedBy = "Terraform"
    }
  }
}

# Create a VPC
resource "aws_vpc" "main" { #aws_vpc = Tipul resursei (ce se creează în AWS), main_vpc = Numele local
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name        = "project-vpc-dev"
    Environment = "dev"
  }
}

#Create public subnets
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id # Conectare la VPC
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true # Alocă IP public automat pentru instanțe

  tags = {
    Name = "public-subnet-1a-dev"
  }
}

#Create IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id # Conectare la VPC

  tags = {
    Name = "main-igw-dev"
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
    Name = "public-route-table-dev"
  }
}

# Connecting the route table with the subnets
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}


# Create ECR repository 
resource "aws_ecr_repository" "ecr" {
  name                 = "my-ecr-app-dev"   
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}


