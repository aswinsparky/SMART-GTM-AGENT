data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# IAM role for EC2: ECR pull + Secrets Manager read
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_backend" {
  name               = "${var.project_name}-ec2-backend"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_backend.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "ec2_ecr_secrets" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      var.database_url_secret_arn,
      var.openai_api_key_secret_arn
    ]
  }
}

resource "aws_iam_role_policy" "ec2_ecr_secrets" {
  name   = "${var.project_name}-ec2-ecr-secrets"
  role   = aws_iam_role.ec2_backend.id
  policy = data.aws_iam_policy_document.ec2_ecr_secrets.json
}

resource "aws_iam_instance_profile" "ec2_backend" {
  name = "${var.project_name}-ec2-backend"
  role = aws_iam_role.ec2_backend.name
}

# User data: install Docker, pull image, fetch secrets, run container
locals {
  ecr_registry = split("/", var.ecr_repository_url)[0]
  user_data    = <<-EOT
#!/bin/bash
set -e
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker

# Login to ECR
aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${local.ecr_registry}

# Fetch secrets
export DATABASE_URL=$(aws secretsmanager get-secret-value --secret-id ${var.database_url_secret_arn} --query SecretString --output text --region ${var.aws_region})
export OPENAI_API_KEY=$(aws secretsmanager get-secret-value --secret-id ${var.openai_api_key_secret_arn} --query SecretString --output text --region ${var.aws_region})

# Run backend container
docker run -d --restart unless-stopped -p 8000:8000 \
  -e DATABASE_URL="$DATABASE_URL" \
  -e OPENAI_API_KEY="$OPENAI_API_KEY" \
  -e MOCK_MODE=${var.mock_mode ? "1" : "0"} \
  ${var.ecr_repository_url}:latest
EOT
}

resource "aws_launch_template" "backend" {
  name_prefix   = "${var.project_name}-backend-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_backend.name
  }
  network_interfaces {
    associate_public_ip_address = false
    security_groups            = [var.backend_security_group_id]
  }
  user_data = base64encode(local.user_data)
}

resource "aws_autoscaling_group" "backend" {
  name                = "${var.project_name}-backend"
  vpc_zone_identifier = var.private_subnet_ids
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.min_size
  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_attachment" "backend" {
  autoscaling_group_name = aws_autoscaling_group.backend.id
  lb_target_group_arn    = var.target_group_arn
}
