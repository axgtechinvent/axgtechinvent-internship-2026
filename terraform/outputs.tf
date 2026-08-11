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

#IAM Outputs

output "iam_user_name" {
  description = "Numele utilizatorului IAM creat pentru aplicatie"
  value       = aws_iam_user.app_user.name
}

output "iam_access_key_id" {
  description = "AWS Access Key ID pentru aplicatie (A se configura in GitHub Secrets)"
  value       = aws_iam_access_key.app_user_key.id
  sensitive   = true
}

output "iam_secret_access_key" {
  description = "AWS Secret Access Key pentru aplicatie (A se configura in GitHub Secrets)"
  value       = aws_iam_access_key.app_user_key.secret
  sensitive   = true
}
