variable "environment" {
  description = "Deployment"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "instance_type" {
  type = string
  default = "t3.micro"
  description = "EC2 instance type"
}

variable "vpc_id" {
  type = string
  description = "VPC ID"
}

variable "public_subnet_id" {
  type = string
  description = "Subnet ID"
}

variable "bucket_region" {
  type = string
  description = "Bucket region"
}

variable "bucket_id" {
  type = string
  description = "Bucket ID"
}

variable "s3_policy_arn" {
  type = string
  description = "ARN of the IAM policy for S3 access"
}


