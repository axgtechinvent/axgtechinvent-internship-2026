output "bucket_id" {
  description = "ID of S3 Bucket"
  value       = aws_s3_bucket.app_storage.id
}

output "bucket_arn" {
  description = "ARN of S3 Bucket"
  value       = aws_s3_bucket.app_storage.arn
}

output "bucket_region" {
  description = "Region of S3 Bucket"
  value       = aws_s3_bucket.app_storage.region
}

output "iam_policy_arn" {
  description = "ARN of the IAM policy for S3 access"
  value       = aws_iam_policy.s3_app_policy.arn
}