#EC2 Outputs

output "instance_id" {
  description = "ID-ul instantei EC2"
  value       = aws_instance.app_server.id
}

output "public_ip" {
  description = "Adresa IP publica a instantei"
  value       = aws_instance.app_server.public_ip
}

output "public_dns" {
  description = "Public DNS pentru instanta EC2"
  value       = aws_instance.app_server.public_dns
}

#S3 Outputs

output "s3_bucket_name" {
  description = "Numele bucket-ului S3 creat"
  value       = aws_s3_bucket.app_storage.id
}

output "s3_bucket_arn" {
  description = "ARN-ul bucket-ului S3"
  value       = aws_s3_bucket.app_storage.arn
}

output "s3_bucket_region" {
  description = "Regiunea AWS in care se afla bucket-ul"
  value       = aws_s3_bucket.app_storage.region
}


output "ecr_repository_url" {
  description = "URL-ul repository-ului ECR"
  value       = module.ecr.repository_url
}
