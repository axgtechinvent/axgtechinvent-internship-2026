# ==============================================================================
# NETWORKING MODULE MOVES
# ==============================================================================
moved {
  from = aws_vpc.main
  to   = module.networking.aws_vpc.main
}

moved {
  from = aws_subnet.public_subnet
  to   = module.networking.aws_subnet.public_subnet
}

moved {
  from = aws_internet_gateway.igw
  to   = module.networking.aws_internet_gateway.igw
}

moved {
  from = aws_route_table.public_rt
  to   = module.networking.aws_route_table.public_rt
}

moved {
  from = aws_route_table_association.public_assoc
  to   = module.networking.aws_route_table_association.public_assoc
}

# ==============================================================================
# S3 MODULE MOVES
# ==============================================================================
moved {
  from = random_string.bucket_suffix
  to   = module.s3.random_string.bucket_suffix
}

moved {
  from = aws_s3_bucket.app_storage
  to   = module.s3.aws_s3_bucket.app_storage
}

moved {
  from = aws_s3_bucket_public_access_block.app_storage_pab
  to   = module.s3.aws_s3_bucket_public_access_block.app_storage_pab
}

moved {
  from = aws_s3_bucket_versioning.app_storage_versioning
  to   = module.s3.aws_s3_bucket_versioning.app_storage_versioning
}

moved {
  from = aws_iam_policy.s3_app_policy
  to   = module.s3.aws_iam_policy.s3_app_policy
}

# ==============================================================================
# ECR MODULE MOVES
# ==============================================================================
moved {
  from = aws_ecr_repository.ecr
  to   = module.ecr.aws_ecr_repository.ecr
}

# ==============================================================================
# EC2 & IAM MODULE MOVES
# ==============================================================================
moved {
  from = aws_security_group.app_sg
  to   = module.ec2.aws_security_group.app_sg
}

moved {
  from = aws_vpc_security_group_ingress_rule.allow_http
  to   = module.ec2.aws_vpc_security_group_ingress_rule.allow_http
}

moved {
  from = aws_vpc_security_group_egress_rule.allow_all_outbound
  to   = module.ec2.aws_vpc_security_group_egress_rule.allow_all_outbound
}

moved {
  from = aws_iam_role.app_ec2_role
  to   = module.ec2.aws_iam_role.app_ec2_role
}

moved {
  from = aws_iam_role_policy_attachment.ec2_ecr_read_only
  to   = module.ec2.aws_iam_role_policy_attachment.ec2_ecr_read_only
}

moved {
  from = aws_iam_role_policy_attachment.ec2_s3_access
  to   = module.ec2.aws_iam_role_policy_attachment.ec2_s3_access
}

moved {
  from = aws_iam_instance_profile.app_profile
  to   = module.ec2.aws_iam_instance_profile.app_profile
}

moved {
  from = aws_instance.app_server
  to   = module.ec2.aws_instance.app_server
}