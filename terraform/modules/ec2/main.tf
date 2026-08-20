
# Definirea Security Group-ului (fara reguli inline)
resource "aws_security_group" "app_sg" {
  name        = "app-server-sg-${var.environment}"
  description = "Security Group pentru serverele de aplicatie"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "app-sg-${var.environment}"
    Environment = var.environment
  }
}

# Regula Inbound HTTP (Permis de oriunde pe portul 80)
resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.app_sg.id
  description       = "Allow HTTP traffic"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# Regula Outbound (iesire permisa catre orice destinatie)
resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.app_sg.id
  description       = "Allow all outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # Toate protocoalele
}


resource "aws_iam_role" "app_ec2_role" {
  name = "${var.project_name}-ec2-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "ec2_ecr_read_only" {
  role       = aws_iam_role.app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ec2_s3_access" {
  role       = aws_iam_role.app_ec2_role.name
  policy_arn = var.s3_policy_arn
}

resource "aws_iam_instance_profile" "app_profile" {
  name = "${var.project_name}-ec2-profile-${var.environment}"
  role = aws_iam_role.app_ec2_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_logs" {
  role       = aws_iam_role.app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Căutare dinamică pentru cel mai recent AMI de Amazon Linux 2023(resursa de tip data source)
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Crearea instantei EC2
resource "aws_instance" "app_server" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type                   # Free tier eligibil
  subnet_id                   = var.public_subnet_id    # Plasare în subnetul public
  vpc_security_group_ids      = [aws_security_group.app_sg.id] # Atasare Security Group
  associate_public_ip_address = true # Asigura un IP public
  iam_instance_profile        = aws_iam_instance_profile.app_profile.name

  user_data = <<-EOF
              #!/bin/bash
              echo "S3_BUCKET_NAME=${var.bucket_id}" > /etc/app.env
              echo "AWS_REGION=${var.bucket_region}" >> /etc/app.env

              # Install and start Docker
              dnf update -y
              dnf install -y docker
              systemctl enable docker
              systemctl start docker
              usermod -aG docker ec2-user

              # Install Docker Compose (v2 plugin)
              mkdir -p /usr/local/lib/docker/cli-plugins
              curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
                -o /usr/local/lib/docker/cli-plugins/docker-compose
              chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

              # Seed the compose file the CI deploy step (sed + docker compose up) expects
              mkdir -p /home/ssm-user
              cat > /home/ssm-user/docker-compose.yaml <<'COMPOSE'
              services:
                app:
                  image: PLACEHOLDER
                  restart: unless-stopped
                  ports:
                    - "80:5000"
                  env_file:
                    - /etc/app.env
              COMPOSE
              EOF

  tags = {
    Name        = "ec2-app-server-dev"
    Environment = var.environment
    Project     = var.project_name
  }
}

