terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-central-1"
}

# Create a VPC
resource "aws_vpc" "main_vpc" { #aws_vpc = Tipul resursei (ce se creează în AWS), main_vpc = Numele local
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true # Permite instanțelor din VPC să primească nume DNS
  enable_dns_support   = true

  tags = {
    Name        = "project-vpc"
    Environment = "dev"
  }
}




