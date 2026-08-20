
# 1. Generam un sufix aleatoriu pentru a garanta un nume unic global
resource "random_string" "bucket_suffix" {
  length  = 6
  special = false
  upper   = false
}

# 2. Resursa principala a bucket-ului S3
resource "aws_s3_bucket" "app_storage" {
  bucket        = "${lower(var.project_name)}-storage-${var.environment}-${random_string.bucket_suffix.result}"
  force_destroy = false # Impiedica stergerea accidentala daca bucket-ul contine fisiere

  tags = {
    Name        = "${var.project_name}-s3-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# 3. Block Public Access 
resource "aws_s3_bucket_public_access_block" "app_storage_pab" {
  bucket = aws_s3_bucket.app_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 4. Bucket Versioning 
resource "aws_s3_bucket_versioning" "app_storage_versioning" {
  bucket = aws_s3_bucket.app_storage.id

  versioning_configuration {
    status = "Disabled"
  }
}

# Generam documentul de politica IAM urmand principiul Least Privilege
data "aws_iam_policy_document" "s3_app_policy_doc" {
  # Permisiuni la nivel de Bucket (listare continut)
  statement {
    sid    = "AllowS3BucketListing"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      aws_s3_bucket.app_storage.arn
    ]
  }

# Permisiuni la nivel de Obiecte (CRUD pe fisiere)
  statement {
    sid    = "AllowS3ObjectCRUD"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${aws_s3_bucket.app_storage.arn}/*"
    ]
  }
}

# Creeaza resursa IAM Policy pe baza documentului JSON de mai sus
  resource "aws_iam_policy" "s3_app_policy" {
    name        = "${var.project_name}-s3-policy-${var.environment}"
    description = "Permisiuni minime necesare aplicatiei pentru lucrul cu bucket-ul S3 ${aws_s3_bucket.app_storage.id}"
    policy      = data.aws_iam_policy_document.s3_app_policy_doc.json

    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
    }
  }
