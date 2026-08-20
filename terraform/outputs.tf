#EC2 Outputs

output "instance_id" {
  description = "ID-ul instantei EC2"
  value       = module.ec2.instance_id
}

output "public_ip" {
  description = "Adresa IP publica a instantei"
  value       = module.ec2.public_ip
}

output "public_dns" {
  description = "Public DNS pentru instanta EC2"
  value       = module.ec2.public_dns
}

#S3 Outputs

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


output "ecr_repository_url" {
  description = "URL-ul repository-ului ECR"
  value       = module.ecr.repository_url
}
