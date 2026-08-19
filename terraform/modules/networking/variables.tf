variable "environment" {
  description = "Deployment"
  type        = string
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for VPC"
}

variable "public_subnet_cidr" {
  type        = string
  default     = "10.0.1.0/24"
  description = "CIDR block for public subnet"
}

variable "availability_zone" {
  type        = string
  default     = "eu-central-1a"
  description = "Availability zone for the subnet"
}

