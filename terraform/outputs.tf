# ------------------------------------------------------------------------------
# EC2 OUTPUTS
# ------------------------------------------------------------------------------

output "ec2_instance_id" {
  description = "ID-ul instantei EC2"
  value       = module.ec2.instance_id
}

output "ec2_public_ip" {
  description = "Adresa IP publica a instantei"
  value       = module.ec2.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS pentru instanta EC2"
  value       = module.ec2.public_dns
}

# ------------------------------------------------------------------------------
# S3 OUTPUTS
# ------------------------------------------------------------------------------

output "s3_bucket_name" {
  description = "Numele bucket-ului S3 creat"
  value       = module.s3.bucket_id
}

output "s3_bucket_arn" {
  description = "ARN-ul bucket-ului S3"
  value       = module.s3.bucket_arn
}

output "s3_bucket_region" {
  description = "Regiunea AWS in care se afla bucket-ul"
  value       = module.s3.bucket_region
}
