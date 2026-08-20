
# Create ECR repository 
resource "aws_ecr_repository" "ecr" {
  name                 = "my-ecr-app-${var.environment}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}