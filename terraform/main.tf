
# Create a VPC
resource "aws_vpc" "main" { #aws_vpc = Tipul resursei (ce se creează în AWS), main_vpc = Numele local
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name        = "project-vpc-dev"
    Environment = var.environment
  }
}

#Create public subnets
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id # Conectare la VPC
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true # Alocă IP public automat pentru instanțe

  tags = {
    Name = "public-subnet-1a-dev"
  }
}

#Create IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id # Conectare la VPC

  tags = {
    Name = "main-igw-dev"
  }
}

#Create route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  # Regula de rutare: Tot traficul destinat exteriorului (0.0.0.0/0) merge prin IGW
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id # Conectare la IGW
  }

  tags = {
    Name = "public-route-table-dev"
  }
}

# Connecting the route table with the subnets
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# ------------------------------------------------------------------------------
# SECURITY GROUP & COMPUTE (EC2 & AMI)
# ------------------------------------------------------------------------------

resource "aws_key_pair" "app_key" {
  key_name   = "app-server-key-dev"
  public_key = file(pathexpand(var.public_key_path))
}

# 1. Definirea Security Group-ului (fara reguli inline)
resource "aws_security_group" "app_sg" {
  name        = "app-server-sg-dev"
  description = "Security Group pentru serverele de aplicatie"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "app-sg-dev"
    Environment = var.environment
  }
}

# 2. Regula Inbound HTTP (Permis de oriunde pe portul 80)
resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.app_sg.id
  description       = "Allow HTTP traffic"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# 3. Regula Inbound SSH 
resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.app_sg.id
  description       = "Allow SSH from my IP"
  cidr_ipv4         = "${var.my_ip}/32"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# 4. Regula Outbound (iesire permisa catre orice destinatie)
resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.app_sg.id
  description       = "Allow all outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # Toate protocoalele
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
  instance_type               = "t3.micro"                     # Free tier eligibil
  subnet_id                   = aws_subnet.public_subnet.id    # Plasare în subnetul public
  vpc_security_group_ids      = [aws_security_group.app_sg.id] # Atasare Security Group
  key_name                    = aws_key_pair.app_key.key_name
  associate_public_ip_address = true # Asigura un IP public

  tags = {
    Name        = "ec2-app-server-dev"
    Environment = var.environment
    Project     = var.project_name
  }
}
# ------------------------------------------------------------------------------
# S3 BUCKET & CONFIGURATION
# ------------------------------------------------------------------------------

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

# ------------------------------------------------------------------------------
# IAM USER, POLICY & ACCESS KEYS 
# ------------------------------------------------------------------------------

# 1. Creeaza IAM User-ul dedicat aplicatiei
resource "aws_iam_user" "app_user" {
  name = "${var.project_name}-s3-user-${var.environment}"

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# 2. Generam documentul de politica IAM urmand principiul Least Privilege
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

# 3. Creeaza resursa IAM Policy pe baza documentului JSON de mai sus
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

# 4. Ataseaza Politica la IAM User
resource "aws_iam_user_policy_attachment" "app_user_s3_attach" {
  user       = aws_iam_user.app_user.name
  policy_arn = aws_iam_policy.s3_app_policy.arn
}

# 5. Genereaza Access Key & Secret Key pentru aplicatie
resource "aws_iam_access_key" "app_user_key" {
  user = aws_iam_user.app_user.name
}

# ------------------------------------------------------------------------------
# ECR REPOSITORY
# ------------------------------------------------------------------------------

# Create ECR repository 
resource "aws_ecr_repository" "ecr" {
  name                 = "my-ecr-app-dev"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}


