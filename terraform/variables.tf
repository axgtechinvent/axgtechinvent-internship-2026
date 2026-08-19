
variable "environment" {
  description = "Deployment"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "AxgProject"
}

variable "aws_region" {
  description = "AWS region"
  default     = "eu-central-1"
}
