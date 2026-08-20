variable "environment" {
  description = "Mediul de deployment"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Numele proiectului"
  type        = string
  default     = "AxgProject"
}

variable "aws_region" {
  description = "AWS region"
  default     = "eu-central-1"
}
