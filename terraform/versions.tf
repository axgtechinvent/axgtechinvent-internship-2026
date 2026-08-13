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
    key          = "${var.environment}/terraform.tfstate"       # Calea din S3 unde se va salva starea
    region       = "eu-central-1"
    use_lockfile = true # Tabela pentru locking
    encrypt      = true # Criptarea fișierului pe S3
  }
}