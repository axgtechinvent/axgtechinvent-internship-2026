module "networking" {
  source      = "./modules/networking"
  environment = var.environment
}

module "s3" {
  source       = "./modules/s3"
  project_name = var.project_name
  environment  = var.environment
}

# 4. Bucket Versioning 
resource "aws_s3_bucket_versioning" "app_storage_versioning" {
  bucket = aws_s3_bucket.app_storage.id

  versioning_configuration {
    status = "Disabled"
  }
}

module "ec2" {
  source           = "./modules/ec2"
  project_name     = var.project_name
  environment      = var.environment
  vpc_id           = module.networking.vpc_id
  public_subnet_id = module.networking.public_subnet_id
  bucket_id        = module.s3.bucket_id
  bucket_region    = module.s3.bucket_region
  s3_policy_arn    = module.s3.iam_policy_arn

}

