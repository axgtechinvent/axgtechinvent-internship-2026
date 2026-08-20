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

output "iam_role_name" {
  description = "Numele rolului IAM asociat EC2"
  value       = aws_iam_role.app_ec2_role.name
}